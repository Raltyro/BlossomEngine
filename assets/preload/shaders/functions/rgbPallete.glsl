vec3 replaceColorRGB(vec3 color, vec3 r, vec3 g, vec3 b) {
	return vec3(min(color.r * r + color.g * g + color.b * b, vec3(1.0)));
}

vec4 replaceColorRGB(vec4 color, vec3 r, vec3 g, vec3 b) {
	vec3 c = color.rgb / color.a;
	c = vec3(min(c.r * r + c.g * g + c.b * b, vec3(1.0)));
	return vec4(c * color.a, color.a);
}