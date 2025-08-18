package blossom.backend;

import blossom.backend.debug.StatsCounter;
import blossom.input.Controls;

class Game extends flixel.FlxGame {
	var borderTiles:BorderTiles;
	var statsCounter:StatsCounter;

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
		FlxG.mouse.useSystemCursor = true;

		Controls.instance = new Controls();
	}

	override function create(_) {
		if (stage == null) return;
		addChild(borderTiles = new BorderTiles(AssetUtil.getBitmap(Paths.image("border"))));

		super.create(_);

		addChild(statsCounter = new StatsCounter(3, 3));
	}

	override function resizeGame(width:Int, height:Int) {
		super.resizeGame(width, height);
		borderTiles.onResize();
	}
}

final class Initial extends flixel.FlxState {
	override function create() {
		FlxG.switchState(GameConstants.INITIAL_STATE);
	}
}