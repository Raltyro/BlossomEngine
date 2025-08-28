package blossom;

import openfl.display.BitmapData;
import openfl.geom.ColorTransform;

import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxAxes;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;

using flixel.util.FlxColorTransformUtil;

#if flixel_animate
import animate.internal.Frame;
import animate.internal.Timeline;
import animate.FlxAnimateController.FlxAnimateAnimation;
import animate.FlxAnimateFrames;

typedef BLGraphicAsset = OneOfFive<FlxAnimateFrames, FlxAtlasFrames, FlxGraphic, BitmapData, String>;
#else
typedef BLGraphicAsset = OneOfFour<FlxAtlasFrames, FlxGraphic, BitmapData, String>;
#end

typedef BLAnimData = {
	name:String,
	?id:String,
	?indices:Array<Int>,
	?fps:Float,
	?loop:Bool,
	?flipX:Bool,
	?flipY:Bool,
	?offset:OneOfTwo<Array<Float>, FlxPoint>,
	?asset:BLGraphicAsset
}

class BLSprite extends flixel.FlxSprite {
	public static function create(x = 0.0, y = 0.0, ?graphic:BLGraphicAsset, ?antialiasing:Bool, ?centerAxes:FlxAxes,
			?scale:Array<Float>, ?scalePoint:FlxPoint,
			?scrollFactor:Array<Float>, ?scrollFactorPoint:FlxPoint,
			?zoomFactor:Array<Float>, ?zoomFactorPoint:FlxPoint,
			?animations:Array<BLAnimData>):BLSprite
	{
		final sprite = new BLSprite(x, y, graphic, animations);

		if (antialiasing != null) sprite.antialiasing = antialiasing;

		if (scale != null) sprite.scale.set(scale[0], scale.length == 1 ? scale[0] : scale[1]);
		else if (scalePoint != null) sprite.scale.copyFrom(scalePoint);

		if (scrollFactor != null) sprite.scrollFactor.set(scrollFactor[0], scrollFactor.length == 1 ? scrollFactor[0] : scrollFactor[1]);
		else if (scrollFactorPoint != null) sprite.scrollFactor.copyFrom(scrollFactorPoint);

		if (zoomFactor != null) sprite.zoomFactor.set(zoomFactor[0], zoomFactor.length == 1 ? zoomFactor[0] : zoomFactor[1]);
		else if (zoomFactorPoint != null) sprite.zoomFactor.copyFrom(zoomFactorPoint);

		sprite.updateHitbox();

		if (centerAxes != null) {
			sprite.screenCenter(centerAxes);
			if (centerAxes.x) sprite.x = Math.floor(sprite.x) + x;
			if (centerAxes.y) sprite.y = Math.floor(sprite.y) + y;
		}

		return sprite;
	}

	public var useFallbackOrigin:Bool = true;
	public var useFallbackOffset:Bool = true;
	public var sourceSize:Null<FlxPoint>;

	public var zoomFactor(default, null):FlxPoint;

	public var skew(default, null):FlxPoint;
	public var transformMatrix(default, null):FlxMatrix;
	public var matrixExposed:Bool = false;

	public var anim(default, set):BLAnimationController;
	public var isAnimate(default, null):Bool = false;

	#if flixel_animate
	public var library(default, null):FlxAnimateFrames;
	public var timeline(default, null):Timeline;
	public var applyStageMatrix:Bool = false;
	public var renderStage:Bool = false;
	#end

	var _rect2:FlxRect;
	var _matrix2:FlxMatrix;
	var _colorTransform:ColorTransform;

	public function new(x = 0.0, y = 0.0, ?graphic:BLGraphicAsset, ?animations:Array<BLAnimData>) {
		super(x, y);
		if (graphic != null) loadBLGraphic(graphic, animations);
	}

	override function initVars() {
		super.initVars();

		anim = new BLAnimationController(this);

		zoomFactor = FlxPoint.get(1, 1);
		skew = FlxPoint.get();

		transformMatrix = new FlxMatrix();

		_rect2 = FlxRect.get();
		_matrix2 = new FlxMatrix();
		_colorTransform = new ColorTransform();
	}

	override function destroy() {
		super.destroy();

		zoomFactor = FlxDestroyUtil.put(zoomFactor);
		skew = FlxDestroyUtil.put(skew);
		anim = FlxDestroyUtil.destroy(anim);

		transformMatrix = null;
		library = null;
		timeline = null;

		_rect2 = FlxDestroyUtil.put(_rect2);
		_matrix2 = null;
		_colorTransform = null;
	}

	override function clone():BLSprite {
		final sprite = new BLSprite(x, y).loadGraphicFromSprite(this);
		sprite.scale.copyFrom(this.scale);
		sprite.scrollFactor.copyFrom(this.scrollFactor);
		sprite.zoomFactor.copyFrom(this.zoomFactor);
		return sprite;
	}

	override function loadGraphicFromSprite(sprite:FlxSprite):BLSprite {
		super.loadGraphicFromSprite(sprite);
		return this;
	}

	override function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):BLSprite {
		if (graphic is String) super.loadGraphic(AssetUtil.getGraphic(cast graphic), animated, frameWidth, frameHeight, unique, key);
		else super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
		return this;
	}

	public function makeSolidColor(width:Float, height:Float, color = FlxColor.WHITE):BLSprite {
		var graph:FlxGraphic = FlxG.bitmap.create(1, 1, color);
		frames = graph.imageFrame;
		antialiasing = false;
		
		#if FLX_TRACK_GRAPHICS
		graph.trackingInfo = '$ID.makeSolid($width, $height, ${color.toHexString()})';
		#end
		
		scale.set(width, height);
		updateHitbox();
		
		return this;
	}

	public function fixHitbox(centerOrigin = true) {
		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
		if (centerOrigin) this.centerOrigin();
	}

	public function scaleToGame():BLSprite {
		final v = 1.0 / Math.min(width / FlxG.width, height / FlxG.height);
		scale.set(v, v);
		updateHitbox();

		return this;
	}

	public function loadBLGraphic(graphic:BLGraphicAsset, ?animations:Array<BLAnimData> #if flixel_animate , ?settings:FlxAnimateSettings #end):BLSprite {
		if ((animations != null && animations.length != 0) || graphic is FlxAtlasFrames) return loadFrames(graphic, animations, #if flixel_animate graphic is FlxAnimateFrames #end);
		else if (graphic is String) {
			var path:String = graphic;
			var base = Paths.withoutExtension(path);
			#if flixel_animate
			if (base == path && AssetUtil.textExists('$base/Animation.json')) {
				final animPath = '$base/anims.json';
				return loadFrames(base, AssetUtil.textExists(animPath) ? null : null, true, settings);
			}
			else #end if (AssetUtil.textExists('$base.xml')) {
				final animPath = '$base-anims.json';
				return loadFrames(path, AssetUtil.textExists(animPath) ? null : null);
			}
			else if (AssetUtil.textExists(Paths.withoutExtension(path = '$base/sprites.${Paths.extension(path)}') + ".xml")) {
				final animPath = '$base/anims.json';
				return loadFrames(path, AssetUtil.textExists(animPath) ? null : null);
			}
		}

		return loadGraphic(cast graphic);
	}

	public function loadFrames(graphic:BLGraphicAsset, ?animations:Array<BLAnimData>, isAnimate = false #if flixel_animate , ?settings:FlxAnimateSettings #end) {
		if (graphic is BitmapData) throw "BitmapData is unsupported";
		else if (graphic is FlxAtlasFrames) frames = graphic; // FlxAnimateFrames gets applied here too
		#if flixel_animate
		else if (isAnimate) frames = AssetUtil.getAnimateAtlas(cast graphic, settings);
		#end
		else frames = AssetUtil.getSparrowAtlas(cast graphic);

		if (animations != null) {
			for (data in animations) anim.addByData(data);
		}

		return this;
	}

	public function isSimpleZoomFactor():Bool return FlxMath.equal(1, zoomFactor.x) && FlxMath.equal(1, zoomFactor.y);

	private inline function prepareZoomFactor(?rect:FlxRect, camera:FlxCamera):FlxRect {
		return (_rect2 ?? FlxRect.get()).set(
			camera.width * 0.5 + camera.scroll.x * scrollFactor.x,
			camera.height * 0.5 + camera.scroll.y * scrollFactor.y,
			(camera.scaleX > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleX, 1, zoomFactor.x)),
			(camera.scaleY > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleY, 1, zoomFactor.y))
		);
	}

	override function isSimpleRender(?camera:FlxCamera):Bool {
		return if (FlxG.renderTile) false;
			else isSimpleZoomFactor() && isSimpleRenderBlit(camera) && (skew.x == 0) && (skew.y == 0) && !matrixExposed;
	}

	override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect {
		if (camera == null) camera = getDefaultCamera();
		newRect = super.getScreenBounds(newRect, camera);

		#if flixel_animate
		if (isAnimate) {
			// TODO: add skewed bounds expansion
			if (applyStageMatrix) Timeline.applyMatrixToRect(newRect, library.matrix);
		}
		#end

		if (!isSimpleZoomFactor()) {
			prepareZoomFactor(_rect2, camera);
			newRect.set(
				(newRect.x - _rect2.x) * _rect2.width + _rect2.x,
				(newRect.y - _rect2.y) * _rect2.height + _rect2.y,
				newRect.width * _rect2.width,
				newRect.height * _rect2.height,
			);
		}

		return newRect;
	}

	override function drawComplex(camera:FlxCamera) {
		if (isAnimate) drawTimeline(timeline, camera);
		else drawFrameComplex(_frame, camera);
	}

	override function drawFrameComplex(frame:FlxFrame, camera:FlxCamera) {
		frame.prepareMatrix(_matrix, ANGLE_0, checkFlipX(), checkFlipY());
		applyMatrixDrawing(_matrix, camera);
		camera.drawPixels(frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}

	inline function applyMatrixDrawing(matrix:FlxMatrix, camera:FlxCamera) {
		_matrix.translate(-origin.x, -origin.y);

		updateTrig();
		matrix.rotateWithTrig(_cosFrameOffsetAngle, _sinFrameOffsetAngle);
		matrix.translate(-frameOffset.x, -frameOffset.y);
		if (animation.curAnim != null) {
			if (animation.curAnim.offset != null) matrix.translate(-animation.curAnim.offset.x, -animation.curAnim.offset.y);
		}
		matrix.rotateWithTrig(_cosFrameOffsetAngle, -_sinFrameOffsetAngle);
		matrix.scale(scale.x, scale.y);

		if (matrixExposed) matrix.concat(transformMatrix);
		else {
			if (bakedRotationAngle <= 0) {
				if (angle != 0) matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}
			if (skew.x != 0 || skew.y != 0) matrix.skew(skew.x, skew.y);
		}

		getScreenPosition(_point, camera).subtract(offset).add(origin.x, origin.y);
		matrix.translate(_point.x, _point.y);

		if (!isSimpleZoomFactor()) {
			prepareZoomFactor(_rect2, camera);
			matrix.setTo(
				matrix.a * _rect2.width, matrix.b * _rect2.height,
				matrix.c * _rect2.width, matrix.d * _rect2.height,
				(matrix.tx - _rect2.x) * _rect2.width + _rect2.x,
				(matrix.ty - _rect2.y) * _rect2.height + _rect2.y,
			);
		}

		if (isPixelPerfectRender(camera)) {
			matrix.tx = Math.floor(matrix.tx);
			matrix.ty = Math.floor(matrix.ty);
		}
	}

	function drawTimeline(timeline:Timeline, camera:FlxCamera) {
		@:privateAccess _matrix.setTo(1, 0, 0, 1, -timeline._bounds.x, -timeline._bounds.y);

		if (checkFlipX()) {
			_matrix.scale(-1, 1);
			_matrix.translate(frame.sourceSize.x, 0);
		}

		if (checkFlipY()) {
			_matrix.scale(1, -1);
			_matrix.translate(0, frame.sourceSize.y);
		}

		if (applyStageMatrix) _matrix.concat(library.matrix);

		applyMatrixDrawing(_matrix, camera);

		if (renderStage) {
			final frame = FlxG.bitmap.whitePixel;
			if (frame != null) {
				_matrix2.setTo(library.stageRect.width / frame.parent.width, 0, 0, library.stageRect.height / frame.parent.height,
					-0.5 * (library.stageRect.width - 1.0), -0.5 * (library.stageRect.height - 1.0));
				_matrix2.concat(_matrix);

				_colorTransform.setMultipliers(library.stageColor);
				_colorTransform.setOffsets(0.0, 0.0, 0.0, 0.0);
				_colorTransform.concat(colorTransform);

				camera.drawPixels(frame, _matrix2, _colorTransform);
			}
		}

		timeline.currentFrame = animation.frameIndex;
		timeline.draw(camera, _matrix, colorTransform, blend, antialiasing, shader);
	}

	inline function set_anim(controller:BLAnimationController):BLAnimationController {
		animation = controller;
		return anim = controller;
	}

	override function set_frames(frames:FlxFramesCollection):FlxFramesCollection {
		if (isAnimate = ((frames = super.set_frames(frames)) is FlxAnimateFrames)) {
			library = cast frames;
			timeline = library.timeline;
			anim.updateTimelineBounds();
		}
		else {
			library = null;
			timeline = null;
		}
		return frames;
	}

	override function get_numFrames():Int
		return if (isAnimate) animation.curAnim != null ? timeline.frameCount : 0;
			else frames != null ? frames.numFrames : 0;
}

@:access(blossom.BLSprite)
class BLAnimationController extends FlxAnimationController {
	// re-invent the wheel from FlxAnimateController...
	#if flixel_animate
	public function addByFrameLabel(name:String, label:String, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool, ?timeline:Timeline) {
		if (!blSprite.isAnimate) return animateError();

		var usedTimeline = timeline ?? getDefaultTimeline();
		var foundFrames = findFrameLabelIndices(label, usedTimeline);

		if (foundFrames.length <= 0) {
			FlxG.log.warn('No frames found with label "$label" in timeline "${usedTimeline.name}".');
			return;
		}

		final anim = new FlxAnimateAnimation(this, name, foundFrames, frameRate ?? getDefaultFramerate(), looped, flipX, flipY);
		anim.timeline = usedTimeline;
		_animations.set(name, anim);
	}

	public function addByFrameLabelIndices(name:String, label:String, indices:Array<Int>, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool,
			?timeline:Timeline)
	{
		if (!blSprite.isAnimate) return animateError();

		var usedTimeline = timeline ?? getDefaultTimeline();
		var foundFrames:Array<Int> = findFrameLabelIndices(label, usedTimeline);
		var useableFrames:Array<Int> = [];

		for (index in indices) {
			var frameIndex:Null<Int> = foundFrames[index];
			if (frameIndex != null) useableFrames.push(frameIndex);
		}

		if (useableFrames.length <= 0) {
			FlxG.log.warn('No frames useable with label "$label" and indices $indices in timeline "${usedTimeline.name}".');
			return;
		}

		final anim = new FlxAnimateAnimation(this, name, useableFrames, frameRate ?? getDefaultFramerate(), looped, flipX, flipY);
		anim.timeline = usedTimeline;
		_animations.set(name, anim);
	}

	public function addByTimeline(name:String, ?timeline:Timeline, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool) 
		inline addByTimelineIndices(name, timeline, [for (i in 0...(timeline ?? getDefaultTimeline()).frameCount) i], frameRate, looped, flipX, flipY);

	public function addByTimelineIndices(name:String, ?timeline:Timeline, indices:Array<Int>, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool,
			?flipY:Bool)
	{
		if (!blSprite.isAnimate) return animateError();

		final anim = new FlxAnimateAnimation(this, name, indices, frameRate ?? getDefaultFramerate(), looped, flipX, flipY);
		anim.timeline = timeline ?? getDefaultTimeline();
		_animations.set(name, anim);
	}

	public function addBySymbol(name:String, symbolName:String, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool) {
		if (!blSprite.isAnimate) return animateError();

		final symbol = blSprite.library.getSymbol(symbolName);
		if (symbol == null) {
			FlxG.log.warn('Symbol not found with name "$symbolName"');
			return;
		}

		final anim = new FlxAnimateAnimation(this, name, [for (i in 0...symbol.timeline.frameCount) i], frameRate ?? getDefaultFramerate(), looped, flipX, flipY);
		anim.timeline = symbol.timeline;
		_animations.set(name, anim);
	}

	public function addBySymbolIndices(name:String, symbolName:String, indices:Array<Int>, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool) {
		if (!blSprite.isAnimate) return animateError();

		final symbol = blSprite.library.getSymbol(symbolName);
		if (symbol == null) {
			FlxG.log.warn('Symbol not found with name "$symbolName"');
			return;
		}

		final anim = new FlxAnimateAnimation(this, name, indices, frameRate ?? getDefaultFramerate(), looped, flipX, flipY);
		anim.timeline = symbol.timeline;
		_animations.set(name, anim);
	}

	public function findFrameLabelIndices(label:String, ?timeline:Timeline):Array<Int> {
		final foundFrames:Array<Int> = [], mainTimeline = timeline ?? getDefaultTimeline();
		var hasFoundLabel:Bool = false;

		for (layer in mainTimeline.layers) {
			for (frame in layer.frames) {
				if (frame.name.rtrim() == label) {
					hasFoundLabel = true;
					for (i in 0...frame.duration) foundFrames.push(frame.index + i);
				}
			}

			if (hasFoundLabel) break;
		}

		return foundFrames;
	}

	inline function animateError() FlxG.log.warn('Sprite is not loaded with a texture atlas.');

	var animateFrame:FlxFrame;

	@:allow(blossom.BLSprite)
	function updateTimelineBounds() {
		if (animateFrame == null) {
			animateFrame = new FlxFrame(blSprite.graphic);
			animateFrame.frame = FlxRect.get();
		}

		@:privateAccess
		var bounds = blSprite.timeline._bounds;
		animateFrame.parent = blSprite.graphic;
		animateFrame.sourceSize.set(bounds.width, bounds.height);
		animateFrame.frame.copyFrom(bounds);
		blSprite.frame = animateFrame;
	}
	#end

	public function addByData(data:BLAnimData, preload = false) {
		// TODO: allow for hybrid normal sprites and flixel_animate sprites
		if (data.asset != null) {
			if (preload || !(data.asset is String)) {
				
			}
			else {
				
			}
		}

		#if flixel_animate
		if (blSprite.isAnimate) {
			if (data.indices != null) {
				if (data.id == null) addByTimelineIndices(data.name, data.indices, data.fps, data.loop, data.flipX, data.flipY);
				else addBySymbolIndices(data.name, data.id, data.indices, data.fps, data.loop, data.flipX, data.flipY);
			}
			else addBySymbol(data.name, data.id ?? data.name, data.fps, data.loop, data.flipX, data.flipY);
		}
		else #end {
			if (data.indices != null) {
				if (data.id == null) add(data.name, data.indices, data.fps, data.loop, data.flipX, data.flipY);
				else addByIndices(data.name, data.id, data.indices, "", data.fps, data.loop, data.flipX, data.flipY);
			}
			else addByPrefix(data.name, data.id ?? data.name, data.fps, data.loop, data.flipX, data.flipY);
		}

		final animation = getByName(data.name);
		if (animation != null) {
			if (data.offset != null) {
				if (data.offset is Array) animation.offset.set(data.offset[0], data.offset[1]);
				else animation.offset.copyFrom(data.offset);
			}
		}
	}

	public function loadPendingAnimations() {
		//for (anim in _pendingAnimations.keys()) addByData(_pendingAnimations.get(anim), true);
	}

	public function new(sprite:BLSprite) super(sprite);

	override function play(animName:String, force = false, reversed = false, frame = 0) {
		// load pending animation here if animName is pending
		// if (_pendingAnimations.exists(animName)) addByData(animName, true);

		super.play(animName, force, reversed, frame);
		blSprite.fixHitbox();
	}

	override function set_frameIndex(frame:Int):Int {
		if (numFrames > 0) {
			frame = frame % numFrames;

			#if flixel_animate
			if (blSprite.isAnimate) {
				blSprite.timeline = cast(_curAnim, FlxAnimateAnimation).timeline;
				blSprite.timeline.currentFrame = frame;
				@:privateAccess blSprite.timeline.signalFrameChange(frame);

				updateTimelineBounds();
			}
			else
			#end {
				_sprite.frame = _sprite.frames.frames[frame];
			}

			frameIndex = frame;
			fireCallback();
		}

		return frameIndex;
	}

	var blSprite(get, never):BLSprite;
	inline function get_blSprite():BLSprite
		return cast _sprite;

	public inline function getDefaultFramerate():Float
		return #if flixel_animate blSprite.library?.frameRate ?? #end 30;

	#if flixel_animate
	public inline function getDefaultTimeline():Timeline
		return blSprite.library?.timeline;
	#end

	override function destroy() {
		super.destroy();

		#if flixel_animate
		animateFrame = FlxDestroyUtil.destroy(animateFrame);
		#end
	}
}