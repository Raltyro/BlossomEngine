package bl.object;

import openfl.display.BlendMode;
import openfl.display.TriangleCulling;
import openfl.display3D.Context3DCompareMode;
import openfl.geom.Matrix3D;

import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxShader;
import flixel.FlxBasic;
import flixel.FlxCamera;

import bl.data.MeshData;
import bl.graphic.shader.Graphics3DShader;
import bl.util.ShaderUtil;

using flixel.util.FlxColorTransformUtil;

class Mesh extends Object3D {
	public var shader:FlxShader = new Graphics3DShader();

	public var repeat:Bool = false;
	public var culling:TriangleCulling = POSITIVE;

	public var meshData(default, set):MeshData;
	public var meshWidth:Float;
	public var meshHeight:Float;
	public var meshDepth:Float;

	var _matrix3D:Matrix3D;
	var _graphic:FlxGraphic;
	var _verticesDummy:DrawData<Float> = new DrawData<Float>();
	var _indices:DrawData<Int> = new DrawData<Int>();
	var _uvs:DrawData<Float> = new DrawData<Float>();
	var _colors:DrawData<Int> = new DrawData<Int>();
	var _vertices:Array<Float> = [];

	public function new(x = 0.0, y = 0.0, z = 0.0, meshData:MeshData) {
		this.meshData = meshData;
		super(x, y, z, meshWidth, meshHeight, meshDepth);
	}

	override function initVars() {
		super.initVars();
		_matrix3D = new Matrix3D();
	}

	override function destroy() {
		super.destroy();
		_matrix3D = null;
	}

	public function updateHitbox() {
		width = meshWidth * Math.abs(scale.x);
		height = meshHeight * Math.abs(scale.y);
		depth = meshDepth * Math.abs(scale.y);
		centerOrigin();
	}

	inline public function centerOrigin()
		origin.set(meshData.minX + meshWidth * 0.5, meshData.minY + meshHeight * 0.5, meshData.minZ + meshDepth * 0.5);

	override function draw() {
		if (alpha == 0 || meshData == null) return;

		final param = ShaderUtil.getParameterFloat(shader, 'vertexOffset');
		if (param == null) return;

		//final prevZVertex = param.value;
		param.value = _vertices;

		Object3D.composeMatrix3D(getPosition3D(true).subtractVector3(offset), rotation, getScale3D(true), rotationOrder, origin, _matrix3D, false);
		Object3D.setModelMatrix(shader, _matrix3D);

		for (camera in getCamerasLegacy()) {
			if (!camera.visible || !camera.exists)
				continue;

			getPerspective(camera).applyShaderParameters(shader);

			final isColored:Bool = (_colors != null && _colors.length != 0) || (colorTransform != null && colorTransform.hasRGBMultipliers());
			final hasColorOffsets:Bool = (colorTransform != null && colorTransform.hasRGBAOffsets());
			final drawItem:FlxDrawTrianglesItem = camera.startTrianglesBatch(_graphic, antialiasing, isColored, blend, hasColorOffsets, shader, LESS_EQUAL, culling);
			drawItem.addTriangles(_verticesDummy, _indices, _uvs, _colors, colorTransform);

			#if FLX_DEBUG FlxBasic.visibleCount++; #end
		}

		//vertexOffsetParam.value = prevVertexOffset;
	}

	function set_meshData(value:MeshData):MeshData {
		if (meshData == value) return value;

		meshWidth = value.maxX - value.minX;
		meshHeight = value.maxY - value.minY;
		meshDepth = value.maxZ - value.minZ;

		_graphic = value.material != null ? AssetUtil.getGraphic(value.material.diffuseTexture) : null;

		_vertices.resize(0);
		_verticesDummy.length = 0;
		_indices.length = 0;
		_uvs.length = 0;

		/*
		for (vert in value.vertices) {
			_verticesDummy.push(1);
			_verticesDummy.push(1);
			_vertices.push(vert.x - 1);
			_vertices.push(vert.y - 1);
			_vertices.push(vert.z);
			_uvs.push(vert.uvX);
			_uvs.push(vert.uvY);
		}
		*/

		for (vert in value.vertices) {
			_verticesDummy.push(1);
			_verticesDummy.push(1);
			_uvs.push(vert.uvX);
			_uvs.push(vert.uvY);
		}

		for (idx in value.indices) {
			_vertices.push(value.vertices[idx].x - 1);
			_vertices.push(value.vertices[idx].y - 1);
			_vertices.push(value.vertices[idx].z);
			_indices.push(idx);
		}

		return meshData = value;
	}
}