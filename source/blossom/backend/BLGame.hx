package blossom.backend;

import blossom.input.Controls;

class BLGame extends flixel.FlxGame {
	public function new() {
		FlxG.signals.postGameReset.add(postGameReset);
		super(GameConstants.WIDTH, GameConstants.HEIGHT, Initial, GameConstants.FRAMERATE, GameConstants.FRAMERATE, true);
	}

	function postGameReset() {
		flixel.graphics.FlxGraphic.defaultPersist = true; // Let AssetUtil handle the rest.
		flixel.FlxObject.defaultMoves = false;
		flixel.FlxSprite.defaultAntialiasing = true;

		FlxG.fixedTimestep = false;
		FlxG.sound.volumeUpKeys = [];
		FlxG.sound.volumeDownKeys = [];
		FlxG.sound.muteKeys = [];

		Controls.instance = new Controls();
	}
}

final class Initial extends flixel.FlxState {
	override function create() {
		FlxG.switchState(GameConstants.INITIAL_STATE);
	}
}