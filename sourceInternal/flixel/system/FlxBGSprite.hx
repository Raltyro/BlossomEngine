package flixel.system;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxBasic;

class FlxBGSprite extends FlxSprite {
	@:access(flixel.FlxCamera)
	override public function draw():Void {
		for (camera in getCamerasLegacy()) if (camera.visible && camera.exists) {
			camera.fill(color.rgb, true, alpha);
		}
	}
}
