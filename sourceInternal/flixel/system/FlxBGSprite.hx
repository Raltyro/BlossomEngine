package flixel.system;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxBasic;

class FlxBGSprite extends FlxSprite {
	@:access(flixel.FlxCamera)
	override public function draw():Void {
		if ((_frame = FlxG.bitmap.whitePixel) == null || _frame.parent == null || _frame.parent.isDestroyed) return;
		for (camera in getCamerasLegacy()) {
			if (!camera.visible || !camera.exists) continue;

			_matrix.setTo(camera.viewWidth / _frame.parent.width, 0, 0, camera.viewHeight / _frame.parent.height, camera.viewMarginLeft, camera.viewMarginTop);
			camera.drawPixels(_frame, _matrix, colorTransform);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}
}
