package flixel.system;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxBasic;

class FlxBGSprite extends FlxSprite {
	public function new() {
		super();
		makeGraphic(1, 1, FlxColor.WHITE, true, "bg_graphic");
		scrollFactor.set();
	}

	@:access(flixel.FlxCamera)
	override public function draw():Void {
		for (camera in getCamerasLegacy()) {
			if (!camera.visible || !camera.exists) continue;

			_matrix.setTo(camera.viewWidth, 0, 0, camera.viewHeight, camera.viewMarginLeft, camera.viewMarginTop);
			camera.drawPixels(frame, _matrix, colorTransform);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}
}
