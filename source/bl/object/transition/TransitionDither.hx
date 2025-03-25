package bl.object.transition;

import flixel.system.FlxAssets.FlxShader;

class TransitionDither extends TransitionScreen {
	var tween:FlxTween;
	var shader:TransitionDitherShader;

	override function create() {
		super.create();
		if (skip) return;

		screen.shader = shader = new TransitionDitherShader();
		shader.zoom.value = [Math.max(Math.round(FlxG.height / 360), 1)]; // shader looks wacky if zoom is not integer
	}

	override function start() {
		super.start();
		if (!skip) tween = FlxTween.num(0, 1, duration, {ease: FlxEase.linear}, (f:Float) -> shader.dither.value = [f]);
	}

	override function destroy() {
		super.destroy();
		if (tween != null) tween.cancel();
		tween = null;
		shader = null;
	}
}


// Accurate Baldi Basics Plus/BBCR Dither Shader
class TransitionDitherShader extends FlxShader {
	@:glFragmentSource('
#pragma header
uniform float dither;
uniform float zoom;

float dither2(vec2 a) {
	a = floor(a + 0.5);
	return fract(a.x * 0.5 + a.y * a.y * 0.75);
}

#define dither4(a) (dither2(a * 0.5) * 0.25 + dither2(a))
#define dithering (dither4(openfl_TextureCoordv * openfl_TextureSize / zoom) + dither) * 2.0 - 1.0
void main() {
	if (dithering > 1.0) discard;
	gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
}
')

	public function new() {
		super();
		dither.value = [0];
		zoom.value = [1];
	}
}