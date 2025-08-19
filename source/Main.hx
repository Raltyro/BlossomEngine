import haxe.Exception;
import haxe.CallStack;

import sys.FileSystem;
import sys.io.File;

import openfl.display.Sprite;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.ErrorEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;

import blossom.backend.api.Discord;

#if linux
@:cppInclude("./gamemode_client.h")
@:cppFileCode("#define GAMEMODE_AUTO")
#elseif (windows && cpp)
@:cppFileCode("#include <windows.h>
#include <psapi.h>")
#end

class Main extends Sprite {
	public static function main() {
		Lib.current.addChild(new Main());
	}

	public function new() {
		super();
		if (stage != null) init();
		else addEventListener(Event.ADDED_TO_STAGE, init);
	}

	function init(?_:Event):Void {
		if (hasEventListener(Event.ADDED_TO_STAGE)) removeEventListener(Event.ADDED_TO_STAGE, init);
		setupGame();
	}

	function setupGame() {
		setupCrashHandler();

		addChild(new blossom.backend.BLGame());

		Discord.start();
	}

	function setupCrashHandler() {
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
		trace("Blossom Engine Crashed");
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