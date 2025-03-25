package bl.play.event;

final class ExitPlay extends ModuleEvent {
	public static var classCallbackName:String = 'onExitPlay';
	public var inStoryMode:Bool;
	public var inSubstate:Bool;
}