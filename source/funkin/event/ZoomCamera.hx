package funkin.event;

class ZoomCamera extends PlayEvent {
	public static var classEventID = 'zoom-camera';
	public static var classEventName = 'Zoom Camera';

	public function new() {
		super();
		once = false;
	}

	// zoom, ?isDirect, ?duration, ?ease
	// zoom, ?isDirect, ?zoomLerp, ?duration, ?ease
	// zoom, ?isDirect, ?duration/zoomLerp, ?isLinear
	override function trigger(data:ChartEvent) {
		if (data.params == null) return;

		final direct = data.params[1] == true;

		if (data.params[0] is Float) {
			playState.cameraFollowZoomDirect = direct ? data.params[0] : null;
			if (!direct) playState.cameraFollowZoomMultiply = data.params[0];
		}

		var ease:String = null, duration = 1.0;
		if (data.params[2] is Float) {
			duration = data.params[2];

			if (data.params[3] is String) ease = data.params[3];
			else if (data.params[3] == true) ease = 'linear';
			else playState.camGame.zoomLerp = duration;
		}

		if (data.params[3] is Float) {
			duration = data.params[3];
			ease = data.params[4] is String ? data.params[4] : 'linear';
		}

		if (ease == null) return;

		playState.updateCameraFollow();
		playState.camGame.tweenZoom(duration, Reflect.field(FlxEase, ease) ?? FlxEase.linear);
	}
}