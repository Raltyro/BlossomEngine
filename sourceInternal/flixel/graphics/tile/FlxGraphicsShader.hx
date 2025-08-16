package flixel.graphics.tile;

import openfl.display.GraphicsShader;

class FlxGraphicsShader extends GraphicsShader
{
	@:glVertexDontOverride
	@:glFragmentDontOverride
	@:glVertexHeader("
		in float openfl_Alpha;
		in vec4 openfl_ColorMultiplier;
		in vec4 openfl_ColorOffset;
		in vec4 openfl_Position;
		in vec2 openfl_TextureCoord;

		out float openfl_Alphav;
		out vec4 openfl_ColorMultiplierv;
		out vec4 openfl_ColorOffsetv;
		out vec2 openfl_TextureCoordv;

		uniform mat4 openfl_Matrix;
		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;

		in float alpha;
		in vec4 colorMultiplier;
		in vec4 colorOffset;
		uniform bool hasColorTransform;
	")
	@:glVertexBody("
		openfl_Alphav = openfl_Alpha * alpha;
		openfl_TextureCoordv = openfl_TextureCoord;

		if (openfl_HasColorTransform) {
			openfl_ColorMultiplierv = openfl_ColorMultiplier;
			openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
		}

		if (hasColorTransform) {
			openfl_ColorOffsetv = colorOffset / 255.0;
			openfl_ColorMultiplierv = colorMultiplier;
		}

		gl_Position = openfl_Matrix * openfl_Position;
	")
	@:glVertexSource("
		#pragma header
		void main(void) {
			#pragma body
		}
	")
	@:glFragmentHeader("
		layout(location = 0) out vec4 ofl_FragColor;
		in float openfl_Alphav;
		in vec4 openfl_ColorMultiplierv;
		in vec4 openfl_ColorOffsetv;
		in vec2 openfl_TextureCoordv;

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
	")
	@:glFragmentBody("
		ofl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
		if (ofl_FragColor.a == 0.0) discard;
	")
	@:glFragmentSource("
		#pragma header
		void main(void) {
			#pragma body
		}
	")
	public function new() {
		super();
	}
}
