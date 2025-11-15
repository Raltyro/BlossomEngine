/*
	Implement Notch detection for mobile devices in the scale mode later
*/

package blossom.backend;

import flixel.math.FlxPoint;

class FullScreenScaleMode extends flixel.system.scaleModes.BaseScaleMode {
	public static var instance:FullScreenScaleMode = null;

	public var minAspectRatio:Float = FlxG.initialWidth / FlxG.initialHeight;
	public var maxAspectRatio:Float = FlxG.initialWidth * 1.25 / FlxG.initialHeight;
	public var enabled(default, set):Bool;

	public function new() {
		super();

		@:bypassAccessor enabled = #if SCALEMODE_NO_FULLSCREEN false #else true #end;
		instance = this;
	}

	function set_enabled(value:Bool) {
		if (enabled != (enabled = value)) return value;
		if (value) {

		}
		else {
			
		}
		return value;
	}
}

//class CutoutTiles extends 