package funkin.event;

class FunctionEvent extends PlayEvent {
	public static var classEventID = 'function';
	public static var classEventName = 'Function Event';

	public function new() {
		super();
		once = false;
	}

	override function triggerAdvanced(data:ChartEvent, index:Int, wasTriggered:Bool) {
		if (data.params == null || (wasTriggered && !(data.params[1] is Bool) || data.params[1])) return;
		Reflect.callMethod(null, data.params[0], [playState]);
	}
}