package ralty;

class TestState extends BLState {
	override function createPost() {
		super.createPost();
		trace('cool');

		SoundUtil.playMusic(Paths.inst('lit up bf'));
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.justPressed.ACCEPT) {
			trace('accepted');
			FlxG.sound.play(Paths.sound('locked'));
		}
	}
}