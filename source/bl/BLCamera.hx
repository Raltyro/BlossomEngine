package bl;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.geom.ColorTransform;

import flixel.addons.util.FlxSimplex;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;

import bl.graphic.BufferPool;
import bl.util.BitmapDataUtil;

@:access(openfl.display.Sprite)
@:access(flixel.graphics.frames.FlxFrame)
@:access(flixel.graphics.FlxGraphic)
class BLCamera extends FlxCamera {
	/**
	 * The rotation of the camera display (in degrees).
	 * In this case, the "angle" property for PlayCamera are the camera's world rotation in degrees.
	 */
	public var rotation(default, set):Float = 0;

	/**
	 * The ratio of the distance to zooms to targetZoom the camera zooms per 1/60 sec.
	 * Valid values range from `0.0` to `1.0`. `1.0` means the camera always snaps to its target
	 * position. `0.5` means the camera always travels halfway to the target position, `0.0` means
	 * the camera does not move. Generally, the lower the value, the more smooth.
	 */
	public var zoomLerp:Float = 1.0;
	public var zoomSmoothScale:Float = 0.0;

	public var followSmoothScale:Float = 0.75;
	public var disableSmoothCam:Bool = false;

	/**
	 * What zoom to zoom into for zoomLerp.
	 */
	public var targetZoom:Null<Float>;

	/**
	 * The tween used for this camera zoom.
	 */
	public var zoomTween:FlxTween;

	/**
	 * The tween used for this camera scroll.
	 */
	public var scrollTween:FlxTween;

	public var keepResolutionScale:Bool = false;
	public var resolutionWidth:Null<Int>;
	public var resolutionHeight:Null<Int>;

	public var smoothing:Bool = true;
	public var shouldDraw:Bool = true;
	public var useBuffer:Bool = #if CAMERA_NO_BUFFER false #else true #end;

	public var appliedFilters(default, null):Bool;
	public var grabbed(default, null):Bool;
	public var freezed(default, null):Bool;

	public var perspective:Perspective = new Perspective();
	public var updateViewPerspective:Bool = true;

	var _presented:Bool;
	var _frame:FlxFrame;
	var _continueDrawStack:FlxDrawBaseItem<Dynamic>;
	var _useBuffer:Bool;
	var _freeze:Bool;

	var _rotatedBounds:FlxRect = FlxRect.get();
	@:noCompletion var _sinAngle:Float = 0;
	@:noCompletion var _cosAngle:Float = 1;

	var _scroll:FlxPoint = FlxPoint.get();
	var _zoom:Float = 1;

	var _lastBeat:Float = 0;

	var _fxTintColor:FlxColor = FlxColor.TRANSPARENT;
	var _fxTintAlpha:Float = 0;
	var _fxTintBlend:BlendMode = NORMAL;

	var _fxShakeIntensityX:Float = 0;
	var _fxShakeIntensityY:Float = 0;
	var _fxShakeIntensityAngle:Float = 0;
	var _fxShakeSpeedX:Float = 0;
	var _fxShakeSpeedY:Float = 0;
	var _fxShakeSpeedAngle:Float = 0;
	var _fxShakeTimeX:Float = 0;
	var _fxShakeTimeY:Float = 0;
	var _fxShakeTimeAngle:Float = 0;
	var _fxShakeTime:Null<Float>;
	var _fxShakeEase:EaseFunction;
	var _fxShakeBetter:Bool = true;
	var _fxShakeScroll:Bool = true;
	var _fxShakeWasScroll:Bool = false;
	var _fxShakePos:FlxPoint = FlxPoint.get();
	var _fxShakeAngle:Float = 0;

	public function new(x = 0.0, y = 0.0, w = 0, h = 0, zoom = 0.0) {
		super(x, y, w, h, zoom);

		bgColor = 0;

		final graph = new FlxGraphic('frameCamera$ID', buffer = buffer ?? BufferPool.get(resolutionWidth ?? width, resolutionHeight ?? height), true);
		(_frame = new FlxFrame(graph)).frame = FlxRect.get(0, 0, width, height);
		graph.destroyOnNoUse = false;
		FlxG.bitmap.addGraphic(graph);

		if (_flashBitmap == null) _scrollRect.addChildAt(_flashBitmap = new Bitmap(buffer), 0);
		if (screen == null) {
			(screen = new FlxSprite()).pixels = buffer;
			screen.origin.set();
		}
	}

	inline public function setScroll(x = 0.0, y = 0.0) _scroll.copyFrom(scroll.set(x, y));

	public function snapSmoothToTarget() {
		_scroll.copyFrom(scroll);
		_zoom = zoom;
	}

	override function snapToTarget() {
		super.snapToTarget();

		if (targetZoom != null) zoom = targetZoom;
		snapSmoothToTarget();

		_fxShakeWasScroll = false;
	}

	override function update(elapsed:Float) {
		if (!_freeze) {
			if (target != null) {
				updateFollow();
				updateLerp(elapsed);
			}
			if (targetZoom != null) updateZoom(elapsed);

			updateScroll();
			updateFlash(elapsed);
			updateFade(elapsed);
			updateShake(elapsed);
			updatePerspective();
		}

		updateFlashSpritePosition();
	}

	override function updateFollow() {
		if (deadzone == null) {
			target.getMidpoint(_point);
			_point.addPoint(targetOffset);
			_scrollTarget.set(_point.x - width * 0.5, _point.y - height * 0.5);
		}
		else {
			final targetX = target.x + targetOffset.x, targetY = target.y + targetOffset.y;

			if (style == SCREEN_BY_SCREEN) {
				if (targetX >= viewRight) _scrollTarget.x += viewWidth;
				else if (targetX + target.width < viewLeft) _scrollTarget.x -= viewWidth;

				if (targetY >= viewBottom) _scrollTarget.y += viewHeight;
				else if (targetY + target.height < viewTop) _scrollTarget.y -= viewHeight;

				bindScrollPos(_scrollTarget);
			}
			else {
				var edge:Float = targetX - deadzone.x;
				if (_scrollTarget.x > edge) _scrollTarget.x = edge;

				if (_scrollTarget.x < (edge = targetX + target.width - deadzone.x - deadzone.width)) _scrollTarget.x = edge;

				if (_scrollTarget.y > (edge = targetY - deadzone.y)) _scrollTarget.y = edge;

				if (_scrollTarget.y < (edge = targetY + target.height - deadzone.y - deadzone.height)) _scrollTarget.y = edge;
			}

			if (target is FlxSprite) {
				if (_lastTargetPosition == null) _lastTargetPosition = FlxPoint.get(target.x, target.y);
				_scrollTarget.x += (target.x - _lastTargetPosition.x) * followLead.x;
				_scrollTarget.y += (target.y - _lastTargetPosition.y) * followLead.y;
				_lastTargetPosition.set(target.x, target.y);
			}
		}
	}

	override function updateLerp(elapsed:Float) {
		if (scrollTween?.active) {
			_scroll.copyFrom(scroll);
			return;
		}

		final finalLerp = disableSmoothCam ? followLerp : followLerp * (1 + followSmoothScale * 1.25);
		if (finalLerp >= 1) _scroll.copyFrom(scroll.copyFrom(_scrollTarget));
		else if (finalLerp > 0) {
			final lerp = FlxMath.getElapsedLerp(finalLerp, elapsed);
			if (disableSmoothCam)
				_scroll.copyFrom(scroll.add((_scrollTarget.x - scroll.x) * lerp, (_scrollTarget.y - scroll.y) * lerp));
			else {
				_scroll.add((_scrollTarget.x - _scroll.x) * lerp, (_scrollTarget.y - _scroll.y) * lerp);

				if (followSmoothScale <= 0) scroll.copyFrom(_scroll);
				else scroll.add((_scroll.x - scroll.x) * lerp, (_scroll.y - scroll.y) * lerp);
			}
		}
	}

	function updateZoom(elapsed:Float) {
		if (zoomTween?.active) {
			_zoom = zoom;
			return;
		}

		final finalLerp = disableSmoothCam ? zoomLerp : zoomLerp * (1 + zoomSmoothScale * 1.25);
		if (finalLerp >= 1) zoom = targetZoom;
		else if (finalLerp > 0) {
			if (disableSmoothCam)
				_zoom = zoom += (targetZoom - zoom) * FlxMath.getElapsedLerp(finalLerp, elapsed);
			else {
				_zoom += (targetZoom - _zoom) * FlxMath.getElapsedLerp(finalLerp, elapsed);
				if (zoomSmoothScale <= 0) zoom = _zoom; else zoom += (_zoom - zoom) * FlxMath.getElapsedLerp(finalLerp, elapsed);
			}
		}
	}

	function _zoomTween(f:Float) zoom = f;

	public function tweenZoom(duration = 1.0, ?to:Float, ?from:Float, ?ease:EaseFunction, ?onComplete:FlxTween->Void) {
		if (zoomTween != null) zoomTween.cancel();
		zoomTween = FlxTween.num(_zoom = from ?? zoom, to ?? targetZoom, duration, {onComplete: onComplete, ease: ease}, _zoomTween);
	}

	public function tweenScroll(duration = 1.0, ?toX:Float, ?toY:Float, ?fromX:Float, ?fromY:Float, ?ease:EaseFunction, ?onComplete:FlxTween->Void) {
		if (scrollTween != null) scrollTween.cancel();
		scroll.x = _scroll.x = fromX ?? scroll.x;
		scroll.y = _scroll.y = fromY ?? scroll.y;
		updateFollow();
		scrollTween = FlxTween.tween(scroll, {x: toX ?? _scrollTarget.x, y: toY ?? _scrollTarget.y}, duration, {onComplete: onComplete, ease: ease});
	}

	public function tint(color:FlxColor = FlxColor.TRANSPARENT, alpha = 1.0, ?blend:BlendMode) {
		_fxTintAlpha = alpha * color.alphaFloat;
		_fxTintBlend = blend ?? NORMAL;

		color.alpha = 255;
		_fxTintColor = color;
	}

	inline function initFXShake(reset = true, ?duration:Float, ?onComplete:Void->Void) {
		if (reset) {
			_fxShakeTimeX = FlxG.random.float(-10000, 10000);
			_fxShakeTimeY = FlxG.random.float(-10000, 10000);
			_fxShakeTimeAngle = FlxG.random.float(-10000, 10000);
		}

		_fxShakeTime = 0;
		_fxShakeDuration = duration;
		_fxShakeComplete = onComplete;
	}

	override function shake(intensity = 0.05, duration = 0.5, ?onComplete:Void->Void, force = true, ?axes:FlxAxes) {
		if (!force && _fxShakeTime != null) return;
		final oldIntensityX = _fxShakeIntensityX, oldIntensityY = _fxShakeIntensityY, oldIntensityAngle = _fxShakeIntensityAngle;
		final oldSpeedX = _fxShakeSpeedX, oldSpeedY = _fxShakeSpeedY, oldSpeedAngle = _fxShakeSpeedAngle;

		_fxShakeBetter = true;
		_fxShakeScroll = true;
		_fxShakeIntensityX = (axes.x || axes == null) ? intensity : 0;
		_fxShakeIntensityY = (axes.y || axes == null) ? intensity : 0;
		_fxShakeIntensityAngle = intensity * 40;
		_fxShakeSpeedX = 1;
		_fxShakeSpeedY = 1;
		_fxShakeSpeedAngle = .6;
		_fxShakeEase = null;

		initFXShake(
			oldIntensityX != _fxShakeIntensityX || oldIntensityY != _fxShakeIntensityY || oldIntensityAngle != _fxShakeIntensityAngle
			|| oldSpeedX != _fxShakeSpeedX || oldSpeedY != _fxShakeSpeedY || oldSpeedAngle != _fxShakeSpeedAngle,
			duration, onComplete
		);
	}

	public function simpleShake(intensity = 0.05, duration = 0.5, ?onComplete:Void->Void, force = true, ?axes:FlxAxes) {
		if (!force && _fxShakeTime != null) return;

		_fxShakeBetter = false;
		_fxShakeScroll = false;
		_fxShakeIntensityX = (axes.x || axes == null) ? intensity : 0;
		_fxShakeIntensityY = (axes.y || axes == null) ? intensity : 0;
		_fxShakeIntensityAngle = 0;
		_fxShakeEase = null;

		initFXShake(duration, onComplete);
	}

	public function advancedShake(
		intensityX = 0.05, intensityY = 0.05, intensityAngle = 2.0,
		speedX = 1.0, speedY = 1.0, speedAngle = 1.0,
		duration = 0.5, ?ease:EaseFunction, ?onComplete:Void->Void, force = true
	) {
		if (!force && _fxShakeTime != null) return;
		final oldIntensityX = _fxShakeIntensityX, oldIntensityY = _fxShakeIntensityY, oldIntensityAngle = _fxShakeIntensityAngle;
		final oldSpeedX = _fxShakeSpeedX, oldSpeedY = _fxShakeSpeedY, oldSpeedAngle = _fxShakeSpeedAngle;

		_fxShakeBetter = true;
		_fxShakeScroll = true;
		_fxShakeIntensityX = intensityX;
		_fxShakeIntensityY = intensityY;
		_fxShakeIntensityAngle = intensityAngle;
		_fxShakeSpeedX = speedX;
		_fxShakeSpeedY = speedY;
		_fxShakeSpeedAngle = speedAngle;
		_fxShakeEase = ease;

		initFXShake(
			oldIntensityX != _fxShakeIntensityX || oldIntensityY != _fxShakeIntensityY || oldIntensityAngle != _fxShakeIntensityAngle
			|| oldSpeedX != _fxShakeSpeedX || oldSpeedY != _fxShakeSpeedY || oldSpeedAngle != _fxShakeSpeedAngle,
			duration, onComplete
		);
	}

	override function updateShake(elapsed:Float) {
		if (_fxShakeWasScroll) {
			scroll.subtractPoint(_fxShakePos);
			_fxShakeWasScroll = false;
		}
		if (_fxShakeTime == null) return;
		if ((_fxShakeTime += elapsed) > _fxShakeDuration) {
			if (_fxShakeComplete != null) _fxShakeComplete();
			_fxShakeComplete = null;
			_fxShakeTime = null;

			_fxShakeAngle = 0;
			_fxShakePos.set();

			calcRotatedBounds();
			calcAngleTris();
			updateInternalSpritePositions();
			return;
		}

		if (_fxShakeBetter) {
			final s = 1 - (_fxShakeEase == null ? 0 : _fxShakeEase(_fxShakeTime / _fxShakeDuration));
			_fxShakePos.set(
				FlxSimplex.simplex(_fxShakeTimeX += elapsed * _fxShakeSpeedX * s * 24, 0) * _fxShakeIntensityX * s * width,
				FlxSimplex.simplex(0, _fxShakeTimeY += elapsed * _fxShakeSpeedY * s * 24) * _fxShakeIntensityY * s * height
			);
			_fxShakeAngle = FlxSimplex.simplex(0, _fxShakeTimeAngle += elapsed * _fxShakeSpeedAngle * s * 24) * _fxShakeIntensityAngle * s;
		}
		else {
			_fxShakePos.set(FlxG.random.float(-1, 1) * _fxShakeIntensityX * width, FlxG.random.float(-1, 1) * _fxShakeIntensityY * height);
			_fxShakeAngle = FlxG.random.float(-1, 1) * _fxShakeAngle;
		}

		if (pixelPerfectShake == null ? pixelPerfectRender : pixelPerfectShake) _fxShakePos.round();
		if (_fxShakeScroll) {
			_fxShakePos.scale(1 / scaleX, 1 / scaleY);
			scroll.addPoint(_fxShakePos);
			_fxShakeWasScroll = true;
		}

		calcRotatedBounds();
		calcAngleTris();
		updateInternalSpritePositions();
	}

	function updatePerspective() {
		if (!updateViewPerspective) return;

		perspective.setPosition(scroll.x, scroll.y);
		perspective.updateViewMatrix();
	}

	public function addShader(shader:FlxShader):ShaderFilter {
		if (filters == null) filters = [];
		final filter = new ShaderFilter(shader);
		filters.push(filter);
		return filter;
	}

	public function insertShader(index:Int, shader:FlxShader):ShaderFilter {
		if (filters == null) filters = [];
		final filter = new ShaderFilter(shader);
		filters.insert(index, filter);
		return filter;
	}

	public function removeShader(shader:FlxShader):Null<ShaderFilter> {
		if (filters != null) {
			for (filter in filters) {
				if (filter is ShaderFilter && cast(filter, ShaderFilter).shader == shader) {
					filters.remove(filter);
					return cast filter;
				}
			}
		}
		return null;
	}

	public function freeze() {
		_freeze = (freezed = true) && _useBuffer;
		if (!_useBuffer) BitmapDataUtil.clear(buffer, bgColor, true);
	}
	public function unfreeze() _freeze = freezed = false;

	override function stopFX() {
		super.stopFX();
		_fxTintAlpha = 0.0;
	}

	override function render() {
		if (!visible) return;

		if (_freeze) {
			if (canvas.visible || _flashBitmap.visible) {
				present();
				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}
			return;
		}

		if (_headOfDrawStack == null) {
			if (_presented = useBgAlphaBlending && bgColor.alpha != 0) BitmapDataUtil.draw(buffer, canvas, canvas.__transform, false, true);
			if (!appliedFilters && filtersEnabled && filters != null && filters.length > 0) {
				BitmapDataUtil.applyFilters(buffer, filters);
				_presented = true;
			}
			if (_presented) present();
			else _flashBitmap.visible = canvas.visible = false;
		}
		else if (_useBuffer = useBuffer || freezed || grabbed || useBgAlphaBlending || alpha < 1 ||
			(filtersEnabled && filters != null && filters.length > 0)
		) {
			if (grabbed && !appliedFilters && filtersEnabled) BitmapDataUtil.applyFilters(buffer, filters);
			else drawScreen(filtersEnabled);
			present();
		}
		else {
			continueDraw();
			canvas.visible = true;
			_flashBitmap.visible = false;
		}

		#if FLX_DEBUG
		FlxBasic.visibleCount++;
		#end
		_freeze = freezed;
	}

	private function present() {
		canvas.graphics.clear();
		_flashBitmap.bitmapData = buffer;
		_flashBitmap.scaleX = width / buffer.width;
		_flashBitmap.scaleY = height / buffer.height;
		_flashBitmap.smoothing = smoothing;
		_useBuffer = _flashBitmap.visible = _presented = true;
		canvas.visible = false;
	}

	override function clearDrawStack() {
		super.clearDrawStack();
		_continueDrawStack = null;
		_presented = grabbed = appliedFilters = false;
	}

	private function resizeScreen(?bitmap:BitmapData):BitmapData {
		final desiredWidth = Math.floor((resolutionWidth ?? width) * (keepResolutionScale ? FlxG.scaleMode.scale.x : 1)),
			desiredHeight = Math.floor((resolutionHeight ?? height) * (keepResolutionScale ? FlxG.scaleMode.scale.y : 1));

		if (bitmap == null) return BitmapDataUtil.create(desiredWidth, desiredHeight);

		BitmapDataUtil.resize(bitmap, desiredWidth, desiredHeight);
		return bitmap;
	}

	public function grabScreen(?bitmap:BitmapData, applyFilters = false, isolate = false, resize = false):BitmapData {
		if (appliedFilters && applyFilters) trace('trying to apply a filter on a applied filters grabbed screen buffer.');

		if (isolate) canvas.graphics.clear();
		continueDraw();

		if (resize || bitmap == null) bitmap = resizeScreen(bitmap);
		if (bitmap.width != width || bitmap.height != height) {
			_helperMatrix.copyFrom(canvas.__transform);
			_helperMatrix.scale(bitmap.width / width, bitmap.height / height);
			BitmapDataUtil.draw(bitmap, canvas, _helperMatrix, true, true);
		}
		else
			BitmapDataUtil.draw(bitmap, canvas, canvas.__transform, false, true);

		if (applyFilters) BitmapDataUtil.applyFilters(bitmap, filters);

		return bitmap;
	}

	private function drawScreen(?applyFilters:Bool, skipDrawStack = false, skipGrab = false) {
		if (!skipGrab) buffer = grabScreen(buffer, applyFilters, false, true);
		if (!appliedFilters) appliedFilters = applyFilters;
		_frame.sourceSize.set(buffer.width, buffer.height);
		_frame.frame = _frame.frame.set(0, 0, buffer.width, buffer.height);

		clearDrawStack();
		grabbed = true;

		canvas.graphics.clear();
		drawFill(_frame, buffer, null, null, smoothing);
		if (skipDrawStack) _continueDrawStack = _headOfDrawStack;
	}

	override function draw() {
		var item = _headOfDrawStack;
		while (item != null) {
			(_continueDrawStack = item).render(this);
			item = item.next;
		}
	}

	function continueDraw() {
		var item = _continueDrawStack != null ? _continueDrawStack.next : _headOfDrawStack;
		while (item != null) {
			(_continueDrawStack = item).render(this);
			item = item.next;
		}
	}

	public function drawFill(?frame:FlxFrame, ?pixels:BitmapData, ?matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false,
		?shader:FlxShader)
	{
		if (matrix == null) _helperMatrix.copyFrom(canvas.__transform);
		else {
			_helperMatrix.copyFrom(matrix);
			_helperMatrix.invert();
			_helperMatrix.concat(canvas.__transform);
		}

		_helperMatrix.scale(frame.frame.width / width, frame.frame.height / height);
		_helperMatrix.invert();

		drawPixels(frame, pixels, _helperMatrix, transform, blend, smoothing, shader);
	}

	override function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false,
		?shader:FlxShader)
	{
		if (shouldDraw) super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
	}

	inline function _drawFX(color:FlxColor, alpha:Float, blend:BlendMode) {
		if (alpha > 0.0) {
			final a = color.alpha;
			canvas.graphics.overrideBlendMode(blend);
			fill(color.to24Bit(), true, ((a <= 0) ? 0xff : a) * alpha / 255, canvas.graphics);
		}
	}

	override function fill(color:FlxColor, blendAlpha = true, fxAlpha = 1.0, ?graphics:Graphics) {
		if (_freeze) return;

		if (_useBuffer && !blendAlpha && !grabbed) BitmapDataUtil.clear(buffer, color, true);
		else if (_presented) {
			canvas.graphics.clear();
			canvas.graphics.beginFill(color, fxAlpha);
			canvas.graphics.drawRect(0, 0, buffer.width, buffer.height);
			canvas.graphics.endFill();

			BitmapDataUtil.draw(buffer, canvas);
		}
		else if (fxAlpha > 0) {
			final targetGraphics = (graphics == null) ? canvas.graphics : graphics;

			targetGraphics.overrideBlendMode(NORMAL);
			targetGraphics.beginFill(color, fxAlpha);
			targetGraphics.drawRect(viewMarginLeft - 1, viewMarginTop - 1, viewWidth + 2, viewHeight + 2);
			targetGraphics.endFill();
		}
	}

	override function drawFX() {
		_drawFX(_fxFlashColor, _fxFlashAlpha, ADD);
		_drawFX(_fxFadeColor, _fxFadeAlpha, NORMAL);
		_drawFX(_fxTintColor, _fxTintAlpha, _fxTintBlend);
	}

	override function checkResize() {
		screen.pixels = buffer = resizeScreen(buffer);
		screen.origin.set();
		_flashRect.width = width;
		_flashRect.height = height;

		if (FlxG.renderBlit) updateBlitMatrix();
	}

	function set_rotation(rotation:Float):Float {
		flashSprite.rotation = rotation;
		return this.rotation = rotation;
	}

	override function set_angle(angle:Float):Float {
		this.angle = angle;

		calcAngleTris();
		calcRotatedBounds();
		calcMarginX();
		calcMarginY();
		updateInternalSpritePositions();

		return angle;
	}

	override function set_alpha(value:Float):Float {
		alpha = FlxMath.bound(value, 0, 1);

		if (_useBuffer) _flashBitmap.alpha = alpha;
		else canvas.alpha = alpha;

		return alpha;
	}

	override function set_color(value:FlxColor):FlxColor {
		color = value;

		var colorTransform:ColorTransform;
		if (_useBuffer) {
			if (_flashBitmap == null) return color;
			colorTransform = _flashBitmap.transform.colorTransform;
		}
		else
			colorTransform = canvas.transform.colorTransform;

		colorTransform.redMultiplier = color.redFloat;
		colorTransform.greenMultiplier = color.greenFloat;
		colorTransform.blueMultiplier = color.blueFloat;

		if (_useBuffer)
			_flashBitmap.transform.colorTransform = colorTransform;
		else
			canvas.transform.colorTransform = colorTransform;

		return color;
	}

	override function set_zoom(zoom:Float):Float {
		_zoom = this.zoom = zoom;
		setScale(zoom, zoom);
		return zoom;
	}

	override function set_width(value:Int):Int {
		if (width != value && (width = value) > 0) {
			calcRotatedBounds();
			calcMarginX();
			updateFlashOffset();
			updateScrollRect();
			updateInternalSpritePositions();
			FlxG.cameras.cameraResized.dispatch(this);
		}
		return value;
	}

	override function set_height(value:Int):Int {
		if (height != value && (height = value) > 0) {
			calcRotatedBounds();
			calcMarginY();
			updateFlashOffset();
			updateScrollRect();
			updateInternalSpritePositions();
			FlxG.cameras.cameraResized.dispatch(this);
		}
		return value;
	}

	override function setScale(X:Float, Y:Float) {
		totalScaleX = (scaleX = X) * FlxG.scaleMode.scale.x;
		totalScaleY = (scaleY = Y) * FlxG.scaleMode.scale.y;

		calcMarginX();
		calcMarginY();
		updateScrollRect();
		updateInternalSpritePositions();

		FlxG.cameras.cameraResized.dispatch(this);
	}

	override function updateScrollRect() {
		final rect = _scrollRect?.scrollRect;
		if (rect != null) {
			rect.setTo(0, 0, width * initialZoom, height * initialZoom);
			_scrollRect.scrollRect = rect;
			_scrollRect.x = -0.5 * rect.width * (_scrollRect.scaleX = FlxG.scaleMode.scale.x);
			_scrollRect.y = -0.5 * rect.height * (_scrollRect.scaleY = FlxG.scaleMode.scale.y);
		}
	}

	inline function doCanvasMatrix(matrix:FlxMatrix) {
		if (_fxShakeScroll) matrix.setTo(scaleX, 0, 0, scaleY, (-0.5 * width) * scaleX, (-0.5 * height) * scaleY);
		else matrix.setTo(scaleX, 0, 0, scaleY, (-0.5 * width + _fxShakePos.x) * scaleX, (-0.5 * height + _fxShakePos.y) * scaleY);
		matrix.rotateWithTrig(_cosAngle, _sinAngle);
		matrix.translate(0.5 * width, 0.5 * height);
	}

	override function updateInternalSpritePositions() {
		if (_flashBitmap != null) {
			_flashBitmap.x = _flashBitmap.y = 0;
		}
		if (canvas != null) {
			doCanvasMatrix(_helperMatrix);
			canvas.transform.matrix = _helperMatrix;
			#if FLX_DEBUG
			if (debugLayer != null) debugLayer.transform.matrix = _helperMatrix;
			#end
		}
	}

	inline function calcRotatedBounds()
		_rotatedBounds.getRotatedBounds(angle + _fxShakeAngle, null, _rotatedBounds.set(0, 0, width, height));

	inline function calcAngleTris() {
		final radians = (angle + _fxShakeAngle) * FlxAngle.TO_RAD;
		_sinAngle = Math.sin(radians);
		_cosAngle = Math.cos(radians);
	}

	override function calcMarginX() {
		final rotatedScaleX = width / _rotatedBounds.width * scaleX;
		viewMarginX = 0.5 * width * (rotatedScaleX - initialZoom) / rotatedScaleX;
	}

	override function calcMarginY() {
		final rotatedScaleY = height / _rotatedBounds.height * scaleY;
		viewMarginY = 0.5 * height * (rotatedScaleY - initialZoom) / rotatedScaleY;
	}

	override function destroy() {
		buffer = BufferPool.put(buffer);
		if (_frame?.parent != null) {
			Reflect.setField(_frame.parent, 'bitmap', null); // bypassAccessor here doesnt work for some reason
			_frame.parent.destroy();
		}
		perspective = FlxDestroyUtil.destroy(perspective);
		_frame = FlxDestroyUtil.destroy(_frame);
		screen = FlxDestroyUtil.destroy(screen);
		_scroll = FlxDestroyUtil.put(_scroll);
		_rotatedBounds = FlxDestroyUtil.put(_rotatedBounds);
		_fxShakePos = FlxDestroyUtil.put(_fxShakePos);
		FlxDestroyUtil.removeChild(_scrollRect, _flashBitmap);
		_flashBitmap = null;
		super.destroy();
	}
}