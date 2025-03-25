package bl.play.event;

import bl.play.PauseSubState.PauseMenuEntry;
final class RegeneratePauseMenu extends ModuleEvent {
	public static var classCallbackName:String = 'onRegeneratePauseMenu';
	public var entries:Array<PauseMenuEntry>;
}