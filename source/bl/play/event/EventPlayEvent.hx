package bl.play.event;

import bl.data.Song.ChartEvent;

final class EventPlayEvent extends ModuleEvent {
	public static var classCallbackName:String = 'onEvent';
	public var event:ChartEvent;
	public var index:Int;
	public var wasTriggered:Bool;
}