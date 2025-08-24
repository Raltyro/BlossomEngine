package blossom.backend;

import blossom.backend.debug.StatsCounter;
import blossom.input.Controls;

#if FLX_DEBUG
import flixel.system.debug.watch.Tracker.TrackerProfile;
import flixel.system.debug.watch.Tracker;
#end

class BLGame extends flixel.FlxGame {
	var statsCounter:StatsCounter;

	public function new() {
		@:bypassAccessor FlxG.scaleMode = new FullScreenScaleMode();
		FlxG.signals.postGameReset.add(postGameReset);
		//borderTiles = new BorderTiles(AssetUtil.getBitmap(Paths.image("border"), true, false));

		super(GameConstants.WIDTH, GameConstants.HEIGHT, Initial, GameConstants.FRAMERATE, GameConstants.FRAMERATE, true);

		#if FLX_DEBUG
		FlxG.debugger.addTrackerProfile(new TrackerProfile(Conductor, [
			"songPosition", "offset", "bpm", "numerator", "denominator", "tuplet",
			"currentMeasureTime", "currentBeatTime", "currentStepTime", "currentTimeChangeIdx"],
			[]
		));
		FlxG.debugger.addTrackerProfile(new TrackerProfile(blossom.math.Vector3.BaseVector3, ["x", "y", "z"]));
		#end
	}

	function postGameReset() {
		flixel.graphics.FlxGraphic.defaultPersist = true; // Let AssetUtil handle the rest.
		flixel.FlxObject.defaultMoves = false;
		flixel.FlxSprite.defaultAntialiasing = true;

		FlxG.fixedTimestep = false;
		//FlxG.sound.volumeUpKeys = [];
		//FlxG.sound.volumeDownKeys = [];
		//FlxG.sound.muteKeys = [];
		FlxG.mouse.useSystemCursor = true;

		Controls.instance = new Controls();

		#if FLX_DEBUG
		FlxG.game.debugger.console.registerObject('Discord', blossom.backend.api.Discord);
		FlxG.game.debugger.console.registerObject('Paths', blossom.backend.Paths);
		//FlxG.game.debugger.console.registerObject('Save', bl.data.Save);
		//FlxG.game.debugger.console.registerObject('AtlasText', bl.object.AtlasText);
		FlxG.game.debugger.console.registerObject('Vector3', blossom.math.Vector3.BaseVector3);
		FlxG.game.debugger.console.registerObject('BLState', blossom.BLState);
		//FlxG.game.debugger.console.registerObject('Character', bl.play.component.Character);
		//FlxG.game.debugger.console.registerObject('Stage', bl.play.component.Stage);
		//FlxG.game.debugger.console.registerObject('PlayState', bl.play.PlayState);
		FlxG.game.debugger.console.registerObject('AssetUtil', AssetUtil);
		FlxG.game.debugger.console.registerObject('BitmapDataUtil', blossom.backend.util.BitmapDataUtil);
		//FlxG.game.debugger.console.registerObject('CoolUtil', bl.util.CoolUtil);
		FlxG.game.debugger.console.registerObject('ShaderUtil', blossom.backend.util.ShaderUtil);
		FlxG.game.debugger.console.registerObject('SoundUtil', blossom.backend.util.SoundUtil);
		FlxG.game.debugger.console.registerObject('Conductor', blossom.backend.Conductor);
		FlxG.game.debugger.console.registerObject('gl', openfl.display.OpenGLRenderer);
		#end
	}

	override function create(_) {
		if (stage == null) return;
		super.create(_);
		addChild(statsCounter = new StatsCounter(3, 3));
	}
}

final class Initial extends flixel.FlxState {
	override function create() {
		if (!blossom.backend.util.CommandLineHandler.parse(Sys.args()))
			FlxG.switchState(GameConstants.INITIAL_STATE);
	}
}