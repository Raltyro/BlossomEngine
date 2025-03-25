package bl.play.field;

import openfl.display.BlendMode;
import openfl.geom.Matrix3D;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxDestroyUtil;

import bl.data.Skin;
import bl.util.ShaderUtil;

class Receptor extends NoteObject {
	public var speed:Float = 1.0;
	public var drawOffset:Float = 0.0;
	public var drawSize:Float = 1.0;
	public var drawSizeFront:Float = 1.0;
	public var drawSizeBack:Float = 1.0;

	public var glowSprite:NoteObject;
	public var splashesLimit:Int = 8;
	public var splashes:FlxTypedGroup<NoteObject>;
	public var splashAnimations:Array<String> = [];

	@:allow(bl.play.field.Notefield)
	var _matrix3D:Matrix3D;
	var _splashCounts:Int = 0;

	public function new(x = 0.0, y = 0.0, column:Int, ?skin:Skin) {
		splashes = new FlxTypedGroup<NoteObject>();
		glowSprite = new NoteObject('glow', column);
		super(x, y, 'receptor', column, skin);

		_matrix3D = new Matrix3D();
	}

	public function prepareGlowSprite() @:privateAccess {
		glowSprite.scrollFactor.set(0, 0);
		glowSprite.angle = angle;
		glowSprite._cameras = _cameras;
	}

	public function spawnSplash():NoteObject {
		if (splashAnimations == null || splashAnimations.length == 0) return null;

		var splash:NoteObject = null;
		if (_splashCounts > splashesLimit) splash = splashes.getFirstExisting();
		if (splash == null) {
			_splashCounts++;
			splash = splashes.recycle(NoteObject, () -> {
				final splash = new NoteObject('splash', column);
				splash.animation.onFinish.add((_) -> {
					splash.kill();
					_splashCounts--;
				});
				return splash;
			});
		}
		else {
			splash.animation.stop();
			splash.revive();
		}
		splash.field = field;
		splash.column = column;
		splash.skin = skin;
		splash.playAnim(FlxG.random.getObject(splashAnimations));

		return splash;
	}

	override function reloadSkin() {
		glowSprite.skin = null;
		glowSprite.field = field;
		glowSprite.column = column;
		glowSprite.skin = skin;
		super.reloadSkin();

		final data = skin.getNoteskin(field?.keys)?.get('splash');
		if (data == null) return;
		
		splashAnimations.clearArray();
		for (anim in data.animations) splashAnimations.push(anim.name);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		glowSprite.update(elapsed);
		splashes.update(elapsed);
	}

	override function draw() {
		super.draw();
		if (glowSprite.visible) {
			prepareGlowSprite();
			glowSprite.draw();
		}
		if (splashes.visible) splashes.draw();
	}

	override function destroy() {
		super.destroy();
		splashes = FlxDestroyUtil.destroy(splashes);
		glowSprite = FlxDestroyUtil.destroy(glowSprite);
		_matrix3D = null;
	}

	override function playAnim(name:String, ?fallback:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):BLSprite {
		if (glowSprite.visible = glowSprite.hasAnim(name)) glowSprite.playAnim(name, force, reversed, frame);
		return super.playAnim(name, fallback, force, reversed, frame);
	}
}