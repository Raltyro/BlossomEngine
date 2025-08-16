package;

import openfl.display.Sprite;

#if FLX_DEBUG
import flixel.system.debug.watch.Tracker.TrackerProfile;
import flixel.system.debug.watch.Tracker;
#end

/*
final class Main extends Sprite {
	public function new() {
		super();

		#if FLX_DEBUG

		#end

		addChild(new blossom.backend.BLGame());
	}
}*/
class Main extends blossom.backend.BLGame {}