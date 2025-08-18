package bl.graphic.shader;

class Graphics3DShader extends BlossomShader {
	@:glVertexHeader("attribute float zVertex
attribute mat4 projectionMatrix;
attribute mat4 viewMatrix;
attribute mat4 modelMatrix;")

	@:glVertexSource("
		#pragma header
		void main(void) {
			#pragma body
			gl_Position = project(openfl_Position + vec4(0.0, 0.0, 0.0, zVertex), projectionMatrix, viewMatrix, modelMatrix);
		}
	")

	public function new() {
		super();
		projectionMatrix.value = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
		viewMatrix.value = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
		modelMatrix.value = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
	}
}