package bl.play;

import bl.data.Song.ChartEvent;

@:autoBuild(bl.util.macro.BuildMacro.buildScripts())
@:build(bl.util.macro.BuildMacro.buildPlayScript())
class PlayScript extends Module {
	// DO NOT DEFINE ANYTHING TO THIS, Taken care of BuildMacro
	@:noCompletion public static var scriptClasses:Map<String, Class<PlayScript>>;
	@:noCompletion public static var songScriptClasses:Map<String, Class<PlayScript>>;

	private inline static function _scriptExists(classes:Map<String, Class<PlayScript>>, id:String):Bool {
		if (classes == null) return false;
		if (classes.exists(id)) return true;

		return false;
	}

	private inline static function _preloadScript(classes:Map<String, Class<PlayScript>>, id:String):Future<Bool> {
		if (classes.exists(id)) {
			var f:() -> Future<Dynamic> = Reflect.field(classes.get(id), 'preload');
			if (f == null) return Future.withValue(false);
			else {
				var promise = new Promise<Bool>();
				f().onComplete((_) -> promise.complete(true));
				return promise.future;
			}
		}

		return Future.withValue(false);
	}

	private inline static function _make(classes:Map<String, Class<PlayScript>>, ?id:String, playState:PlayState):Null<PlayScript> {
		if (classes.exists(id)) return Type.createInstance(classes.get(id), [playState]);
		
		return null;
	}

	public static function scriptExists(id:String):Bool return _scriptExists(scriptClasses, id);
	public static function preloadScript(id:String):Future<Bool> return _preloadScript(scriptClasses, id);
	public static function make(?id:String, playState:PlayState):Null<PlayScript> return _make(scriptClasses, id, playState);

	public static function songScriptExists(id:String):Bool return _scriptExists(songScriptClasses, id);
	public static function preloadSongScript(id:String):Future<Bool> return _preloadScript(songScriptClasses, id);
	public static function makeSongScript(?id:String, playState:PlayState):Null<PlayScript> return _make(songScriptClasses, id, playState);

	public var scriptID:String = 'fallback';

	public var playState:Null<PlayState>;

	// todo, make a macro to automatically set playstate variables to this as inlined

	public var conductor(get, set):Null<Conductor>;
	inline function get_conductor() return playState?.conductor; inline function set_conductor(v) return playState.conductor = v;

	public var events(get, set):Null<PlayEventHandler>;
	inline function get_events() return playState?.events; inline function set_events(v) return playState.events = v;

	public var timePosition(get, set):Float;
	inline function get_timePosition() return playState?.timePosition ?? 0; inline function set_timePosition(v:Float) return playState.timePosition = v;

	function _init() {} // BuildMacro
	public function new(playState:PlayState, priority:Int = 0) {
		this.playState = playState;

		_init();
		super(priority);
	}

	inline private function addEvent(time:Float, event:ChartEvent):ChartEvent {
		event.time = time;
		return events.add(event);
	}

	private function addEvents(time = 0.0, arr:Array<ChartEvent>):Array<ChartEvent> {
		for (event in arr) {
			event.time = event.time ?? time;
			events.add(event);
		}
		return arr;
	}

	inline private function getTimeInBeats(time:Float):Float return conductor.getTimeInBeats(time);
	inline private function getTimeInMeasures(time:Float):Float return conductor.getTimeInMeasures(time);
	inline private function getTimeInSteps(time:Float):Float return conductor.getTimeInSteps(time);
	inline private function getBeatsInTime(beatTime:Float):Float return conductor.getBeatsInTime(beatTime);
	inline private function getMeasuresInTime(measureTime:Float):Float return conductor.getMeasuresInTime(measureTime);
	inline private function getStepsInTime(stepTime:Float):Float return conductor.getStepsInTime(stepTime);
}