package funkin.event;

class FocusCamera extends PlayEvent {
	public static var classEventID = 'focus-camera';
	public static var classEventName = 'Focus Camera';

	public function new() {
		super();
		once = false;
	}

	// characaterID, ?camX, ?camY, ?duration ?ease
	// characaterID, ?camX, ?camY, ?followLerp, ?duration, ?ease
	// characaterID, ?camX, ?camY, ?duration/followLerp, ?isLinear
	override function trigger(data:ChartEvent) {
		if (data.params == null) return;

		var char:Character = null;
		if (data.params[0] is Int) {
			final id:Int = data.params[0];
			for (character in playState.characters) {
				if (character.ID == id) {
					char = character;
					break;
				}
			}
		}
		else if (data.params[0] is String)
			switch (cast(data.params[0], String).charAt(0).toLowerCase()) {
				case 'b': char = playState.bf;
				case 'g': char = playState.gf;
				case 'd': char = playState.dad;
				case 'c': playState.cameraFollowPoint.copyFrom(playState.stage.centerPosition);
			}

		if (!(data.params[0] is Bool) || data.params[0] != true) playState.cameraFollowCharacter = char;
		playState.cameraFollowPosition.set(
			data.params[1] is Float ? data.params[1] : playState.cameraFollowPosition.x,
			data.params[2] is Float ? data.params[2] : playState.cameraFollowPosition.y
		);

		var ease:String = null, duration = 1.0;
		if (data.params[3] is Float) {
			duration = data.params[3];

			if (data.params[4] is String) ease = data.params[4];
			else if (data.params[4] == true) ease = 'linear';
			else playState.camGame.followLerp = duration;
		}

		if (data.params[4] is Float) {
			duration = data.params[4];
			ease = data.params[5] is String ? data.params[5] : 'linear';
		}

		if (ease == null) return;

		playState.updateCameraFollow();
		playState.camGame.tweenScroll(duration, Reflect.field(FlxEase, ease) ?? FlxEase.linear);
	}
}