package bl.input;

import flixel.input.actions.FlxAction;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput.FlxInputState;
import flixel.FlxBasic;

class TurboBasic extends FlxBasic {
	public static inline final DEFAULT_DELAY:Float = 0.4;
	public static inline final DEFAULT_INTERVAL:Float = 1 / 18;

	public var delay:Float;
	public var interval:Float;
	public var activated(default, null):Bool;
	public var pressed(get, never):Bool; function get_pressed() return false;
	public var allPress:Bool;

	var time:Float = 0;

	public function new(delay = DEFAULT_DELAY, interval = DEFAULT_INTERVAL, allPress = false) {
		super();
		this.delay = delay;
		this.interval = interval;
		this.allPress = allPress;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (pressed) {
			if (time == 0) activated = true;
			else if (activated = (time >= delay + interval)) time -= interval;
			time += elapsed;
		}
		else {
			activated = false;
			time = 0;
		}
	}
}

class TurboActions extends TurboBasic {
	public var actions:Array<FlxAction>;
	public function new(actions:Array<FlxAction>, ?delay:Float, ?interval:Float, ?allPress:Bool) {
		super(delay, interval, allPress);
		this.actions = actions;
	}

	override function get_pressed() {
		if (allPress) {
			for (action in actions) if (!action.check()) return false;
		}
		else {
			for (action in actions) if (action.check()) return true;
		}
		return allPress;
	}
}

class TurboKeys extends TurboBasic {
	public var keys:Array<FlxKey>;
	public function new(keys:Array<FlxKey>, ?delay:Float, ?interval:Float, ?allPress:Bool) {
		super(delay, interval, allPress);
		this.keys = keys;
	}

	override function get_pressed() {
		if (allPress) {
			for (key in keys) if (!FlxG.keys.checkStatus(key, PRESSED)) return false;
		}
		else {
			for (key in keys) if (FlxG.keys.checkStatus(key, PRESSED)) return true;
		}
		return allPress;
	}
}

class TurboButtons extends TurboBasic {
	public var inputs:Array<FlxGamepadInputID>;
	public var gamepad:FlxGamepad;
	public function new(inputs:Array<FlxGamepadInputID>, ?gamepad:FlxGamepad, ?delay:Float, ?interval:Float, ?allPress:Bool) {
		super(delay, interval, allPress);
		this.inputs = inputs;
		this.gamepad = gamepad ?? FlxG.gamepads.firstActive;
	}

	override function get_pressed() {
		if (allPress) {
			for (input in inputs) if (!gamepad.checkStatus(input, PRESSED)) return false;
		}
		else {
			for (input in inputs) if (gamepad.checkStatus(input, PRESSED)) return true;
		}
		return allPress;
	}
}