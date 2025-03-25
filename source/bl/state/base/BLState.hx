package bl.state.base;

import flixel.util.typeLimit.NextState;

import bl.mod.event.ConductorHit;
import bl.mod.event.State;
import bl.object.transition.Transition;
import bl.input.Controls;

// It's FlxSubstate instead so it can be a substate and a normal state
// and theres no need for it having a seperate class for substate too

class BLState extends flixel.FlxSubState {
	// global default transitions for ALL states, used if transIn/transOut are null
	public static var defaultTransIn:TransitionData = null;
	public static var defaultTransOut:TransitionData = null;

	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;

	// beginning & ending transitions for THIS state:
	public var transIn:TransitionData;
	public var transOut:TransitionData;
	public var curTrans:Transition;

	var _modules:ModuleGroup;
	public var modules(get, set):ModuleGroup;
	function get_modules() {
		if (_modules == null) return parent != null ? parent.modules : (_modules = new ModuleGroup());
		return _modules;
	}
	inline function set_modules(newModules) return _modules = newModules;

	public var isSubstate(get, null):Null<Bool> = null; function get_isSubstate() return isSubstate ?? (_parentState != null);
	public var parent(get, null):Null<BLState>;
	function get_parent() {
		if (parent == null && _parentState is BLState) parent = cast _parentState;
		return parent;
	}

	public var updateConductor:Bool = true;
	public var conductor(default, set):Null<Conductor>;
	function set_conductor(newConductor) {
		if (conductor != null) {
			conductor.onMeasureHit.remove(_measureHit);
			conductor.onBeatHit.remove(_beatHit);
			conductor.onStepHit.remove(_stepHit);
			conductor.onMetronomeHit.remove(_metronomeHit);
		}
		if (newConductor != null) {
			newConductor.onMeasureHit.add(_measureHit);
			newConductor.onBeatHit.add(_beatHit);
			newConductor.onStepHit.add(_stepHit);
			newConductor.onMetronomeHit.add(_metronomeHit);

			#if FLX_DEBUG
			FlxG.debugger.track(newConductor);
			#end
		}
		return conductor = newConductor;
	}

	public var controls(get, set):Controls;

	var _controls:Controls;
	inline function get_controls() return _controls ?? Controls.instance;
	inline function set_controls(controls) return _controls = controls;

	public function new() super();

	override function create() {
		super.create();
		if (!(isSubstate = get_isSubstate())) {
			if (bgColor == 0) bgColor = FlxColor.BLACK;
			if (!(FlxG.camera is BLCamera) && FlxG.cameras.list.length == 1) FlxG.cameras.reset(new BLCamera());
		}
		if (conductor == null && !isSubstate) conductor = Conductor.instance;
		else updateConductor = false;

		_created = true;
		controls.reset();

		if (!isSubstate || transIn != null) {
			final trans = transIn ?? defaultTransIn;
			if (trans != null && !skipNextTransIn) openTransition(trans, IN);
			skipNextTransIn = false;
		}

		AssetUtil.gc();
	}

	override function startOutro(onOutroComplete:()->Void) {
		final trans = transOut ?? defaultTransOut;
		if (trans != null && !skipNextTransOut) {
			if (curTrans != null && curTrans.status == OUT) curTrans.finishCallback = onOutroComplete;
			else openTransition(trans, OUT, onOutroComplete);
		}
		else onOutroComplete();
		skipNextTransOut = false;
	}

	private function openTransition(trans:TransitionData, status:TransitionStatus, ?callback:()->Void) @:privateAccess {
		if (curTrans != null) curTrans.finish();
		(curTrans = trans.createTransition(status, callback)).camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		curTrans._parentState = this;
		curTrans._created = true;
		curTrans.create();
		curTrans.start();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (updateConductor && conductor != null) conductor.update();

		modules.call('update', [elapsed]);
	}

	override function tryUpdate(elapsed:Float) {
		if (curTrans == null) super.tryUpdate(elapsed);
		else {
			if (curTrans.parentUpdate) super.tryUpdate(elapsed);
			if (curTrans.finished) {
				curTrans.destroy();
				curTrans = null;
			}
			else curTrans.update(elapsed);
		}
	}

	override function draw() {
		if (curTrans?.parentDraw ?? true) {
			if (FlxG.renderBlit) {
				for (camera in getCamerasLegacy()) camera.fill(bgColor);
			}
			else if (_bgSprite != null && _bgSprite.visible) {
				@:privateAccess _bgSprite._cameras = _cameras;
				_bgSprite.draw();
			}

			super.draw();
		}

		curTrans?.draw();

		if (subState == null) modules.call('draw');
	}

	override function destroy():Void {
		super.destroy();
		if (parent?.modules != modules) modules.destroy();

		transIn = null;
		transOut = null;
		parent = null;

		if (curTrans != null) curTrans.destroy();
		curTrans = null;

		if (conductor != null) {
			conductor.onMeasureHit.remove(_measureHit);
			conductor.onBeatHit.remove(_beatHit);
			conductor.onStepHit.remove(_stepHit);
			conductor.onMetronomeHit.remove(_metronomeHit);
		}
	}

	public function stepHit():Bool
		return !modules.event(ModuleEvent.get(StepHit).recycle(conductor.currentStep)).cancelled;

	public function beatHit():Bool
		return !modules.event(ModuleEvent.get(BeatHit).recycle(conductor.currentBeat)).cancelled;

	public function measureHit():Bool
		return !modules.event(ModuleEvent.get(MeasureHit).recycle(conductor.currentMeasure)).cancelled;

	public function metronomeHit(measureTicked:Bool):Bool
		return !modules.event(ModuleEvent.get(MetronomeHit).recycle(measureTicked, conductor.currentMeasure, conductor.currentBeat)).cancelled;

	function _stepHit() {
		stepHit();
		modules.eventPost(ModuleEvent.get(StepHit).recycle(conductor.currentStep));
	}

	function _beatHit() {
		beatHit();
		modules.eventPost(ModuleEvent.get(BeatHit).recycle(conductor.currentBeat));
	}

	function _measureHit() {
		measureHit();
		modules.eventPost(ModuleEvent.get(MeasureHit).recycle(conductor.currentMeasure));
	}

	function _metronomeHit(measureTicked:Bool) {
		metronomeHit(measureTicked);
		modules.eventPost(ModuleEvent.get(MetronomeHit).recycle(measureTicked, conductor.currentMeasure, conductor.currentBeat));
	}
}