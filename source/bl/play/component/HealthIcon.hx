package bl.play.component;

#if !macro
import openfl.display.BitmapData;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.util.typeLimit.OneOfTwo;
import flixel.FlxCamera;

import bl.play.component.Character.CharacterIconData;
import bl.util.ParseUtil;
#end

// Use Character.make(charID, true).getHealthIcon() instead
class HealthIcon extends BLSprite {
	public static final DEFAULT_HEALTH_ICON:String = 'unknown';
	public static final prefix:String = 'icons/';

	public static function getIcon(?icon:String, ?library:String, defaultIfMissing:Bool = true):String {
		if (icon != null) {
			var path:String = Paths.image(prefix + icon, library);
			#if macro
			return path;
			#else
			if (AssetUtil.graphicExists(path)) return path;
			#end
		}
		return if (defaultIfMissing) Paths.image(prefix + DEFAULT_HEALTH_ICON); else null;
	}

	#if !macro
	public var iconOffset:FlxPoint;
	public var iconZoom:Float = 1;
	public var sprTracker:FlxSprite;

	public var iconColor:FlxColor = FlxColor.WHITE;
	public var loseThreshold:Float = 0.4;
	public var winThreshold:Float = 1.6;
	public var canUpdate:Bool = true;
	public var dontFlip:Bool = false;

	private var _scale:FlxPoint;

	public function new(?icon:BLGraphicAsset, ?data:CharacterIconData, ?library:String, ?animArray:Array<BLAnimData>) {
		super();

		if (data != null) {
			loadIconData(data);
			if (data.image != null) return;
		}

		if (icon is String) loadIconPath(icon, library);
		else loadIconGraphic(icon == null ? getIcon() : icon, animArray);
	}

	public function loadIconPath(path:String, ?library:String)
		return loadIconGraphic(Paths.dir(path) != '' ? path : getIcon(path, library));

	public function loadIconData(data:CharacterIconData):HealthIcon {
		iconColor = ParseUtil.parseColor(data.color);
		loseThreshold = data.loseThreshold ?? 0.4;
		winThreshold = data.winThreshold ?? 0.4;
		dontFlip = data.dontFlip ?? false;
		return loadIconGraphic((data.image != null && Paths.dir(data.image) != '') ? data.image : getIcon(data.image));
	}

	inline function addFramesPrefix(name:String, loop = false) if (hasFrames(name)) animation.addByPrefix(name, name, 24, loop);
	public function loadIconGraphic(graphic:BLGraphicAsset, ?animArray:Array<BLAnimData>):HealthIcon {
		loadBLGraphic(graphic, animArray);

		if (!hasAnim(Idle)) {
			if (numFrames < 2) {
				loadGraphic(this.graphic, true, this.graphic.height, this.graphic.height);
				animation.add(Idle, [0]);
				if (animation.numFrames > 1) animation.add(Losing, [1]);
				if (animation.numFrames > 2) animation.add(Winning, [2]);
			}
			else {
				addFramesPrefix(Idle, true); addFramesPrefix(Losing, true); addFramesPrefix(Winning, true);
				addFramesPrefix(ToLosing); addFramesPrefix(ToWinning); addFramesPrefix(FromLosing); addFramesPrefix(FromWinning);
			}
		}
		playAnim(Idle);

		return this;
	}

	public function updateHealthIcon(health:Float) {
		if (!canUpdate) return;
		switch (curAnim?.name ?? Idle) {
			case Idle:
				if (health <= loseThreshold) playAnim(ToLosing, Losing);
				else if (health >= winThreshold) playAnim(ToWinning, Winning);
				else playAnim(Idle);
			case Winning:
				if (health < winThreshold) playAnim(FromWinning, Idle);
				else playAnim(Winning, Idle);
			case Losing:
				if (health > loseThreshold) playAnim(FromLosing, Idle);
				else playAnim(Losing, Idle);
			case ToLosing:
				if (animation.finished) playAnim(Losing, Idle);
			case ToWinning:
				if (animation.finished) playAnim(Winning, Idle);
			case FromLosing | FromWinning:
				if (animation.finished) playAnim(Idle);
			default:
				playAnim(Idle);
		}
	}

	override function playAnim(name:String, ?fallback:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):BLSprite {
		if (!hasAnim(name)) {
			if (fallback == null && fallbackAnim != null && name != fallbackAnim.name) return playAnim(fallbackAnim.name, force, reversed, frame);
			else if (fallback != null) return playAnim(fallback, force, reversed, frame);
			return cast this;
		}
		return super.playAnim(name, fallback, force, reversed, frame);
	}

	override function initVars() {
		super.initVars();
		iconOffset = FlxPoint.get();
		_scale = FlxPoint.get();
	}

	override function destroy() {
		super.destroy();
		iconOffset = flixel.util.FlxDestroyUtil.put(iconOffset);
		_scale = flixel.util.FlxDestroyUtil.put(_scale);
	}

	override function updateHitbox() {
		super.updateHitbox();
		width *= iconZoom;
		height *= iconZoom;
		offset.add(-0.5 * (frameWidth * iconZoom - frameWidth), -0.5 * (frameHeight * iconZoom - frameHeight));
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 36);
	}

	override function draw() {
		if (iconZoom == 1) return super.draw();
		_scale.copyFrom(scale);
		scale.scale(iconZoom);
		super.draw();
		_scale.copyTo(scale);
	}

	override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint {
		final x = -iconOffset.x, y = -iconOffset.y;
		if (x == 0 && y == 0) return super.getScreenPosition(result, camera);

		final sx = scale.x * _facingHorizontalMult, sy = scale.y * _facingVerticalMult;
		return super.getScreenPosition(result, camera).add(x * _cosAngle * sx - y * _sinAngle * sy, y * _cosAngle * sy + x * _sinAngle * sx);
	}

	override function getRotatedBounds(?newRect:FlxRect):FlxRect {
		final sx = scale.x * _facingHorizontalMult, sy = scale.y * _facingVerticalMult, x = -iconOffset.x, y = -iconOffset.y;
		return super.getRotatedBounds(newRect).offset(x * _cosAngle * sx - y * _sinAngle * sy, y * _cosAngle * sy + x * _sinAngle * sx);
	}

	override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect {
		final x = -iconOffset.x, y = -iconOffset.y;
		if (x == 0 && y == 0) return super.getScreenBounds(newRect, camera);

		final sx = scale.x * _facingHorizontalMult, sy = scale.y * _facingVerticalMult;
		super.getScreenBounds(newRect, camera).offset(x * _cosAngle * sx - y * _sinAngle * sy, y * _cosAngle * sy + x * _sinAngle * sx);
		return if (isPixelPerfectRender(camera)) newRect.floor() else newRect;
	}
	#end
}

enum abstract HealthIconState(String) to String from String {
	public var Idle = 'idle';
	public var Winning = 'winning';
	public var Losing = 'losing';

	public var ToWinning = 'toWinning';
	public var ToLosing = 'toLosing';
	public var FromWinning = 'fromWinning';
	public var FromLosing = 'fromLosing';
}