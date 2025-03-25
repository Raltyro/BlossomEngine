package bl.graphic.shader;

class AdjustColorShader extends Graphics3DShader
{
	@:glFragmentHeader("
		vec3 adjustColor(vec3 color, float hue, float saturation, float brightness, float contrast) {
			// b
			color = clamp(color + (brightness / 255.0), 0.0, 1.0);

			// h
			float angle = radians(hue);
			float cosAngle = cos(angle);
			vec3 k = vec3(0.57735, 0.57735, 0.57735);
			color = color * cosAngle + cross(k, color) * sin(angle) + k * dot(k, color) * (1.0 - cosAngle);

			// c
			color = clamp((color - 0.5) * (1.0 + ((contrast) / 255.0)) + 0.5, 0.0, 1.0);
		
			// s
			vec3 intensity = vec3(dot(color, vec3(0.30980392156, 0.60784313725, 0.08235294117)));
			return clamp(mix(intensity, color, (1.0 + (saturation / 100.0))), 0.0, 1.0);
		}

		vec4 hsb_flixel_texture2D(sampler2D bitmap, vec2 coord, float hue, float saturation, float brightness, float contrast) {
			vec4 color = texture2D(bitmap, coord);
			if (color.a != 0.0) color = vec4(adjustColor(color.rgb, hue, saturation, brightness, contrast), color.a);
			if (!hasTransform) return color;

			return apply_flixel_transform(color);
		}
	", true)
	@:glFragmentSource("
		#pragma header

		uniform float hue;
		uniform float saturation;
		uniform float brightness;
		uniform float contrast;

		void main() {
			gl_FragColor = hsb_flixel_texture2D(bitmap, openfl_TextureCoordv, hue, saturation, brightness, contrast);
			if (gl_FragColor.a == 0.0) discard;
		}
	", true)

	public function new() {
		super();
		hue.value = [0.0];
		saturation.value = [0.0];
		brightness.value = [0.0];
		contrast.value = [0.0];
	}
}