package;

import haxe.CallStack;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.errors.Error;
import openfl.events.ErrorEvent;
import openfl.events.KeyboardEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;

import flixel.input.keyboard.FlxKey;
import flixel.text.FlxInputText;
import flixel.FlxGame;
import flixel.FlxG;
import flixel.FlxState;

import bl.api.Discord;
import bl.data.Save;
import bl.graphic.BorderTiles;
import bl.object.debug.StatsCounter;
import bl.input.Controls;
import bl.util.AssetUtil;
import bl.util.CoolUtil;
import bl.Paths;

using StringTools;

#if FLX_DEBUG
import flixel.system.debug.watch.Tracker.TrackerProfile;
import flixel.system.debug.watch.Tracker;
#end

#if linux
import lime.graphics.Image;

@:cppInclude('./gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#elseif (windows && cpp)
//@:headerInclude("windows.h") this doesnt work somehow
//@:headerInclude("psapi.h")
@:cppFileCode('#include <windows.h>
#include <psapi.h>')
#end

class Main extends Sprite {
	public static final DEFAULT_FRAMERATE:Int = 90; // just enough for gameplay
	public static final ENGINE_VERSION:String = "BETA";

	public static var TITLE(get, never):String;
	static function get_TITLE():String return Lib.application.meta.get('name') ?? "Funkin' Blossom";

	public static var VERSION(get, never):String;
	static function get_VERSION():String return 'v${Lib.application.meta.get('version')}';

	public static var focused(default, null):Bool = true;
	public static var allowExit:Bool = true;
	
	public static var borderTiles:BorderTiles;
	public static var statsCounter:StatsCounter;

	public static var current:Main;

	public static var framerate(get, set):Float;
	static function set_framerate(cap:Float):Float {
		if (FlxG.game != null) {
			var _framerate:Int = Std.int(cap);
			if (_framerate > FlxG.drawFramerate) {
				FlxG.updateFramerate = _framerate;
				FlxG.drawFramerate = _framerate;
			}
			else {
				FlxG.drawFramerate = _framerate;
				FlxG.updateFramerate = _framerate;
			}
		}
		return Lib.current.stage.frameRate = cap;
	}
	static function get_framerate():Float return Lib.current.stage.frameRate;

	public static function main():Void {
		//#if (FLX_DEBUG && hl && !hlc)
		//Lib.application.onUpdate.add((_) -> if (hl.Api.checkReload()) trace('reloaded'));
		//#end
		Lib.current.addChild(current = new Main());
	}

	public function new() {
		super();

		if (stage != null) init();
		else addEventListener(Event.ADDED_TO_STAGE, init);
	}

	function init(?E:Event):Void {
		if (hasEventListener(Event.ADDED_TO_STAGE)) removeEventListener(Event.ADDED_TO_STAGE, init);
		setupGame();
	}

	// restart the entire game including the executable itself
	/*public static function restart() {
		#if sys
		#if (windows && target.threaded)
		if (Main.args.contains("-livereload")) {
			sys.thread.Thread.create(Sys.command.bind(Sys.programPath(), ["RESTARTED","-livereload"]));
			Sys.sleep(1);
			Sys.exit(0);
		}
		else
		#end
			new Process(Sys.programPath(), ["RESTARTED"]);

		Sys.exit(0);
		#else
		throw "Cannot hard reset in platforms that don't support sys";
		#end
	}*/

	function setupGame() {
		#if cpp // Thank you EliteMasterEric, very cool!
		//#if windows untyped __cpp__('SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX)'); #end
		untyped __global__.__hxcpp_set_critical_error_handler(crashHandler);
		#end
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, (event) -> {
			if (Std.isOfType(event.error, Error)) {
				var err = cast(event.error, Error);
				crashHandler(err.getStackTrace() ?? err.message);
			} else if (Std.isOfType(event.error, ErrorEvent))
				crashHandler(cast(event.error, ErrorEvent).text);
			else
				crashHandler(Std.string(event.error));
		});

		#if linux Lib.current.stage.window.setIcon(Image.fromFile("icon.png")); #end
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		Lib.application.window.onClose.add(onClose);

		FlxG.signals.focusGained.add(onFocus);
		FlxG.signals.focusLost.add(onFocusLost);
		FlxG.signals.postGameReset.add(onGameReset);

		addChild(borderTiles = new BorderTiles(AssetUtil.getBitmap(Paths.image('border'))));

		framerate = DEFAULT_FRAMERATE;
		setupDebug();
		addChild(new FlxGame(1280, 720, bl.InitState, DEFAULT_FRAMERATE, DEFAULT_FRAMERATE, true, false));

		Discord.start();
	}

	#if FLX_DEBUG
	inline function setupDebug() {
		FlxG.debugger.addTrackerProfile(new TrackerProfile(bl.Conductor, [
			"songPosition", "offset", "bpm", "numerator", "denominator", "tuplet",
			"currentMeasureTime", "currentBeatTime", "currentStepTime", "currentTimeChangeIdx"],
			[]
		));
		FlxG.debugger.addTrackerProfile(new TrackerProfile(bl.math.Vector3.BaseVector3, ["x", "y", "z"]));
	}

	override function __enterFrame(tick) {
		super.__enterFrame(tick);
		if (FlxG.game.debugger != null) {
			FlxG.game.debugger.x = 0;
			FlxG.game.debugger.y = 0;
		}
	}
	#else
	inline function setupDebug() {}
	#end

	static function onFocus() {
		focused = true;
	}

	static function onFocusLost() {
		focused = false;
		//Paths.compress();
	}

	static function onGameReset() {
		AssetUtil.clearCache();
		flixel.graphics.FlxGraphic.defaultPersist = true; // Let AssetUtil handle the cache
		flixel.FlxObject.defaultMoves = false;

		FlxG.fixedTimestep = false;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.sound.volumeUpKeys = [];
		FlxG.sound.volumeDownKeys = [];
		FlxG.sound.muteKeys = [];

		Controls.instance = new Controls();

		if (statsCounter != null) {
			current.removeChild(statsCounter);
			@:privateAccess statsCounter.__cleanup();
		}
		current.addChild(statsCounter = new StatsCounter(3, 3));

		// maybe dont do this? base_game assets doesnt work
		if (Sys.args().contains('-livereload')) {
			bl.mod.PolymodHandler.useSourceAssets = true;
			bl.mod.PolymodHandler.loadMods();
		}

		#if FLX_DEBUG
		if (FlxG.game.debugger != null) {
			FlxG.game.removeChild(FlxG.game.debugger);
			current.addChild(FlxG.game.debugger);

			FlxG.game.debugger.console.registerObject('Main', Main);
			FlxG.game.debugger.console.registerObject('Paths', Paths);
			FlxG.game.debugger.console.registerObject('Discord', bl.api.Discord);
			FlxG.game.debugger.console.registerObject('Save', bl.data.Save);
			FlxG.game.debugger.console.registerObject('AtlasText', bl.object.AtlasText);
			FlxG.game.debugger.console.registerObject('Vector3', bl.math.Vector3.BaseVector3);
			FlxG.game.debugger.console.registerObject('BLState', bl.state.base.BLState);
			FlxG.game.debugger.console.registerObject('Character', bl.play.component.Character);
			FlxG.game.debugger.console.registerObject('Stage', bl.play.component.Stage);
			FlxG.game.debugger.console.registerObject('PlayState', bl.play.PlayState);
			FlxG.game.debugger.console.registerObject('AssetUtil', AssetUtil);
			FlxG.game.debugger.console.registerObject('BitmapDataUtil', bl.util.BitmapDataUtil);
			FlxG.game.debugger.console.registerObject('CoolUtil', bl.util.CoolUtil);
			FlxG.game.debugger.console.registerObject('ShaderUtil', bl.util.ShaderUtil);
			FlxG.game.debugger.console.registerObject('SoundUtil', bl.util.SoundUtil);
			FlxG.game.debugger.console.registerObject('Conductor', bl.Conductor);
			FlxG.game.debugger.console.registerObject('gl', openfl.display.OpenGLRenderer);
		}
		#end

		Save.load();
	}

	private function onClose() {
		if (!allowExit) Lib.application.window.onClose.cancel();
	}
	
	private function onKeyDown(evt:KeyboardEvent) @:privateAccess {
		if (!FlxInputText.globalManager.isTyping && focused #if FLX_DEBUG && !FlxG.game.debugger.interaction.isActive() #end) {
			if (Controls.instance.controls.get(FULLSCREEN).keys.contains(evt.keyCode)) FlxG.fullscreen = !FlxG.fullscreen;
			else if (Controls.instance.controls.get(VOLUME_MUTE).keys.contains(evt.keyCode)) FlxG.sound.toggleMuted();
			else if (Controls.instance.controls.get(VOLUME_UP).keys.contains(evt.keyCode)) FlxG.sound.changeVolume(0.1);
			else if (Controls.instance.controls.get(VOLUME_DOWN).keys.contains(evt.keyCode)) FlxG.sound.changeVolume(-0.1);
		}
	}

	// https://github.com/gedehari/IzzyEngine/blob/master/source/Main.hx
	// thanks ari (sqirradotdev)!!
	public static function crashHandler(inWhat:String = "unknown", ?exception:haxe.Exception) {
		trace("Blossom Engine Crashed");
		var now:String = (Date.now().toString()).replace(" ", "_").replace(":", "'");
		var path:String = './crash/BlossomCrashLog_${now}.txt';

		var msg:String = '';
		if (exception == null) {
			for (stackItem in CallStack.exceptionStack(true)) {
				switch(stackItem) {
					case FilePos(s, file, line, column):
						msg += '$file:$line\n';
					default:
						Sys.println(stackItem);
				}
			}
			msg = msg.substr(0, msg.length - 1);
		}
		else
			msg = '${exception.message}\n${CallStack.toString(exception.stack)}';

		var errMsg:String = '$inWhat\n\n$msg';
		#if sys
		if (!FileSystem.exists("./crash/")) FileSystem.createDirectory("./crash/");
		File.saveContent(path, errMsg);
		#end

		Sys.println(errMsg);
		#if (windows && cpp) windows_showErrorMsgBox #else Lib.application.window.alert #end (msg, inWhat);
		Sys.exit(1);
	}

	#if (windows && cpp)
	@:functionCode('MessageBox(NULL, message, title, MB_ICONERROR | MB_OK);')
	static function windows_showErrorMsgBox(message:String, title:String){}
	#end
}