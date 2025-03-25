package bl.graphic.shader;

import flixel.system.FlxAssets.FlxShader;

class Graphics3DShader extends FlxShader
{
	@:glVertexHeader("
		attribute float zVertex;
		attribute vec3 vertexOffset;
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
	", true)
	@:glVertexBody("
		gl_Position = openfl_Position + vec4(vertexOffset.xy, vertexOffset.z + zVertex, 0.0);
	", true)
	@:glVertexSource("
		#pragma header
		void main(void) {
			#pragma body
			gl_Position = project(gl_Position);
		}
	", true)
	/*@:glFragmentSource("
		#pragma header
		void main(void) {
			gl_FragColor = vec4(vec3(gl_FragCoord.z), 1.0) * flixel_texture2D(bitmap, openfl_TextureCoordv).a;
		}
	", true)*/

	public function new() {
		super();
		projectionMatrix.value = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
		viewMatrix.value = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
		modelMatrix.value = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
	}
}