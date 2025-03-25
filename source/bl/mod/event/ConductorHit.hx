package bl.mod.event;

final class MetronomeHit extends ModuleEvent {
	public static var classCallbackName:String = 'onMetronomeHit';
	public var measureTicked:Bool;
	public var measure:Int;
	public var beat:Int;
}

final class MeasureHit extends ModuleEvent {
	public static var classCallbackName:String = 'onMeasureHit';
	public var measure:Int;
}

final class BeatHit extends ModuleEvent {
	public static var classCallbackName:String = 'onBeatHit';
	public var beat:Int;
}

final class StepHit extends ModuleEvent {
	public static var classCallbackName:String = 'onStepHit';
	public var step:Int;
}