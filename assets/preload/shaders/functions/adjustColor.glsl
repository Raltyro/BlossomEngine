// Although it does implements hsv modification, it's not that accurate? i suggest using hsvColor.glsl
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