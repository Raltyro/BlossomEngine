package bl.util;

import lime.app.Application;

typedef Int8 = #if cpp cpp.Int8 #elseif hl hl.UI8 #else Int #end;
typedef UInt8 = #if cpp cpp.UInt8 #else Int #end;
#if cpp typedef UInt = cpp.UInt32; #end

class CoolUtil {
	// Only use this for camera followLerp, it's only for to mimicks other fnf engine like psych engine etc.
	public #if (!hscript) inline #end static function funkinLerp(v:Float):Float return 1 - Math.exp(-.01666 * v);

	public static function changeWindowTitle(?desc:String, ?title:String)
		Application.current.window.title = (title ?? Main.TITLE) + (desc ?? "");

	// for editors...
	#if FLX_DEBUG
	static var debugger:flixel.system.debug.FlxDebugger;
	public static function suppressWarning() @:privateAccess {
		debugger = FlxG.game.debugger;
		Reflect.setField(FlxG.game, 'debugger', null);
	}

	public static function reviveWarning() @:privateAccess {
		Reflect.setField(FlxG.game, 'debugger', debugger);
		debugger = null;
	}
	#else
	public static function suppressWarning() {}
	public static function reviveWarning() {}
	#end

	public static var intervalSizes:Array<String> = ["B", "KB", "MB", "GB"];
	public static function getSizeString(size:Float, from:Int = 0, precision:Int = 2):String {
		while (size >= 1024 && from < 3) {size /= 1024; from++;}
		return '${FlxMath.roundDecimal(size, precision)} ${intervalSizes[from]}';
	}

	public static function afterUpdate(f:()->Void, frames:UInt = 1) {
		var wrap; wrap = (_) -> if (--frames <= 0) {
			Application.current.onUpdate.remove(wrap);
			f();
		}
		Application.current.onUpdate.add(wrap);
	}

	public static function chainFutures(futures:Array<Future<Dynamic>>):Future<Bool> {
		if (futures.length == 0) return Future.withValue(false);
		var promise = new Promise<Bool>(), i:UInt = 0;
		var f = (_) -> if (++i >= futures.length) promise.complete(true);
		for (future in futures) future.onError(f).onComplete(f);
		return promise.future;
	}

	public static function futureWaitTime<T>(future:Future<T>, waitTime:Float = 8):Future<T> {
		if (future.isComplete) return future;

		var due = haxe.Timer.stamp() + waitTime, waitListener;
		waitListener = (_) -> if (haxe.Timer.stamp() > due) @:privateAccess {
			Application.current.onUpdate.remove(waitListener);
			future.isComplete = true;
			future.value = null;

			if (future.__completeListeners != null) {
				for (listener in future.__completeListeners) listener(null);
				future.__completeListeners = null;
			}
		}
		Application.current.onUpdate.add(waitListener);

		var wrapListener = future.onComplete((v) -> Application.current.onUpdate.remove(waitListener));
		return future;
	}
}