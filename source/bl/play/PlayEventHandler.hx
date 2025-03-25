package bl.play;

import bl.data.Song.ChartEvent;
import bl.play.event.EventPlayEvent;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxSort;

typedef PlayEventTask = {
	triggered:Bool,
	data:ChartEvent
}

class PlayEventHandler implements IFlxDestroyable {
	public var playState:PlayState;

	public var timePosition:Float = 0;
	public var eventIndex:Int = 0;

	public var length(default, null):Int = 0;

	public var created:Bool = false;
	public var events:Array<PlayEventTask> = [];
	public var handlers:Map<String, PlayEvent> = [];

	public function new(?playState:PlayState) {
		this.playState = playState;
	}

	public function initHandler(event:String) {
		if (!handlers.exists(event)) {
			final handler = PlayEvent.make(event, playState);
			if (handler != null) {
				handlers.set(event, handler);
				if (created) handler.create();
			}
		}
	}

	public function refresh() {
		events.sort((a, b) -> {
			initHandler(a.data.event);
			return FlxSort.byValues(FlxSort.ASCENDING, a.data.time, b.data.time);
		});
		length = events.length;
	}

	public function reset() {
		for (event in events) event.triggered = false;
		refresh();
		eventIndex = 0;
	}

	public function clear() {
		length = 0;
		events.clearArray();
	}

	public function add(data:ChartEvent):ChartEvent {
		if (data == null) return data;
		if (data.time == null) throw 'ChartEvent must have time before adding it to PlayEventHandler';

		events.push({triggered: false, data: data});
		initHandler(data.event);

		length++;
		return data;
	}

	public function remove(data:ChartEvent):ChartEvent {
		for (idx in (length = events.length)...0) if (events[idx].data == data) {
			events.splice(idx, 1);
			length--;
		}
		return data;
	}

	public function removeAtIndex(idx:Int):Null<ChartEvent> {
		if (idx < 0 || idx >= length) return null;

		final event = events.splice(idx, 1)[0];
		length--;
		return event?.data;
	}

	public function create() {
		created = true;
		for (handler in handlers) if (!handler.created) handler.create();
	}

	public function update(timePosition:Float, elapsed:Float) {
		this.timePosition = timePosition;

		var event:PlayEventTask;
		while ((event = events[eventIndex - 1]) != null && timePosition < event.data.time) eventIndex--;
		while ((event = events[eventIndex]) != null && timePosition >= event.data.time) {
			final handler = handlers.get(event.data.event);
			if (handler != null) {
				if (!event.triggered || !handler.once) handler.trigger(event.data);
				handler.triggerAdvanced(event.data, eventIndex, event.triggered);
			}

			playState?.modules.event(ModuleEvent.get(EventPlayEvent).recycle(event.data, eventIndex, event.triggered));

			event.triggered = true;
			eventIndex++;
		}

		for (handler in handlers) handler.update(elapsed);
	}

	public function destroy() {
		created = false;

		if (handlers != null) {
			for (handler in handlers) handler.destroy();
			handlers = null;
		}
		if (events != null) {
			FlxArrayUtil.clearArray(events);
			events = null;
		}
	}

	public function toString():String
		return 'PlayEventHandler(${events.toString()}, ${handlers.toString()})';
}