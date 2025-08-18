vec3 srgb2linear(vec3 color) {
	// note: some people use an approximation for the gamma of 2.0, for efficiency, but 2.2 is more correct
	return pow(color, vec3(2.2));
}

vec3 linear2srgb(vec3 color) {
	// note: if using gamma of 2.0, instead can use 0.5 as the value here
	return pow(color, vec3(0.45454545454545453/*1.0/2.2*/));
}