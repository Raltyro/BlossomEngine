package bl.object.transition;

import flixel.FlxCamera;

enum abstract TransitionStatus(String) from String to String {
	var OUT = "out";
	var IN = "in";
}

class TransitionData {
	public var transition:Class<Transition>;
	public var duration:Float;
	public var data:Dynamic;

	public function new(transition:Class<Transition>, duration:Float = 1, ?data:Dynamic) {
		this.transition = transition;
		this.duration = duration;
		this.data = data;
	}

	public function createTransition(status:TransitionStatus, finishCallback:()->Void):Transition
		return Reflect.callMethod(null, Reflect.field(transition, 'construct') ?? Transition.construct, [transition, status, finishCallback, duration, data]);
}

class Transition extends flixel.FlxSubState {
	public var status:TransitionStatus;
	public var finishCallback:()->Void;
	public var duration:Float;

	public var parentUpdate:Bool = true;
	public var parentDraw:Bool = true;

	public var finished:Bool = false;
	public var timer:Float = 0;

	public static function construct(transition:Class<Transition>, status:TransitionStatus, finishCallback:()->Void, duration:Float, data:Dynamic):Transition {
		var instance = Type.createInstance(transition, []);
		instance.status = status;
		instance.finishCallback = finishCallback;
		instance.duration = duration;

		for (field in Reflect.fields(data)) Reflect.setProperty(instance, field, Reflect.field(data, field));
		return instance;
	}

	// don't override this ever
	public function new() {
		super();
		active = false;
	}

	// override these
	/*override function create() {
		super.create();
	}*/

	public function start() {
		active = true;
		finished = false;
		timer = 0;
	}

	override function destroy() {
		if (createdCamera) {
			if (FlxG.cameras.list.contains(camera)) FlxG.cameras.remove(camera);
			camera.destroy();
		}
		createdCamera = false;

		super.destroy();
		finishCallback = null;
	}

	public function finish() {
		active = false;
		finished = true;
		timer = duration;

		if (finishCallback != null) finishCallback();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (active && (timer += elapsed) >= duration) finish();
	}

	// helper functions
	var createdCamera:Bool = false;
	public function createCamera(useBlossom = false):FlxCamera {
		(camera = useBlossom ? new BLCamera() : new FlxCamera()).bgColor = 0;
		FlxG.cameras.add(camera, false);

		createdCamera = true;
		return camera;
	}
}