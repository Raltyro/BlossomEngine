package blossom.backend;

import haxe.Exception;
import haxe.CallStack;

import sys.FileSystem;
import sys.io.File;

import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.ErrorEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;

import blossom.backend.api.Discord;
import blossom.backend.mod.events.StateEvent;
import blossom.backend.mod.ModuleGroup;
import blossom.input.Controls;

#if FLX_DEBUG
import flixel.system.debug.watch.Tracker.TrackerProfile;
import flixel.system.debug.watch.Tracker;
#end

import flixel.FlxState;

#if (windows && cpp)
@:cppFileCode("#include <windows.h>
#include <psapi.h>")
#end

class BLGame extends flixel.FlxGame {
	var _oldState:FlxState;

	public function new() {
		@:bypassAccessor FlxG.scaleMode = new FullScreenScaleMode();
		FlxG.signals.postGameReset.add(postGameReset);
		FlxG.signals.preStateSwitch.add(preStateSwitch);
		FlxG.signals.postStateSwitch.add(postStateSwitch);
		FlxG.signals.preStateCreate.add(preStateCreate);

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
		#end
	}

	function preStateSwitch() {
		ModuleGroup.global.event(ModuleEvent.get(StateSwitch).recycle());
		ModuleGroup.global.event(ModuleEvent.get(StateDestroy).recycle(_oldState = _state));
	}

	function preStateCreate(_) {
		ModuleGroup.global.eventPost(ModuleEvent.get(StateDestroy).recycle(_oldState));
		ModuleGroup.global.event(ModuleEvent.get(StateCreate).recycle(_state));
	}

	function postStateSwitch() {
		ModuleGroup.global.eventPost(ModuleEvent.get(StateCreate).recycle(_state));
		ModuleGroup.global.eventPost(ModuleEvent.get(StateSwitch).recycle());
	}

	override function create(_) {
		if (stage == null) return;
		setupCrashHandler();
		Discord.start();

		super.create(_);

		//addChildAt(statsCounter = new StatsCounter(3, 3), getChildIndex(_inputContainer) + 1);
	}

	#if !FLX_DEBUG
	@:noCompletion override function __hitTest(_, _, _, _, _, _):Bool return false;
	@:noCompletion override function __hitTestHitArea(_, _, _, _, _, _):Bool return false;
	@:noCompletion override function __hitTestMask(_, _):Bool return false;
	#end

	inline function setupCrashHandler() {
		#if cpp
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
	}

	// https://github.com/gedehari/IzzyEngine/blob/master/source/Main.hx
	// thanks ari (sqirradotdev)!!
	public static function crashHandler(inWhat:String = "unknown", ?exception:Exception) {
		var now:String = StringTools.replace(StringTools.replace(Date.now().toString(), " ", "_"), ":", "'");
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

final class Initial extends flixel.FlxState {
	override function create() {
		BLState.defaultTransIn = GameConstants.DEFAULT_TRANSITION_IN?.copy();
		BLState.defaultTransOut = GameConstants.DEFAULT_TRANSITION_OUT?.copy();
		BLState.skipNextTransIn = BLState.skipNextTransOut = true;

		if (!blossom.backend.util.CommandLineHandler.parse(Sys.args())) @:privateAccess
			FlxG.game._nextState = GameConstants.INITIAL_STATE;
	}
}