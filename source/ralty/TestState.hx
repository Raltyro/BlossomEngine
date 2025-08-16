package ralty;

class TestState extends BLState {
	override function createPost() {
		super.createPost();
		trace('cool');

		SoundUtil.playMenuMusic();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.justPressed.ACCEPT) {
			trace('accepted');
			FlxG.sound.play(Paths.sound('locked'));
		}
	}
}