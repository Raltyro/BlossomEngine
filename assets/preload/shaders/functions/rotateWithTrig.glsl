vec2 rotateWithTrig(vec2 uv, float c, float s) {
	return uv.xy * c + vec2(-uv.y, uv.x) * s;
}

vec2 rotateWithTrig(vec2 uv, vec2 trig) {
	return uv.xy * trig.x + vec2(-uv.y, uv.x) * trig.y;
}