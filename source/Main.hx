package;

import openfl.display.Sprite;

#if FLX_DEBUG
import flixel.system.debug.watch.Tracker.TrackerProfile;
import flixel.system.debug.watch.Tracker;
#end

class Main extends Sprite {
	public function new() {
		super();

		addChild(new blossom.backend.Game());
	}
}