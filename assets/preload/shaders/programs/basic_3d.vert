#pragma header

uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;

varying vec4 worldPosition;
varying vec4 viewPosition;

vec4 project(vec4 vertex) {
	mat4 internalMatrix = openfl_Matrix;
	vec4 internalOffset = vec4(internalMatrix[3].xy / vec2(internalMatrix[0][0], internalMatrix[1][1]), 0.0, 0.0);
	internalMatrix[3].xy = vec2(0.0);

	return projectionMatrix * internalMatrix * (viewPosition = viewMatrix * (worldPosition = (modelMatrix * vertex) + internalOffset));
}