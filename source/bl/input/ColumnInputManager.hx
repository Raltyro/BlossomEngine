package bl.input;

import haxe.Int64;

import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.system.System;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxInputText;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.FlxBasic;

private typedef ColumnInputRequest = {
	column:Int,
	ticks:Float,
	down:Bool
}

class ColumnInputManager implements IFlxDestroyable {
	public static function getDefaultKeyBinds(keys = 4):Array<Array<FlxKey>> {
		return switch (keys) {
			case 1: [[SPACE, G]];
			case 2: [[LEFT, A, DOWN, S], [UP, W, RIGHT, D, K, L]];
			case 3: [[LEFT, A, DOWN, S], [SPACE, G], [UP, W, RIGHT, D, K, L]];
			//case 4: [[LEFT, A], [DOWN, S], [UP, W, K], [RIGHT, D, L]];
			case 4: [[Z], [X], [K], [O]];
			case 5: [[LEFT, A], [DOWN, S], [SPACE, G], [UP, W, K], [RIGHT, D, L]];
			case 6: [[A], [S], [D], [J], [K], [L]];
			case 7: [[A], [S], [D], [SPACE, G], [J], [K], [L]];
			case 8: [[A], [S], [D], [F], [H], [J], [K], [L]];
			case 9: [[A], [S], [D], [F], [SPACE, G], [H], [J], [K], [L]];
			default: [];
		}
	}

	public static function getDefaultButtonBinds(keys = 4):Array<Array<FlxGamepadInputID>> {
		return switch (keys) {
			case 1: [[DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN,
				DPAD_UP, LEFT_STICK_DIGITAL_UP, DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT]];
			case 2: [[DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
				[DPAD_UP, LEFT_STICK_DIGITAL_UP, DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT]];
			case 3: [[DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT], [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, DPAD_UP, LEFT_STICK_DIGITAL_UP],
				[DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT]];
			case 4: [[DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT], [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
				[DPAD_UP, LEFT_STICK_DIGITAL_UP], [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT]];
			default: [];
		}
	}

	public static function getDefaultColumnKeyBinds():Map<Int, Array<Array<FlxKey>>>
		return [for (keys in 1...10) keys => ColumnInputManager.getDefaultKeyBinds(keys)];

	public static function getDefaultColumnButtonBinds():Map<Int, Array<Array<FlxGamepadInputID>>>
		return [for (keys in 1...5) keys => ColumnInputManager.getDefaultButtonBinds(keys)];

	static inline function getTicks():Float return @:privateAccess System.getTimer();
	static inline function checkTyping():Bool return FlxInputText.globalManager.isTyping;
	static inline function convertKeyCode(input:KeyCode):FlxKey @:privateAccess return Keyboard.__convertKeyCode(input);

	public var inputPressed:FlxTypedSignal<Int->Float->Void> = new FlxTypedSignal<Int->Float->Void>();
	public var inputReleased:FlxTypedSignal<Int->Float->Void> = new FlxTypedSignal<Int->Float->Void>();

	public var ticks:Float = getTicks();
	public var keys(default, set):Int;
	public var paused(default, set):Bool = false;

	public var columnKeyBinds:Map<Int, Array<Array<FlxKey>>>;
	public var columnButtonBinds:Map<Int, Array<Array<FlxGamepadInputID>>>;

	public var columnPressed:Array<Bool>;
	public var columnLastPress:Array<Float>;
	public var columnLastRelease:Array<Float>;

	var _columnPressed:Array<Bool>;
	var _pending:Array<ColumnInputRequest> = [];
	var _cache:Array<ColumnInputRequest> = [];

	public function new(keys = 4, ?columnKeyBinds:Map<Int, Array<Array<FlxKey>>>, ?columnButtonBinds:Map<Int, Array<Array<FlxGamepadInputID>>>) {
		this.columnKeyBinds = columnKeyBinds ?? getDefaultColumnKeyBinds();
		this.columnButtonBinds = columnButtonBinds ?? getDefaultColumnButtonBinds();
		this.keys = keys;

		//FlxG.stage.application.window.onKeyDownPrecise.add(handleKeyDown);
		//FlxG.stage.application.window.onKeyUpPrecise.add(handleKeyUp);
		FlxG.stage.application.window.onKeyDown.add(handleKeyDown);
		FlxG.stage.application.window.onKeyUp.add(handleKeyUp);
		FlxG.signals.preUpdate.add(update);
	}

	public function getKeyInColumn(key:FlxKey):Int {
		final keyBinds = columnKeyBinds.get(keys);
		if (keyBinds == null) return -1;

		for (column => binds in keyBinds) if (binds.contains(key)) return column;
		return -1;
	}

	public function getButtonInColumn(button:FlxGamepadInputID):Int {
		final buttonBinds = columnButtonBinds.get(keys);
		if (buttonBinds == null) return -1;

		for (column => binds in buttonBinds) if (binds.contains(button)) return column;
		return -1;
	}

	public function destroy() {
		//FlxG.stage.application.window.onKeyDownPrecise.remove(handleKeyDown);
		//FlxG.stage.application.window.onKeyUpPrecise.remove(handleKeyUp);
		FlxG.stage.application.window.onKeyDown.remove(handleKeyDown);
		FlxG.stage.application.window.onKeyUp.remove(handleKeyUp);
		FlxG.signals.preUpdate.remove(update);

		_pending = null;
		_cache = null;
	}

	function set_keys(value:Int):Int {
		if (keys == value) return value;

		final lastColumnPressed = columnPressed, ticks = getTicks();

		_columnPressed = [for (i in 0...value) false];
		columnPressed = [for (i in 0...value) false];
		columnLastPress = [for (i in 0...value) ticks];
		columnLastRelease = [for (i in 0...value) ticks];
		if (lastColumnPressed != null) for (i => v in lastColumnPressed) if (v) inputReleased.dispatch(i, ticks);

		for (request in _pending) _cache.push(request);
		_pending.clearArray();

		return keys = value;
	}

	function set_paused(value:Bool):Bool {
		if (paused == value) return value;
		else if (paused = value) {
			for (request in _pending) {
				_columnPressed[request.column] = request.down;
				_cache.push(request);
			}
			_pending.clearArray();
		}
		else {
			final ticks = getTicks();
			for (column in 0...keys) if (columnPressed[column] != _columnPressed[column])
				makeRequest(column, _columnPressed[column], ticks);
		}

		return value;
	}

	inline function makeRequest(column:Int, down:Bool, ticks:Float) {
		if (column == -1) return;

		if (paused) _columnPressed[column] = down;
		else {
			final request = _cache.pop();
			if (request == null) _pending.push({column: column, ticks: ticks, down: down});
			else {
				request.column = column;
				request.ticks = ticks;
				request.down = down;
				_pending.push(request);
			}
		}
	}

	function handleKeyDown(keyCode:KeyCode, _:KeyModifier/*, timestamp:Int64 */) {
		makeRequest(getKeyInColumn(convertKeyCode(keyCode)), true, getTicks());
	}

	function handleKeyUp(keyCode:KeyCode, _:KeyModifier/*, timestamp:Int64 */) {
		makeRequest(getKeyInColumn(convertKeyCode(keyCode)), false, getTicks());
	}

	function update() {
		if (paused || checkTyping()) {
			for (request in _pending) _cache.push(request);
			_pending.clearArray();
		}

		for (request in _pending) {
			if (columnPressed[request.column] != request.down) {
				if (columnPressed[request.column] = request.down)
					inputPressed.dispatch(request.column, columnLastPress[request.column] = request.ticks);
				else
					inputReleased.dispatch(request.column, columnLastRelease[request.column] = request.ticks);
			}
			_cache.push(request);
		}
		_pending.clearArray();

		ticks = getTicks();
	}
}