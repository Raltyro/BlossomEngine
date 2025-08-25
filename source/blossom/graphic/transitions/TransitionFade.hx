package blossom.graphic.transitions;

import flixel.graphics.FlxGraphic;
import flixel.util.FlxGradient;

class TransitionFade extends Transition {
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	override function create() {
		super.create();
		createCamera(false);

		add(transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK));
		add(transGradient = new FlxSprite().loadGraphic(getGradient()));
		transGradient.flipY = status == IN;

		updateFade();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		updateFade();
	}

	private function updateFade() {
		var camera = camera ?? FlxG.camera, width:Float = FlxG.width, height:Float = FlxG.height, scaleX = 1.0, scaleY = 1.0;
		if (camera != null) {
			width = camera.width;
			height = camera.height;
			scaleX = camera.scaleX;
			scaleY = camera.scaleY;
		}

		var gradWidth = Math.ceil(width / scaleX), gradHeight = Math.ceil(height / scaleY);

		transGradient.setGraphicSize(gradWidth, gradHeight);
		transGradient.updateHitbox();
		transGradient.y = FlxMath.remapToRange(timer / duration, 0, 1, -gradHeight, gradHeight) -gradHeight + height;

		transBlack.setGraphicSize(gradWidth, gradHeight);
		transBlack.updateHitbox();
		transBlack.y = transGradient.y + (status == IN ? gradHeight : -gradHeight);

		transGradient.x = transBlack.x = -gradWidth + width;
	}

	private static var cachedGradient:FlxGraphic;
	private static function getGradient():FlxGraphic {
		@:privateAccess if (cachedGradient != null && !cachedGradient.isDestroyed) return cachedGradient;

		final key = "TransitionFadeGradient";
		return cachedGradient = AssetUtil.registerGraphic(FlxGradient.createGradientBitmapData(1, 255, [FlxColor.BLACK, 0]), key, true, true);
	}
}