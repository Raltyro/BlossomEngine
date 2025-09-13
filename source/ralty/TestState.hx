package ralty;

class TestState extends BLState {
	var voices:FlxSound;
	var sprite:BLSprite;

	override function create() {
		super.create();

		//SoundUtil.playMusic(Paths.music('suspended'));
		FlxG.sound.playMusic(AssetUtil.getMusic(Paths.inst('the uprising')));
		voices = FlxG.sound.play(AssetUtil.getMusic(Paths.voices('the uprising')), 1.0, true, false);

		FlxG.sound.music.onComplete = () -> voices.play(true, 0);

		var path = Paths.atlas("characters/GF_assets", "shared");
		trace(path);
		add(sprite = BLSprite.create(path));

		sprite.anim.addBySymbol("idle", "GF Dancing Left", 24);

		/*var path = Paths.atlas("characters/BOYFRIEND", "shared");
		trace(path);
		add(sprite = new FlxSprite());
		sprite.frames = FlxAtlasFrames.fromSparrow(Paths.fix(path, Paths.EXT_IMAGE), Paths.fix(path, "xml"));

		sprite.animation.addByPrefix("idle", "BF idle dance", 24);*/

		sprite.animation.play("idle");

		sprite.updateHitbox();
		sprite.screenCenter();
		//sprite.blend = openfl.display.BlendMode.BURN;
		/*sprite.shader = new blossom.graphic.shaders.BlossomShader("
#pragma header
uniform float time;

void main(void) {
	vec2 uv = frameCoordv - 0.5;
	uv.x *= sin(uv.y * 3.0 + time) * 0.2;
	gl_FragColor = flixel_texture2D(bitmap, frameCoordToUV(uv + 0.5));
	if (gl_FragColor.a == 0.0) discard;
}
");*/
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		//sprite.shader.data.time.value = [FlxG.game.ticks / 1000];

		if (controls.justPressed.BACK) {

		}

		if (controls.justPressed.ACCEPT) {
			trace(FlxG.sound.music.time);
			AssetUtil.gc();
			FlxG.autoPause = !FlxG.autoPause;
			FlxG.sound.play(Paths.sound('locked'));
		}

		if (FlxG.keys.justPressed.ONE) {
			var cam:BLCamera = cast camera;
			if (!cam.freezed) cam.freeze();
			else cam.unfreeze();
			trace(cam.freezed);
		}
		if (FlxG.keys.justPressed.TWO) {
			var cam:BLCamera = cast camera;
			cam.useBuffer = !cam.useBuffer;
			trace('uses buffer', cam.useBuffer);
		}
	}
}