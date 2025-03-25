package bl.graphic.shader;

class RGBPalleteShader extends Graphics3DShader
{
	@:glFragmentHeader("
		vec4 replaceColorRGB(vec4 color, vec3 r, vec3 g, vec3 b, float rgbMix) {
			if (rgbMix == 0.0) return color;

			vec4 newColor = color;
			newColor.rgb = mix(color.rgb, min(color.r * r + color.g * g + color.b * b, vec3(1.0)), rgbMix);
			return newColor;
		}

		vec4 rgb_flixel_texture2D(sampler2D bitmap, vec2 coord, vec3 r, vec3 g, vec3 b, float rgbMix) {
			vec4 color = replaceColorRGB(texture2D(bitmap, coord), r, g, b, rgbMix);
			if (!hasTransform) return color;

			return apply_flixel_transform(color);
		}
	", true)
	@:glFragmentSource("
		#pragma header

		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float rgbMix;

		void main() {
			gl_FragColor = rgb_flixel_texture2D(bitmap, openfl_TextureCoordv, r, g, b, rgbMix);
			if (gl_FragColor.a == 0.0) discard;
		}
	", true)

	public function new() {
		super();
		r.value = [1.0, 1.0, 1.0];
		g.value = [1.0, 1.0, 1.0];
		b.value = [1.0, 1.0, 1.0];
		rgbMix.value = [1.0];
	}
}