package bl.state.base;

import flixel.addons.ui.FlxUIAssets;
import flixel.util.typeLimit.NextState;

import bl.mod.event.ConductorHit;
import bl.mod.event.State;
import bl.object.transition.Transition;
import bl.input.Controls;

class BLStateUI extends flixel.addons.ui.FlxUISubState {
	// beginning & ending transitions for THIS state:
	public var transIn:TransitionData;
	public var transOut:TransitionData;
	public var curTrans:Transition;

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

	public var controls(get, never):Controls; inline function get_controls() return Controls.instance;

	public function new() {
		super();
		cacheFlixelUI();
	}

	override function create() {
		super.create();

		//if (!(FlxG.camera is BLCamera) && FlxG.cameras.list.length == 1) FlxG.cameras.reset(new BLCamera());
		//if (bgColor == 0) bgColor = FlxColor.BLACK;
		camera.bgColor = bgColor = 0;

		_created = true;

		final trans = transIn ?? BLState.defaultTransIn;
		if (trans != null && !BLState.skipNextTransIn) openTransition(trans, IN);
		BLState.skipNextTransIn = false;

		AssetUtil.gc();
	}

	override function startOutro(onOutroComplete:()->Void) {
		final trans = transOut ?? BLState.defaultTransOut;
		if (trans != null && !BLState.skipNextTransOut) {
			if (curTrans != null && curTrans.status == OUT) curTrans.finishCallback = onOutroComplete;
			else openTransition(trans, OUT, onOutroComplete);
		}
		else onOutroComplete();
		BLState.skipNextTransOut = false;
	}

	private function openTransition(trans:TransitionData, status:TransitionStatus, ?callback:()->Void) @:privateAccess {
		if (curTrans != null) curTrans.finish();
		(curTrans = trans.createTransition(status, callback)).camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		curTrans._parentState = this;
		curTrans._created = true;
		curTrans.create();
		curTrans.start();
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
	}

	override function destroy():Void {
		super.destroy();

		transIn = null;
		transOut = null;

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
		return true;

	public function beatHit():Bool
		return true;

	public function measureHit():Bool
		return true;

	public function metronomeHit(measureTicked:Bool):Bool
		return true;

	function _stepHit() stepHit();
	function _beatHit() beatHit();
	function _measureHit() measureHit();
	function _metronomeHit(measureTicked:Bool) metronomeHit(measureTicked);

	inline function cacheFlixelUI() {
		final arr = [
			FlxUIAssets.IMG_BUTTON,
			FlxUIAssets.IMG_BUTTON_ARROW_DOWN,
			FlxUIAssets.IMG_BUTTON_ARROW_LEFT,
			FlxUIAssets.IMG_BUTTON_ARROW_RIGHT,
			FlxUIAssets.IMG_BUTTON_ARROW_UP,
			FlxUIAssets.IMG_BUTTON_THIN,
			FlxUIAssets.IMG_BUTTON_TOGGLE,

			FlxUIAssets.IMG_CHECK_MARK,
			FlxUIAssets.IMG_CHECK_BOX,
			FlxUIAssets.IMG_CHROME,
			FlxUIAssets.IMG_CHROME_LIGHT,
			FlxUIAssets.IMG_CHROME_FLAT,
			FlxUIAssets.IMG_CHROME_INSET,
			FlxUIAssets.IMG_RADIO,
			FlxUIAssets.IMG_RADIO_DOT,
			FlxUIAssets.IMG_TAB,
			FlxUIAssets.IMG_TAB_BACK,
			FlxUIAssets.IMG_BOX,
			FlxUIAssets.IMG_DROPDOWN,
			FlxUIAssets.IMG_PLUS,
			FlxUIAssets.IMG_MINUS,
			FlxUIAssets.IMG_HILIGHT,
			FlxUIAssets.IMG_INVIS,
			FlxUIAssets.IMG_SWATCH,
			FlxUIAssets.IMG_TOOLTIP_ARROW,

			FlxUIAssets.IMG_FINGER_SMALL,
			FlxUIAssets.IMG_FINGER_BIG
		];
		for (v in arr) AssetUtil.getGraphic(v, true, false);
	}
}
