package flixel.graphics.tile;

import openfl.display.GraphicsShader;

class FlxGraphicsShader extends GraphicsShader
{
	//@:glFragmentExtensions([{name: "GL_KHR_blend_equation_advanced", behavior: "enable"}])
	@:glVertexDontOverride
	@:glFragmentDontOverride
	@:glVertexHeader("
		attribute float openfl_Alpha;
		attribute vec4 openfl_ColorMultiplier;
		attribute vec4 openfl_ColorOffset;
		attribute vec4 openfl_Position;
		attribute vec2 openfl_TextureCoord;

		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;

		uniform mat4 openfl_Matrix;
		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;

		attribute float alpha;
		attribute vec4 colorMultiplier;
		attribute vec4 colorOffset;
		uniform bool hasColorTransform;
	", true)
	@:glVertexBody("
		openfl_Alphav = openfl_Alpha * alpha;
		openfl_TextureCoordv = openfl_TextureCoord;

		if (hasColorTransform) {
			if (openfl_HasColorTransform) {
				openfl_ColorOffsetv = (openfl_ColorOffset / 255.0 * colorMultiplier) + (colorOffset / 255.0);
				openfl_ColorMultiplierv = openfl_ColorMultiplier * colorMultiplier;
			}
			else {
				openfl_ColorOffsetv = colorOffset / 255.0;
				openfl_ColorMultiplierv = colorMultiplier;
			}
		}
		else if (openfl_HasColorTransform) {
			openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
			openfl_ColorMultiplierv = openfl_ColorMultiplier;
		}

		gl_Position = openfl_Matrix * openfl_Position;
	")
	@:glVertexSource("
		#pragma header
		void main(void) {
			#pragma body
		}
	", true)
	@:glFragmentHeader("
		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;

		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;
		uniform sampler2D bitmap;

		uniform bool hasTransform;
		uniform bool hasColorTransform;

		vec4 apply_flixel_transform(vec4 color) {
			if (color.a == 0.0 || openfl_Alphav == 0.0) return vec4(0.0, 0.0, 0.0, 0.0);
			else if (!openfl_HasColorTransform && !hasColorTransform) return color * openfl_Alphav;

			color = vec4(color.rgb / color.a, color.a);

			vec4 mult = vec4(openfl_ColorMultiplierv.rgb, 1.0);
			color = clamp(openfl_ColorOffsetv + (color * mult), 0.0, 1.0);

			return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
		}

		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord) {
			vec4 color = texture2D(bitmap, coord);
			if (!hasTransform) return color;

			return apply_flixel_transform(color);
		}
	", true)
	@:glFragmentBody("
		gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
		if (gl_FragColor.a == 0.0) discard;
	")
	@:glFragmentSource("
		#pragma header
		void main(void) {
			#pragma body
		}
	", true)
	public function new() {
		super();
	}
}
