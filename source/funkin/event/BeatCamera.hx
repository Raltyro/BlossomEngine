package funkin.event;

class BeatCamera extends PlayEvent {
	public static var classEventID = 'beat-camera';
	public static var classEventName = 'beat Camera';

	public function new() {
		super();
		once = false;
	}

	override function trigger(data:ChartEvent) {
		if (data.params == null) return;

		var interval = 1.0, beatType:BeatType = MEASURE, strength:Null<Float> = null, offset:Null<Float> = null;
		if (data.params[0] is Float) interval = data.params[0];
		if (data.params[1] is Int) beatType = cast data.params[1];
		else if (data.params[1] is String)
			switch (cast(data.params[1], String).charAt(0).toLowerCase()) {
				case 'b': beatType = BEAT;
				case 's': beatType = STEP;
			}
		if (data.params[2] is Float) strength = data.params[2];

		var dataOffset:Dynamic = data.params[3], dataCamera:Dynamic = data.params[4];
		if (dataOffset is Float) offset = dataOffset;
		else if (dataOffset is String || dataCamera == null)
			dataCamera = dataOffset;

		final cameras:Array<PlayCamera> = [];
		if (dataCamera is String)
			switch (cast(dataCamera, String).charAt(0).toLowerCase()) {
				case 'l': cameras.push(playState.camLogic);
				case 'h': cameras.push(playState.camHUD);
				default: cameras.push(playState.camGame);
			}
		else
			for (camera in FlxG.cameras.list) if (camera is PlayCamera) cameras.push(cast camera);

		for (camera in cameras) {
			camera.bopInterval = interval;
			camera.bopEvery = beatType;
			if (strength != null) {
				camera.bopStrength = if (camera == playState.camGame) 0.015 else if (camera == playState.camHUD) 0.03 else 0;
				camera.bopStrength *= strength;
			}
			if (offset != null) camera.bopOffset = offset;
		}
	}
}