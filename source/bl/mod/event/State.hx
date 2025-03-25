package bl.mod.event;

import flixel.FlxState;

final class StateSwitch extends ModuleEvent {
	public static var classCallbackName:String = 'onStateSwitch';
}

final class StateCreate extends ModuleEvent {
	public static var classCallbackName:String = 'onStateCreate';
	public var state:FlxState;
}

final class StateDestroy extends ModuleEvent {
	public static var classCallbackName:String = 'onStateDestroy';
	public var state:FlxState;
}