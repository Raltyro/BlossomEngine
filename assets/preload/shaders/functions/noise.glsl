float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(float p){
	float i = floor(p);
	float f = fract(p);
	return mix(hash(i), hash(i + 1.0), f);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	vec2 u = f*f*(3.0-2.0*f);

	return mix(mix(hash(i + vec2(0.0,0.0)), 
				   hash(i + vec2(1.0,0.0)), u.x),
			   mix(hash(i + vec2(0.0,1.0)), 
				   hash(i + vec2(1.0,1.0)), u.x), u.y);
}