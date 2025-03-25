package funkin.event;

import bl.graphic.SpriteFrameBuffer;

class SmearCamera extends PlayEvent {
	public static var classEventID = 'smear-camera';
	public static var classEventName = 'Smear Camera';

	public function new() {
		super();
		once = false;
	}

	var aft:SpriteFrameBuffer;

	override function create() {
		super.create();

		aft.camera = playState.camGame;
	}

	override function trigger(data:ChartEvent) {
		if (data.params == null) return;
	}
}

class SmearCameraModule extends Module {

}