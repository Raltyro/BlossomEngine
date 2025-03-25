package bl;

import bl.mod.event.ConductorHit;
import bl.mod.event.State;
import bl.object.transition.Transition;

class InitState extends flixel.FlxState {
	static var initialized:Bool = false;

	public function new() {
		super();
	}

	override function create() {
		super.create();

		if (!initialized) {
			initialized = true;
		}

		BLState.defaultTransIn = new TransitionData(bl.object.transition.TransitionFade, .5);
		BLState.defaultTransOut = new TransitionData(bl.object.transition.TransitionFade, .5);

		#if (sys && !macro)
		if (bl.util.CommandLineHandler.parse(Sys.args())) return;
		#end
		FlxG.switchState(bl.state.menu.TitleState.new);
	}
}