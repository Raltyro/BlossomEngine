package bl.play.component;

import openfl.geom.ColorTransform;
import flixel.graphics.frames.FlxFrame;
import flixel.system.macros.FlxMacroUtil;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import flixel.util.FlxColorTransformUtil;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxStringUtil;
import flixel.FlxCamera;

import hxjson5.Json5;

import bl.play.component.Stage.StageCharPos;
import bl.util.BitmapDataUtil;

using StringTools;

enum abstract NoteDirection(UInt) from UInt to UInt {
	public static var fromStringMap(default, null):Map<String, NoteDirection> = FlxMacroUtil.buildMap("bl.play.component.NoteDirection", false, []);
	public static var toStringMap(default, null):Map<NoteDirection, String> = FlxMacroUtil.buildMap("bl.play.component.NoteDirection", true, []);

	var LEFT = 0;
	var DOWN = 1;
	var UP = 2;
	var RIGHT = 3;

	@:from
	public static inline function fromString(s:String) return fromStringMap.get(s.toUpperCase());

	@:to
	public inline function toString():String return toStringMap.get(this);

	public static inline function fromColumn(column:Int, key = 4) {
		// yandev ahh
		return switch (key) {
			case 2: switch (column) {
				case 0: LEFT; case 1: RIGHT; default: UP;
			}
			case 3: switch (column) {
				case 0: LEFT; case 2: RIGHT; default: UP;
			}
			case 4: switch (column) {
				case 0: LEFT; case 1: DOWN; case 3: RIGHT; default: UP;
			}
			case 5: switch (column) {
				case 0: LEFT; case 1: DOWN; case 4: RIGHT; default: UP;
			}
			case 6: switch (column) {
				case 0: LEFT; case 1 | 3: DOWN; case 5: RIGHT; default: UP;
			}
			case 7: switch (column) {
				case 0: LEFT; case 1 | 4: DOWN; case 6: RIGHT; default: UP;
			}
			case 8: switch (column) {
				case 0 | 4: LEFT; case 1 | 5: DOWN; case 3 | 7: RIGHT; default: UP;
			}
			case 9: switch (column) {
				case 0 | 5: LEFT; case 1 | 6: DOWN; case 3 | 8: RIGHT; default: UP;
			}
			default: UP;
		}
	}
}

typedef CharacterData = {
	?icon:CharacterIconData,
	image:String,
	?animations:Array<BLAnimData>,
	?name:String,

	?antialiasing:Bool,
	?strokeTime:Float,
	?holdInterval:Float,

	?flipX:Bool,
	?flipY:Bool,

	?scale:Array<Float>,
	?origin:Array<Float>,
	?cam:Array<Float>,
	?camDirection:Array<Array<Float>>,

	?width:Float,
	?height:Float,

	?deathCam:Array<Float>,
	?deathCharacterID:String,
	?deathSFX:String,
	?deathMusic:String,
	?deathEndMusic:String,

	?pauseMusic:String
}

typedef CharacterIconData = {
	?image:String,
	?color:Dynamic,
	?dontFlip:Bool,
	?loseThreshold:Float,
	?winThreshold:Float
}

@:autoBuild(bl.util.macro.BuildMacro.buildCharacters())
class Character extends BLSprite {
	public static final DEFAULT_CHARACTER:String = 'bf';
	@:noCompletion public static var characterClasses:Map<String, Class<Character>>; // DO NOT DEFINE ANYTHING TO THIS, Taken care of BuildMacro

	public static function characterExists(charID:String):Bool return characterHardcodedExists(charID) || characterAssetExists(charID);

	public static function characterHardcodedExists(charID:String):Bool return characterClasses.exists(charID);

	public static function characterAssetExists(charID:String):Bool return AssetUtil.textExists(Paths.character(charID));

	public static function preloadCharacter(charID:String):Future<Bool> {
		if (characterHardcodedExists(charID)) {
			var f:() -> Future<Dynamic> = Reflect.field(characterClasses.get(charID), 'preload');
			if (f != null) {
				var promise = new Promise<Bool>();
				f().onComplete((_) -> promise.complete(true));
				return promise.future;
			}
		}
		else {
			final path = Paths.character(charID);
			if (AssetUtil.textExists(path)) try {
				final data:CharacterData = cast Json5.parse(AssetUtil.getText(path));
				if (data != null && data.image != null) {
					var promise = new Promise<Bool>();
					AssetUtil.loadGraphic(data.image).onComplete((_) -> promise.complete(true));
					return promise.future;
				}
			}
			catch(e) {}
		}

		return Future.withValue(false);
	}

	public static function make(charID:String, ?conductor:Conductor, ?id:Int, ?dontCreate:Bool):Null<Character> {
		if (charID == null) return null;
		else return makeFromAsset(charID, conductor, id, dontCreate) ?? makeFromHardcoded(charID, conductor, id, dontCreate);
	}

	public static function makeFromHardcoded(charID:String, ?conductor:Conductor, ?id:Int, ?dontCreate:Bool):Null<Character> {
		if (characterHardcodedExists(charID)) return Type.createInstance(characterClasses.get(charID), [conductor, id, dontCreate]);
		else return null;
	}

	public static function makeFromAsset(charID:String, ?conductor:Conductor, ?id:Int, ?dontCreate:Bool):Null<Character> {
		final path = Paths.character(charID);
		if (AssetUtil.textExists(path)) {
			try {
				final data:CharacterData = cast Json5.parse(AssetUtil.getText(path));
				return new CustomCharacter(charID, data, conductor, id, dontCreate);
			}
			catch(e) {
				trace('Failed to parse JSON for Character "$path"\nError: ${e.message}');
			}
		}
		return null;
	}

	#if !hscript inline #end public static function makeWithDefault(?charID:String, ?conductor:Conductor, ?id:Int, ?dontCreate:Bool):Character
		return make(charID, conductor, id, dontCreate) ?? make(DEFAULT_CHARACTER, conductor, id, dontCreate) ?? new Character(conductor, id, dontCreate);

	public var characterID:String;
	public var characterName:String;

	public var characterIconData:CharacterIconData;

	public var created:Bool = false;

	public var deathCharacterID:Null<String>;
	public var deathSFXPath:Null<String>;
	public var deathMusicPath:Null<String>;
	public var deathEndMusicPath:Null<String>;
	public var deathCameraFocus:FlxPoint;

	public var pauseMusicPath:Null<String>;

	public var cameraFocus:FlxPoint;
	public var cameraFocusDirection:Map<NoteDirection, FlxPoint>;
	public var cameraZoomTarget:Float = 1;
	public var characterOrigin:FlxPoint;

	public var showPivot(default, set):Bool;
	public var showCameraPivot(default, set):Bool;
	public var cameraPivotUseGameOver:Bool;

	//public var characterOriginAngle(default, set):Float; // TODO
	public var stageFlipX(default, set):Bool;
	public var stageFlipY(default, set):Bool;

	public var idleSuffix:String = '';
	public var singSuffix:String = '';
	public var alternateIdle:Bool = true;
	public var canDance:Bool = true;
	public var specialAnim:Bool = false;
	public var dontPlayLoop:Bool = false;

	public var holdInterval:Float;
	public var strokeTime:Float;

	/**
	 * Beat Intervals of character dance.
	 */
	public var danceInterval:Float = 2;
	public var danceEvery:BeatType = BEAT;

	/**
	 * How much measure offset the dance is.
	 */
	public var danceOffset:Float = 0;

	/**
	 * The conductor for camera bops to work.
	 */
	public var conductor:Null<Conductor>;

	public var danced:Bool = false;
	public var singing(get, never):Bool; function get_singing() return curAnimName.startsWith('sing') && !curAnimName.endsWith('-end');
	public var currentDirection:Null<NoteDirection> = null;
	public var stagePosition:Null<StageCharPos>;

	var _pivotFrame:FlxFrame;
	var _pivotColor:ColorTransform;
	var _characterOriginScale:FlxPoint;
	var _lastBeat:Float = 0;
	var _holdTimer:Float = 0;
	var _duration:Null<Float> = 0;
	var _sinOriginAngle:Float = 0;
	var _cosOriginAngle:Float = 1;

	public function new(?conductor:Conductor, id:Int = 0, dontCreate = false) {
		characterID = characterID ?? 'fallback';
		characterName = characterName ?? 'Fallback';
		super();
		this.conductor = conductor;
		this.ID = id;

		resetCharacter();
		if (!dontCreate) {
			create();
			initFallbackAnim();
		}
	}

	public function create() {
		created = true;
	}

	inline public function initFallbackAnim() fallbackAnim = animation.getByName('idle') ?? fallbackAnim;

	#if !hscript inline #end public function getHealthIcon():HealthIcon
		return new HealthIcon(characterID, characterIconData);

	public function resetCharacter() {
		antialiasing = true;
		strokeTime = 0.13;
		holdInterval = 1;
		danceInterval = hasAnim('danceLeft') || hasAnim('danceRight') ? 1 : 2;

		flipX = false;
		flipY = false;

		scale.set(1, 1);

		characterOrigin.set(0, 0);
		cameraFocus.set(0, 0);
		deathCameraFocus.set(0, 0);

		cameraFocusDirection[LEFT].set(-30, 0);
		cameraFocusDirection[DOWN].set(0, 30);
		cameraFocusDirection[UP].set(0, -30);
		cameraFocusDirection[RIGHT].set(30, 0);

		scrollFactor.set(1, 1);

		alpha = 1;
		visible = true;
	}

	public function apply(charPos:StageCharPos) {
		resetCharacter();
		stagePosition = charPos;

		setPosition(charPos.x, charPos.y);
		scale.scale(charPos.scaleX ?? charPos.scale ?? 1, charPos.scaleY ?? charPos.scale ?? 1);
		scrollFactor.scale(charPos.scrollX ?? charPos.scroll ?? 1, charPos.scrollY ?? charPos.scroll ?? 1);

		angle = charPos.angle ?? 0;
		stageFlipX = charPos.flipX ?? false;
		stageFlipY = charPos.flipY ?? false;

		if (charPos.visible is Bool) visible = visible && charPos.visible;
		if (charPos.alpha is Float) alpha *= charPos.alpha;

		updateHitbox();
	}

	public function dance(force = false) {
		if (!alive || (!force && singing)) return;

		var suffix = idleSuffix != null && idleSuffix != '' ? '-$idleSuffix' : '';
		var anim = danced ? correctAnimName('danceLeft$suffix') : correctAnimName('danceRight$suffix');
		if (alternateIdle && anim != null) danced = !danced;
		else anim = correctAnimName('idle$suffix');

		if (anim == null) return;

		playAnim(anim, force);
		currentDirection = null;
	}

	public function sing(direction:NoteDirection, duration:Float = 0, miss = false, ?suffix:String) {
		if (!alive || specialAnim) return;

		suffix = suffix != null && suffix != '' ? '-$suffix' : (singSuffix != null && singSuffix != '' ? '-$singSuffix' : '');
		if (stageFlipX) {
			if (direction == LEFT) direction = RIGHT;
			else if (direction == RIGHT) direction = LEFT;
		}

		final fallback = 'sing${direction.toString()}${miss ? 'miss' : ''}';
		final anim = correctAnimName('$fallback$suffix', fallback);
		if (anim == null) return;

		playAnim(anim, true);
		currentDirection = direction;
		_holdTimer = 0;
		_duration = duration >= 0 ? Math.max(duration, 0) + 0.1 : null;
	}

	inline public function stopSinging(force = false) {
		_duration = force && _duration != null && _duration > 0.1 ? 0 : 0.1;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (conductor != null && !specialAnim) {
			if (singing) {
				if (_duration != null) {
					if (_duration > 0) {
						if ((_duration -= elapsed) <= 0) {
							_duration = 0;
							_lastBeat = Math.floor(conductor.currentBeatTime * 2) / 2;
						}
					}
					else if ((_duration -= Math.max(conductor.currentBeatTime - _lastBeat, 0)) < -holdInterval - 1) {
						_lastBeat = conductor.getBeats(danceEvery, danceInterval, danceOffset);
						dance(true);
					}
					else
						_lastBeat = conductor.currentBeatTime;
				}
				if ((_duration == null || _duration > 0.1) && strokeTime > 0 && (_holdTimer += elapsed) > strokeTime) {
					_holdTimer = 0;
					restartAnim();
				}
			}
			else if (canDance) {
				final beat = conductor.getBeats(danceEvery, danceInterval, danceOffset);
				if (_lastBeat != beat) {
					_lastBeat = beat;
					dance();
				}
			}
		}

		if (!dontPlayLoop && curAnim?.finished && hasAnim('${curAnimName}-loop') && (_duration != null || _duration <= 0.1 || strokeTime <= 0))
			playAnim('${curAnimName}-loop');
	}

	override function draw() {
		super.draw();
		for (camera in getCamerasLegacy()) {
			if (!camera.visible || !camera.exists) continue;
			if (showPivot) drawPivot(camera);
			if (showCameraPivot) drawCameraPivot(camera);
		}
	}

	function drawPivot(camera:FlxCamera) {
		final w = _pivotFrame.frame.width * 0.5, h = _pivotFrame.frame.height * 0.5,
			sx = _characterOriginScale.x * 2, sy = _characterOriginScale.y * 2;

		_matrix.setTo(sx, 0, 0, sy, -w * sx, -h * sy);
		if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle); // TODO: replace this with characterOriginAngle Tris
		_matrix.translate(x - camera.scroll.x * scrollFactor.x, y - camera.scroll.y * scrollFactor.y);

		FlxColorTransformUtil.setMultipliers(_pivotColor, 0.9, 0, 0, 1);
		camera.drawPixels(_pivotFrame, _matrix, _pivotColor);
	}

	function drawCameraPivot(camera:FlxCamera) {
		final w = _pivotFrame.frame.width * 0.5, h = _pivotFrame.frame.height * 0.5,
			sx = _characterOriginScale.x * 2, sy = _characterOriginScale.y * 2;

		_matrix.setTo(sx, 0, 0, sy, -w * sx, -h * sy);
		if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle); // TODO: replace this with characterOriginAngle Tris

		final cameraFocus = cameraPivotUseGameOver ? deathCameraFocus : cameraFocus;
		final sx = scale.x * (stageFlipX ? -1 : 1), sy = scale.y * (stageFlipY ? -1 : 1);
		_matrix.translate(
			x - camera.scroll.x * scrollFactor.x + cameraFocus.x * sx,
			y - camera.scroll.y * scrollFactor.y + cameraFocus.y * sy
		);

		if (currentDirection != null) {
			final p = cameraFocusDirection.get(currentDirection);
			if (p != null) _matrix.translate(p.x * sx, p.y * sy);
		}

		FlxColorTransformUtil.setMultipliers(_pivotColor, 0, cameraPivotUseGameOver ? 0.9 : 0, 0.9, 1);
		camera.drawPixels(_pivotFrame, _matrix, _pivotColor);
	}

	@:noCompletion
	override function initVars() {
		super.initVars();
		cameraFocus = FlxPoint.get();
		deathCameraFocus = FlxPoint.get();
		characterOrigin = FlxPoint.get();
		cameraFocusDirection = [for (i in NoteDirection.toStringMap.keys()) i => FlxPoint.get()];
		_characterOriginScale = FlxPoint.get().copyFrom(scale);
		_pivotColor = new ColorTransform();
	}

	override function destroy() {
		super.destroy();
		cameraFocus = FlxDestroyUtil.put(cameraFocus);
		deathCameraFocus = FlxDestroyUtil.put(deathCameraFocus);
		characterOrigin = FlxDestroyUtil.put(characterOrigin);
		_characterOriginScale = FlxDestroyUtil.put(_characterOriginScale);
		_pivotColor = null;
		if (cameraFocusDirection != null) for (i in cameraFocusDirection.keys()) FlxDestroyUtil.put(cameraFocusDirection.get(i));
		cameraFocusDirection = null;
		created = false;
	}

	// TODO: negative scales does not work as it supposed to like flipping the image with respecting origin
	override function updateHitbox() {
		super.updateHitbox();
		_characterOriginScale.set(scale.x, scale.y);
	}

	override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint {
		final x = stageFlipX ? -getSourceSizeX() * scale.x + characterOrigin.x * _characterOriginScale.x : -characterOrigin.x * _characterOriginScale.x,
			y = stageFlipY ? -getSourceSizeY() * scale.y + characterOrigin.y * _characterOriginScale.y : -characterOrigin.y * _characterOriginScale.y;

		//return super.getScreenPosition(result, camera).add(x * _cosAngle - y * _sinAngle, y * _cosAngle + x * _sinAngle);
		return super.getScreenPosition(result, camera).add(x, y);
	}

	override function getRotatedBounds(?newRect:FlxRect):FlxRect {
		final x = stageFlipX ? -getSourceSizeX() * scale.x + characterOrigin.x * _characterOriginScale.x : -characterOrigin.x * _characterOriginScale.x,
			y = stageFlipY ? -getSourceSizeY() * scale.y + characterOrigin.y * _characterOriginScale.y : -characterOrigin.y * _characterOriginScale.y;

		//return super.getRotatedBounds(newRect).offset(x * _cosAngle - y * _sinAngle, y * _cosAngle + x * _sinAngle);
		return super.getRotatedBounds(newRect).offset(x, y);
	}

	override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect {
		final x = stageFlipX ? -getSourceSizeX() * scale.x + characterOrigin.x * _characterOriginScale.x : -characterOrigin.x * _characterOriginScale.x,
			y = stageFlipY ? -getSourceSizeY() * scale.y + characterOrigin.y * _characterOriginScale.y : -characterOrigin.y * _characterOriginScale.y;

		//super.getScreenBounds(newRect, camera).offset(x * _cosAngle - y * _sinAngle, y * _cosAngle + x * _sinAngle);
		super.getScreenBounds(newRect, camera).offset(x, y);
		return if (isPixelPerfectRender(camera)) newRect.floor() else newRect;
	}

	override function set_flipX(value:Bool) {
		if (FlxG.renderTile) _facingHorizontalMult = (value != stageFlipX ? -1 : 1);
		dirty = (flipX != value) || dirty;
		return flipX = value;
	}

	override function set_flipY(value:Bool) {
		if (FlxG.renderTile) _facingVerticalMult = (value != stageFlipY ? -1 : 1);
		dirty = (flipY != value) || dirty;
		return flipY = value;
	}

	function set_stageFlipX(value:Bool) {
		if (FlxG.renderTile) _facingHorizontalMult = (flipX != value ? -1 : 1);
		dirty = (stageFlipX != value) || dirty;
		return stageFlipX = value;
	}

	function set_stageFlipY(value:Bool) {
		if (FlxG.renderTile) _facingVerticalMult = (flipY != value ? -1 : 1);
		dirty = (stageFlipY != value) || dirty;
		return stageFlipY = value;
	}

	override function checkFlipX() return ((flipX != stageFlipX) != (_frame?.flipX ?? false)) != (animation.curAnim?.flipX ?? false);
	override function checkFlipY() return ((flipY != stageFlipY) != (_frame?.flipY ?? false)) != (animation.curAnim?.flipY ?? false);

	static function getPivotFrame():FlxFrame {
		if (AssetUtil.graphicCached('CharacterPivotGraphic')) return AssetUtil.getGraphic('CharacterPivotGraphic').imageFrame.getByIndex(0);
		else @:privateAccess {
			final bitmap = BitmapDataUtil.create(16, 16), gfx = FlxSpriteUtil.flashGfx;
			FlxSpriteUtil.beginDraw(FlxColor.WHITE); FlxSpriteUtil.setLineStyle({color: FlxColor.WHITE, thickness: 2});
			gfx.moveTo(8, 0); gfx.lineTo(8, 16);
			gfx.moveTo(0, 8); gfx.lineTo(16, 8);
			gfx.endFill(); bitmap.draw(FlxSpriteUtil.flashGfxSprite);
			return AssetUtil.registerGraphic(bitmap, 'CharacterPivotGraphic', true, false).imageFrame.getByIndex(0);
		}
	}

	function set_showPivot(v:Bool) {
		if (v != showPivot && v && _pivotFrame == null) _pivotFrame = getPivotFrame();
		return showPivot = v;
	}

	function set_showCameraPivot(v:Bool) {
		if (v != showCameraPivot && v && _pivotFrame == null) _pivotFrame = getPivotFrame();
		return showCameraPivot = v;
	}

	override function toString():String
		return 'Character(${this.characterID}, ${this.characterName}, ' + FlxStringUtil.getDebugString([
			LabelValuePair.weak("x", x),
			LabelValuePair.weak("y", y),
			LabelValuePair.weak("w", width),
			LabelValuePair.weak("h", height),
			LabelValuePair.weak("visible", visible),
			LabelValuePair.weak("velocity", velocity)
		]) + ')';
}

class CustomCharacter extends Character {
	public var characterData:CharacterData;

	public function new(charID:String, data:CharacterData, ?conductor:Conductor, id:Int = 0, dontCreate = false) {
		characterID = charID;
		characterName = data.name ?? charID;
		characterData = data;
		if (data.icon != null) characterIconData = data.icon;
		super(conductor, id, dontCreate);
	}

	override function resetCharacter() {
		antialiasing = characterData.antialiasing ?? true;
		strokeTime = characterData.strokeTime ?? 0.13;
		holdInterval = characterData.holdInterval ?? 1;

		flipX = characterData.flipX ?? false;
		flipY = characterData.flipY ?? false;

		scale.set(characterData.scale[0] ?? 1, characterData.scale[1] ?? 1);

		characterOrigin.set(characterData.origin[0] ?? 0, characterData.origin[1] ?? 0);
		cameraFocus.set(characterData.cam[0] ?? 0, characterData.cam[1] ?? 0);
		deathCameraFocus.set(characterData.deathCam[0] ?? 0, characterData.deathCam[1] ?? 0);

		if (characterData.camDirection != null) for (i => dir in characterData.camDirection) {
			if (cameraFocusDirection[i] != null)
				cameraFocusDirection[i].set(dir[0] ?? 0, dir[1] ?? 0);
		}

		deathMusicPath = characterData.deathMusic;
		deathEndMusicPath = characterData.deathEndMusic;
		deathSFXPath = characterData.deathSFX;
		pauseMusicPath = characterData.pauseMusic;
	}

	override function create() {
		super.create();

		if (characterData.animations == null) loadBLGraphic(characterData.image);
		else loadAnimGraphic(characterData.image, characterData.animations);

		final w = characterData.width, h = characterData.height;
		if (w != null && h != null && w > 0 && h > 0) sourceSize = new FlxPoint(w, h);
	}
}