package blossom;

import blossom.backend.mod.events.ConductorEvent;
import blossom.backend.mod.events.StateEvent;
import blossom.backend.mod.ModuleGroup;
import blossom.graphic.transitions.Transition;
import blossom.input.Controls;

// It's a FlxSubstate instead so it can be a substate and a normal state
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

	public var parent(get, null):Null<BLState>;
	function get_parent()
		return if (parent != _parentState && (_parentState == null || _parentState is BLState)) parent = cast _parentState;
		else parent;

	public var controls(get, set):Controls;

	var _controls:Controls;
	inline function get_controls() return _controls ?? Controls.instance;
	inline function set_controls(controls) return _controls = controls;

	var _modules:ModuleGroup;
	public var modules(get, set):ModuleGroup;
	function get_modules() 
		if (_modules == null) return parent != null ? parent.modules : (_modules = new ModuleGroup());
		else return _modules;
	function set_modules(newModules) return _modules = newModules;

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

	public function new() super(0);

	override function create() {
		super.create();

		if (_parentState == null) bgColor = FlxColor.BLACK;

		if (conductor == null && _parentState == null) conductor = Conductor.instance;
		else updateConductor = false;

		_created = true;
		controls.reset();
	}

	override function createPost() {
		super.createPost();

		if (_parentState == null || transIn != null) {
			final trans = transIn ?? defaultTransIn;
			if (trans != null && !skipNextTransIn) openTransition(trans, IN);
			skipNextTransIn = false;
		}
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
		if (updateConductor) conductor?.update();

		modules.call1('update', elapsed);
	}

	override function tryUpdate(elapsed:Float) {
		if (curTrans != null) {
			if (curTrans.parentUpdate) super.tryUpdate(elapsed);
			if (curTrans.finished) {
				curTrans.destroy();
				curTrans = null;
			}
			else
				curTrans.update(elapsed);
		}
		else
			super.tryUpdate(elapsed);
	}

	override function draw() {
		if (curTrans != null) {
			if (curTrans.parentDraw) {
				super.draw();
				modules.call('draw');
			}
			curTrans.draw();
		}
		else {
			super.draw();
			modules.call('draw');
		}
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