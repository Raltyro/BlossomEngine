package bl.object.transition;

import flixel.graphics.FlxGraphic;
import flixel.util.FlxGradient;

class TransitionFade extends Transition {
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	override function create() {
		super.create();
		createCamera();

		add(transGradient = new FlxSprite().loadGraphic(getGradient()));
		transGradient.scrollFactor.set();
		transGradient.flipY = status == IN;

		add(transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK));
		transBlack.scrollFactor.set();

		updateFade();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		updateFade();
	}

	private function updateFade() {
		var camera = camera ?? FlxG.camera, width:Float = FlxG.width, height:Float = FlxG.height, scaleX = 1., scaleY = 1.;
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
		@:privateAccess if (cachedGradient != null && cachedGradient.frameCollections != null) return cachedGradient;

		final key = "TransitionFadeGradient";
		(cachedGradient = AssetUtil.registerGraphic(FlxGradient.createGradientBitmapData(1, 1024, [FlxColor.BLACK, 0x0]), key, true));
		return cachedGradient;
	}
}