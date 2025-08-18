package bl.graphic.shader;

class AdjustColorShader extends BlossomShader {
	@:glFragmentHeader("#include 'functions/adjustColor.glsl'
		vec4 hsb_flixel_texture2D(sampler2D bitmap, vec2 coord, float hue, float saturation, float brightness, float contrast) {
			vec4 color = texture2D(bitmap, coord);
			if (color.a != 0.0) color = vec4(adjustColor(color.rgb, hue, saturation, brightness, contrast), color.a);
			if (!hasTransform) return color;

			return apply_flixel_transform(color);
		}
	")

	@:glFragmentSource("#pragma header
		uniform float hue;
		uniform float saturation;
		uniform float brightness;
		uniform float contrast;

		void main() {
			gl_FragColor = hsb_flixel_texture2D(bitmap, openfl_TextureCoordv, hue, saturation, brightness, contrast);
			if (gl_FragColor.a == 0.0) discard;
		}
	")

	public function new() {
		super();
		hue.value = [0.0];
		saturation.value = [0.0];
		brightness.value = [0.0];
		contrast.value = [0.0];
	}
}