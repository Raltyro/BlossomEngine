package bl.play;

import bl.data.Song.ChartEvent;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

@:autoBuild(bl.util.macro.BuildMacro.buildPlayEvents())
class PlayEvent implements IFlxDestroyable {
	@:noCompletion public static var eventClasses:Map<String, Class<PlayEvent>>; // DO NOT DEFINE ANYTHING TO THIS, Taken care of BuildMacro

	public static function eventExists(eventID:String):Bool {
		if (eventClasses.exists(eventID)) return true;

		return false;
	}

	public static function preloadEvent(eventID:String, data:ChartEvent):Future<Bool> {
		if (eventClasses.exists(eventID)) {
			var f:ChartEvent->Future<Dynamic> = Reflect.field(eventClasses.get(eventID), 'preload');
			if (f == null) return Future.withValue(false);
			else {
				var promise = new Promise<Bool>();
				f(data).onComplete((_) -> promise.complete(true));
				return promise.future;
			}
		}

		return Future.withValue(false);
	}

	public static function make(eventID:String, ?playState:PlayState):Null<PlayEvent> {
		if (eventClasses.exists(eventID)) {
			final instance = Type.createInstance(eventClasses.get(eventID), []);
			instance.playState = playState;
			return instance;
		}

		return null;
	}

	public var eventID:String = 'fallback';
	public var eventName:String = 'Fallback';
	public var eventIcon:Null<String>;

	public var once:Bool = true;

	public var playState:PlayState;
	public var created:Bool = false;

	function _init() {} // BuildMacro
	public function new() _init();

	public function create() {
		created = true;
	}

	public function destroy() {
		created = false;
	}

	public function update(elapsed:Float) {}

	public function trigger(data:ChartEvent) {}
	public function triggerAdvanced(data:ChartEvent, index:Int, wasTriggered:Bool) {}

	public function toString():String
		return 'PlayEvent(${this.eventID}, ${this.eventName})';
}