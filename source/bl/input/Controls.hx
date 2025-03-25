// TODO: add gamepad support

package bl.input;

import flixel.input.FlxBaseKeyList;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

// Don't forget to add the default keyBind in the Controls>getDefaultKeyBind if you're planning to add more controls... or not
enum abstract Control(String) from String to String {
	var UI_UP = "ui_up";
	var UI_DOWN = "ui_down";
	var UI_LEFT = "ui_left";
	var UI_RIGHT = "ui_right";
	var ACCEPT = "accept";
	var BACK = "back";
	var PAUSE = "pause";
	var RESET = "reset";
	var CUTSCENE_ADVANCE = "cutscene_advance";
	var SCREENSHOT = "screenshot";
	var FULLSCREEN = "fullscreen";
	var VOLUME_UP = "volume_up";
	var VOLUME_DOWN = "volume_down";
	var VOLUME_MUTE = "volume_mute";
	var DEBUG_MENU = "debug_menu";
	var DEBUG_CHART = "debug_chart";
	var DEBUG_CHARACTER = "debug_character";
}

class Controls extends FlxActionSet {
	public static function getDefaultKeyBind(control:Control):Array<FlxKey> {
		return switch(control) {
			case UI_UP:             [UP, W];
			case UI_DOWN:           [DOWN, S];
			case UI_LEFT:           [LEFT, A];
			case UI_RIGHT:          [RIGHT, D];
			case ACCEPT:            [ENTER, Z, SPACE];
			case BACK:              [ESCAPE, X, BACKSPACE];
			case PAUSE:             [ESCAPE, ENTER];
			case RESET:             [R];
			case CUTSCENE_ADVANCE:  [ENTER, Z];
			case SCREENSHOT:        [PRINTSCREEN];
			case FULLSCREEN:        [F11];
			case VOLUME_UP:         [PLUS, NUMPADPLUS];
			case VOLUME_DOWN:       [MINUS, NUMPADMINUS];
			case VOLUME_MUTE:       [ZERO, NUMPADZERO];
			case DEBUG_MENU:        [SIX];
			case DEBUG_CHART:       [SEVEN];
			case DEBUG_CHARACTER:   [EIGHT];
			default: [];
		}
	}

	public static function getDefaultButtonBind(control:Control):Array<FlxGamepadInputID> {
		return switch(control) {
			case UI_UP:             [DPAD_UP, LEFT_STICK_DIGITAL_UP];
			case UI_DOWN:           [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN];
			case UI_LEFT:           [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT];
			case UI_RIGHT:          [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT];
			case ACCEPT:            [#if switch B #else A #end];
			case BACK:              [#if switch A #else B #end, FlxGamepadInputID.BACK];
			case PAUSE:             [START];
			case RESET:             [RIGHT_SHOULDER];
			case CUTSCENE_ADVANCE:  [A];
			default: [];
		}
	}

	public static var instance:Controls;

	public var pressed(default, null):FunkinControlList;
	public var justPressed(default, null):FunkinControlList;
	public var released(default, null):FunkinControlList;
	public var justReleased(default, null):FunkinControlList;
	public var controls:Map<Control, FunkinAction> = new Map<Control, FunkinAction>();

	public function new(?name:String = "FunkinControls", ?keyBinds:Map<Control, Array<FlxKey>>, ?buttonBinds:Map<Control, Array<FlxGamepadInputID>>, gamepadID:Int = FlxInputDeviceID.ALL) {
		var actions:Array<FlxActionDigital> = [];
		for (index => control in FunkinControlList.enums) actions.push(controls[control] = new FunkinAction(control));
		super(name, actions);

		if (keyBinds != null) setKeyBinds(keyBinds, false); else setDefaultKeyBinds(false);
		//if (buttonBinds != null) setButtonBinds(buttonBinds, false); else setDefaultButtonBinds(false);

		pressed = new FunkinControlList(PRESSED, this);
		justPressed = new FunkinControlList(JUST_PRESSED, this);
		released = new FunkinControlList(RELEASED, this);
		justReleased = new FunkinControlList(JUST_RELEASED, this);
	}

	public function reset() {
		@:privateAccess FlxG.keys.update();
		for (control in (cast digitalActions:Array<FunkinAction>)) if (control is FunkinAction) control.reset();
	}

	public function resetControlBinds() for (action in digitalActions) action.inputs = [];

	public function resetKeyBinds() for (action in digitalActions) {
		var i = action.inputs.length, input;
		while (i-- > 0) if ((input = action.inputs[i]).device == KEYBOARD) action.remove(input);
	}

	public function resetButtonBinds(deviceID:Int = FlxInputDeviceID.ALL) for (action in digitalActions) {
		var i = action.inputs.length, input;
		while (i-- > 0) if (isGamepad(input = action.inputs[i], deviceID)) action.remove(input);
	}

	public function setDefaultKeyBinds(reset:Bool = true) {
		if (reset) resetKeyBinds();
		for (control => v in controls) bindKeys(control, getDefaultKeyBind(control));
	}

	public function setKeyBinds(?binds:Map<Control, Array<FlxKey>>, reset:Bool = true) {
		if (reset) resetKeyBinds();

		var action;
		for (control => keys in binds) if ((action = controls.get(control)) != null) {
			if (keys.length == 0) bindKeys(control, getDefaultKeyBind(control));
			else if (keys.length != 1 || keys[0] != FlxKey.NONE) bindKeys(control, keys.copy());
		}
	}

	public function forEachBound(control:Control, func:FlxActionDigital->FlxInputState->Void) {
		var action = controls.get(control);
		if (action != null) {
			func(action, PRESSED);
			func(action, JUST_PRESSED);
			func(action, JUST_RELEASED);
		}
	}

	public function bindKeys(control:Control, keys:Array<FlxKey>)
		forEachBound(control, (action, state) -> addKeys(action, keys, state));

	public function unbindKeys(control:Control, keys:Array<FlxKey>)
		forEachBound(control, (action, _) -> removeKeys(action, keys));

	//public function bindSwipe(control:Control, swipeDir:Int = FlxDirectionFlags.UP, ?swpLength:Float = 90)
	//	forEachBound(control, function(action, press) action.add(new FlxActionInputDigitalMobileSwipeGameplay(swipeDir, press, swpLength)));

	static function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState)
		for (key in keys) if (key != FlxKey.NONE) action.addKey(key, state);

	static function removeKeys(action:FlxActionDigital, keys:Array<FlxKey>) {
		var i = action.inputs.length, input;
		while (i-- > 0) if ((input = action.inputs[i]).device == KEYBOARD && keys.indexOf(cast input.inputID) != -1) action.remove(input);
	}

	inline static function isGamepad(input:FlxActionInput, deviceID:Int)
		return input.device == GAMEPAD && (deviceID == FlxInputDeviceID.ALL || input.deviceID == deviceID);
}

@:build(bl.util.macro.BuildMacro.buildFunkinControlList()) // Builds the actual key list fields, enums:Map<Control, String> var
class FunkinControlList {
	var status:FlxInputState; var manager:Controls;

	public function new(Status, Manager) {
		status = Status;
		manager = Manager;
	}

	public var ANY(get, never):Bool;
	function get_ANY():Bool {
		for (control in (cast manager.digitalActions:Array<FunkinAction>)) if (control is FunkinAction && control.checkFiltered(status)) return true;
		return false;
	}

	public var NONE(get, never):Bool;
	function get_NONE():Bool {
		for (control in (cast manager.digitalActions:Array<FunkinAction>)) if (control is FunkinAction && control.checkFiltered(status)) return false;
		return true;
	}
}

class FunkinAction extends FlxActionDigital {
	var cache:Map<String, {timestamp:Float, value:Bool}> = [];
	var keys:Array<FlxKey> = [];

	override function addKey(key:FlxKey, trigger:FlxInputState):FlxActionDigital {
		if (!keys.contains(key)) keys.push(key);
		return super.addKey(key, trigger);
	}

	override function remove(input:FlxActionInput, destroy = true) {
		if (input.device == KEYBOARD) keys.remove(cast input.inputID);
		return super.remove(input, destroy);
	}

	public function new(name:String = "") super(name);

	public override function check():Bool return inline checkPressed();
	public function checkPressed():Bool return checkFiltered(PRESSED);
	public function checkJustPressed():Bool return checkFiltered(JUST_PRESSED);
	public function checkReleased():Bool return checkFiltered(RELEASED);
	public function checkJustReleased():Bool return checkFiltered(JUST_RELEASED);

	public function checkPressedGamepad():Bool return checkFiltered(PRESSED, GAMEPAD);
	public function checkJustPressedGamepad():Bool return checkFiltered(JUST_PRESSED, GAMEPAD);
	public function checkReleasedGamepad():Bool return checkFiltered(RELEASED, GAMEPAD);
	public function checkJustReleasedGamepad():Bool return checkFiltered(JUST_RELEASED, GAMEPAD);

	public function checkMultiFiltered(?filterTriggers:Array<FlxInputState>, ?filterDevices:Array<FlxInputDevice>):Bool {
		if (filterTriggers == null) filterTriggers = [PRESSED, JUST_PRESSED];
		if (filterDevices == null) for (i in filterTriggers) if (checkFiltered(i)) return true;
		else for (i in filterTriggers) for (j in filterDevices) if (checkFiltered(i, j)) return true;
		return false;
	}

	public function checkFiltered(?filterTrigger:FlxInputState, ?filterDevice:FlxInputDevice):Bool {
		// Make sure we only update the inputs once per frame.
		final key = '${filterTrigger}:${filterDevice}';
		var cacheEntry = cache.get(key);
		if (cacheEntry == null) cache.set(key, cacheEntry = {timestamp: 0, value: false});
		else if (cacheEntry.timestamp == FlxG.game.ticks) return cacheEntry.value;

		// Don't return early because we need to call check() on ALL inputs.
		var i = inputs != null ? inputs.length : 0, result = false;
		while (--i >= 0) {
			var input = inputs[i];
			if (input.destroyed) {
				inputs.swapAndPop(i);
				continue;
			}
			else if (FlxG.game.ticks != _timestamp) input.update();

			// Check whether the input is the right trigger.
			if (filterTrigger != null && input.trigger != filterTrigger) continue;

			// Check whether the input is the right device.
			if (filterDevice != null && input.device != filterDevice) continue;

			// Check whether the input has triggered.
			if (input.check(this)) result = true;
		}

		// We need to cache and return this result.
		cacheEntry.timestamp = _timestamp = FlxG.game.ticks;
		return cacheEntry.value = result;
	}

	public function reset() {
		for (entry in cache) entry.value = false;
	}
}