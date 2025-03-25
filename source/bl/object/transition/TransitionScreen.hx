package bl.object.transition;

import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import bl.util.BitmapDataUtil;

class TransitionScreen extends Transition {
	public static var graphic:FlxGraphic;

	static var gotScreen:Bool = false;
	public static function getScreen() {
		gotScreen = true;

		var w = Math.ceil(Math.min(FlxG.width, FlxG.bitmap.maxTextureSize)), h = Math.ceil(Math.min(FlxG.height, FlxG.bitmap.maxTextureSize));
		if (graphic == null) makeGraphic(w, h);
		else {
			if (w != graphic.width || h != graphic.height) BitmapDataUtil.resize(graphic.bitmap, w, h);
			BitmapDataUtil.clear(graphic.bitmap, FlxColor.BLACK);
		}

		final rx = 1 / FlxG.scaleMode.scale.x, ry = 1 / FlxG.scaleMode.scale.y;
		for (camera in FlxG.cameras.list) @:privateAccess {
			if (camera is BLCamera) {
				final blCam = cast(camera, BLCamera);
				if (blCam._presented) BitmapDataUtil.draw(graphic.bitmap, blCam.buffer);
				else blCam.grabScreen(graphic.bitmap);
			}
			else {
				final mat = camera._helperMatrix;
				if (mat != null) {
					mat.setTo(rx, 0, 0, ry, 0, 0);
					BitmapDataUtil.draw(graphic.bitmap, camera._scrollRect, mat, FlxSprite.defaultAntialiasing);
				}
			}
		}
	}

	var screen:FlxSprite;
	var skip:Bool = false;

	override function create() {
		super.create();
		createCamera();

		if (status == OUT) {
			getScreen();
			skip = true;
		}
		else if (!gotScreen) skip = true;
		else {
			gotScreen = false;
			add(screen = new FlxSprite().loadGraphic(graphic));
			screen.scale.set(1 / camera.zoom, 1 / camera.zoom);
			screen.updateHitbox();
		}
	}

	override function start() {
		super.start();
		if (skip) finish();
	}

	override function destroy() {
		super.destroy();

		if (screen != null) screen.destroy();
		screen = null;
	}

	inline private static function makeGraphic(width:Int, height:Int)
		graphic = AssetUtil.registerGraphic(BitmapDataUtil.create(width, height), 'TransitionScreen', true);
}