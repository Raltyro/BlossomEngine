package flixel.graphics.tile;

import openfl.display.Graphics;
import openfl.display.TriangleCulling;
import openfl.geom.ColorTransform;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.FlxCamera;

typedef DrawData<T> = openfl.Vector<T>;

class FlxDrawTrianglesItem extends FlxDrawBaseItem<FlxDrawTrianglesItem> {
	static var point:FlxPoint = FlxPoint.get();
	static var rect:FlxRect = FlxRect.get();

	public static inline function inflateBounds(bounds:FlxRect, x:Float, y:Float):FlxRect {
		if (x < bounds.x) {
			bounds.width += bounds.x - x;
			bounds.x = x;
		}

		if (y < bounds.y) {
			bounds.height += bounds.y - y;
			bounds.y = y;
		}

		if (x > bounds.x + bounds.width) bounds.width = x - bounds.x;
		if (y > bounds.y + bounds.height) bounds.height = y - bounds.y;

		return bounds;
	}

	// unused in this fork
	public var verticesPosition:Int = 0;
	public var indicesPosition:Int = 0;
	public var colorsPosition:Int = 0;
	var bounds:FlxRect = FlxRect.get();

	public var shader:FlxShader;
	var alphas:Array<Float>;
	var colorMultipliers:Array<Float>;
	var colorOffsets:Array<Float>;

	public var culling:TriangleCulling;
	public var vertices:DrawData<Float> = new DrawData<Float>();
	public var indices:DrawData<Int> = new DrawData<Int>();
	public var uvtData:DrawData<Float> = new DrawData<Float>();
	public var colors:DrawData<Int> = new DrawData<Int>();

	public function new() {
		super();
		type = FlxDrawItemType.TRIANGLES;
		alphas = [];
	}

	override public function reset() {
		super.reset();
		culling = NONE;

		vertices.length = 0;
		indices.length = 0;
		uvtData.length = 0;
		colors.length = 0;

		alphas.splice(0, alphas.length);
		colorMultipliers?.splice(0, colorMultipliers.length);
		colorOffsets?.splice(0, colorOffsets.length);
	}

	override public function dispose() {
		super.dispose();
		vertices = null;
		indices = null;
		uvtData = null;
		colors = null;
		bounds = null;

		alphas = null;
		colorMultipliers = null;
		colorOffsets = null;
	}

	public function addTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint,
		?cameraBounds:FlxRect, ?transform:ColorTransform)
	{
		if (position == null) position = point.set();

		final verticesLength = vertices.length,
			indicesLength = indices.length,
			prevNumberOfVertices = this.numVertices;

		var drawPosition = this.vertices.length, i = 0;
		while (i < verticesLength) {
			this.vertices[drawPosition++] = position.x + vertices[i++];
			this.vertices[drawPosition++] = position.y + vertices[i++];
		}

		drawPosition = this.uvtData.length;
		for (i in 0...uvtData.length) this.uvtData[drawPosition++] = uvtData[i];

		if (colored) {
			drawPosition = this.colors.length;
			for (i in 0...colors.length) this.colors[drawPosition++] = colors[i];
		}

		cameraBounds?.putWeak();
		position.putWeak();

		drawPosition = this.indices.length;
		final alpha = transform?.alphaMultiplier ?? 1;
		for (i in 0...indicesLength) {
			this.indices[drawPosition++] = indices[i] + prevNumberOfVertices;
			alphas.push(alpha);
		}

		if (colored || hasColorOffsets) {
			if (colorMultipliers == null) colorMultipliers = [];
			if (colorOffsets == null) colorOffsets = [];

			for (i in 0...indicesLength) {
				if (transform == null) {
					colorMultipliers.push(1);
					colorMultipliers.push(1);
					colorMultipliers.push(1);

					colorOffsets.push(1);
					colorOffsets.push(1);
					colorOffsets.push(1);
					colorOffsets.push(1);
				}
				else {
					colorMultipliers.push(transform.redMultiplier);
					colorMultipliers.push(transform.greenMultiplier);
					colorMultipliers.push(transform.blueMultiplier);

					colorOffsets.push(transform.redOffset);
					colorOffsets.push(transform.greenOffset);
					colorOffsets.push(transform.blueOffset);
					colorOffsets.push(transform.alphaOffset);
				}

				colorMultipliers.push(1);
			}
		}
	}

	/*
	public function addColoredTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>,
		?position:FlxPoint, ?cameraBounds:FlxRect, ?transforms:Array<ColorTransform>)
	{
		if (position == null) position = point.set();

		final verticesLength = vertices.length,
			indicesLength = indices.length,
			prevNumberOfVertices = this.numVertices;

		var drawPosition = this.vertices.length, i = 0;
		while (i < verticesLength) {
			this.vertices[drawPosition++] = position.x + vertices[i++];
			this.vertices[drawPosition++] = position.y + vertices[i++];
		}

		drawPosition = this.uvtData.length;
		for (i in 0...uvtData.length) this.uvtData[drawPosition++] = uvtData[i];

		if (colored) {
			drawPosition = this.colors.length;
			for (i in 0...colors.length) this.colors[drawPosition++] = colors[i];
		}

		cameraBounds?.putWeak();
		position.putWeak();

		drawPosition = this.indices.length;
		for (i in 0...indicesLength) this.indices[drawPosition++] = indices[i] + prevNumberOfVertices;

		for (i in 0...indicesLength) {

		if (colored || hasColorOffsets) {
			if (colorMultipliers == null) colorMultipliers = [];
			if (colorOffsets == null) colorOffsets = [];

			for (i in 0...indicesLength) {
				if (transform == null) {
					colorMultipliers.push(1);
					colorMultipliers.push(1);
					colorMultipliers.push(1);

					colorOffsets.push(1);
					colorOffsets.push(1);
					colorOffsets.push(1);
					colorOffsets.push(1);
				}
				else {
					colorMultipliers.push(transform.redMultiplier);
					colorMultipliers.push(transform.greenMultiplier);
					colorMultipliers.push(transform.blueMultiplier);

					colorOffsets.push(transform.redOffset);
					colorOffsets.push(transform.greenOffset);
					colorOffsets.push(transform.blueOffset);
					colorOffsets.push(transform.alphaOffset);
				}

				colorMultipliers.push(1);
			}
		}
	}*/

	override public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform)
	{
		// TODO: implement this, though it doesnt even worky in original anyway
	}

	override public function render(camera:FlxCamera) {
		if (graphics.isDestroyed) throw 'Attempting to draw a destroyed FlxGraphic as Triangles';
		if (numTriangles <= 0) return;

		final shader = shader != null ? shader : graphics.shader;
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.filter = (camera.antialiasing || antialiasing) ? LINEAR : NEAREST;
		shader.alpha.value = alphas;
		if (colored || hasColorOffsets) {
			shader.colorMultiplier.value = colorMultipliers;
			shader.colorOffset.value = colorOffsets;
		}

		setParameterValue(shader.hasTransform, true);
		setParameterValue(shader.hasColorTransform, colored || hasColorOffsets);

		camera.canvas.graphics.overrideBlendMode(blend);
		camera.canvas.graphics.beginShaderFill(shader);
		if (depthCompareMode == ALWAYS || depthCompareMode == null) camera.canvas.graphics.overrideDepthTest(false, ALWAYS);
		else camera.canvas.graphics.overrideDepthTest(true, depthCompareMode);
		camera.canvas.graphics.drawTriangles(vertices, indices, uvtData, culling);
		camera.canvas.graphics.endFill();

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug) {
			camera.debugLayer.graphics.lineStyle(1, FlxColor.BLUE, 0.5);
			camera.debugLayer.graphics.drawTriangles(vertices, indices, uvtData);
		}
		#end

		super.render(camera);
	}

	override function get_numVertices():Int return Std.int(vertices.length / 2);
	override function get_numTriangles():Int return Std.int(indices.length / 3);
}