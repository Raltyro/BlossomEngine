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
	static inline final INDICES_PER_QUAD = 6;
	static final point:FlxPoint = FlxPoint.get();
	static final rect:FlxRect = FlxRect.get();
	//static final bounds = FlxRect.get();

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

	public var shader:FlxShader;
	public var culling:TriangleCulling;
	public var vertices:DrawData<Float> = new DrawData<Float>();
	public var indices:DrawData<Int> = new DrawData<Int>();
	public var uvtData:DrawData<Float> = new DrawData<Float>();
	public var colors:DrawData<Int> = new DrawData<Int>();

	var angles:Array<Float> = [];
	var alphas:Array<Float> = [];

	var colorMultipliers:Array<Float> = [];
	var colorOffsets:Array<Float> = [];

	public function new() {
		super();
		type = TRIANGLES;
	}

	override public function reset() {
		super.reset();

		//verticesPosition = 0;
		//indicesPosition = 0;
		//colorsPosition = 0;

		culling = NONE;
		vertices.length = 0;
		indices.length = 0;
		uvtData.length = 0;
		colors.length = 0;

		angles.resize(0);
		alphas.resize(0);

		colorMultipliers.resize(0);
		colorOffsets.resize(0);
	}

	override public function dispose() {
		super.dispose();

		vertices = null;
		indices = null;
		uvtData = null;
		colors = null;

		angles = null;
		alphas = null;

		colorMultipliers = null;
		colorOffsets = null;
	}

	public function addTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint,
		?cameraBounds:FlxRect, ?transform:ColorTransform)
	{
		if (position == null) position = point.set();
		cameraBounds?.putWeak(); // unused

		final verticesLength = Math.floor(vertices.length / 2) * 2, prevNumberOfVertices = this.numVertices;

		var i = 0;
		while (i < verticesLength) {
			this.uvtData.push(uvtData[i]);
			this.vertices.push(position.x + vertices[i]);
			this.uvtData.push(uvtData[++i]);
			this.vertices.push(position.y + vertices[i]);
			i++;
		}
		position.putWeak();

		final indicesLength = Math.floor(indices.length / 3) * 3, colorsLength = colors != null ? colors.length : 0, alpha = transform?.alphaMultiplier ?? 1.0;
		i = 0;

		var index = 0, color:FlxColor = 0;
		if (colored || hasColorOffsets) {
			var redMultiplier = 1.0, greenMultiplier = 1.0, blueMultiplier = 1.0;
			var redOffset = 1.0, greenOffset = 1.0, blueOffset = 1.0, alphaOffset = 1.0;

			if (transform != null) {
				redMultiplier = transform.redMultiplier;
				greenMultiplier = transform.greenMultiplier;
				blueMultiplier = transform.blueMultiplier;

				redOffset = transform.redOffset;
				greenOffset = transform.greenOffset;
				blueOffset = transform.blueOffset;
				alphaOffset = transform.alphaOffset;
			}

			while (i < indicesLength) {
				if ((index = indices[i]) < colorsLength) {
					colorMultipliers.push(redMultiplier * (color = colors[index]).redFloat);
					colorMultipliers.push(greenMultiplier * color.greenFloat);
					colorMultipliers.push(blueMultiplier * color.blueFloat);
					colorMultipliers.push(color.alphaFloat);
				}
				else {
					colorMultipliers.push(redMultiplier);
					colorMultipliers.push(greenMultiplier);
					colorMultipliers.push(blueMultiplier);
					colorMultipliers.push(1.0);
				}

				colorOffsets.push(redOffset);
				colorOffsets.push(greenOffset);
				colorOffsets.push(blueOffset);
				colorOffsets.push(alphaOffset);

				angles.push(0);
				alphas.push(alpha);

				this.indices.push(prevNumberOfVertices + index);
				i++;
			}
		}
		else while (i < indicesLength) {
			if ((index = indices[i]) < colorsLength) alphas.push(alpha * (color = colors[index]).alphaFloat);
			else alphas.push(alpha);

			angles.push(0);
			this.indices.push(prevNumberOfVertices + index);
			i++;
		}
	}

	public function addColoredTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint,
		?cameraBounds:FlxRect, ?transforms:Array<ColorTransform>)
	{
		if (position == null) position = point.set();
		cameraBounds?.putWeak(); // unused

		final verticesLength = Math.floor(vertices.length / 2) * 2, prevNumberOfVertices = this.numVertices;

		var i = 0;
		while (i < verticesLength) {
			this.uvtData.push(uvtData[i]);
			this.vertices.push(position.x + vertices[i]);
			this.uvtData.push(uvtData[++i]);
			this.vertices.push(position.y + vertices[i]);
			i++;
		}
		position.putWeak();

		final indicesLength = Math.floor(indices.length / 3) * 3, colorsLength = colors?.length ?? 0, transformsLength = transforms?.length ?? 0;
		i = 0;

		if (colored || hasColorOffsets) {
			var index = 0, color:FlxColor = 0, transform = null;
			var redMultiplier = 1.0, greenMultiplier = 1.0, blueMultiplier = 1.0, redOffset = 1.0, greenOffset = 1.0, blueOffset = 1.0, alphaOffset = 1.0;

			while (i < indicesLength) {
				if ((index = indices[i]) < transformsLength) {
					redMultiplier = (transform = transforms[index]).redMultiplier;
					greenMultiplier = transform.greenMultiplier;
					blueMultiplier = transform.blueMultiplier;
					alphas.push(transform.alphaMultiplier);

					redOffset = transform.redOffset;
					greenOffset = transform.greenOffset;
					blueOffset = transform.blueOffset;
					alphaOffset = transform.alphaOffset;
				}
				else {
					redMultiplier = 1.0;
					greenMultiplier = 1.0;
					blueMultiplier = 1.0;
					alphas.push(1.0);

					redOffset = 1.0;
					greenOffset = 1.0;
					blueOffset = 1.0;
					alphaOffset = 1.0;
				}

				if (index < colorsLength) {
					colorMultipliers.push(redMultiplier * (color = colors[index]).redFloat);
					colorMultipliers.push(greenMultiplier * color.greenFloat);
					colorMultipliers.push(blueMultiplier * color.blueFloat);
					colorMultipliers.push(color.alphaFloat);
				}
				else {
					colorMultipliers.push(redMultiplier);
					colorMultipliers.push(greenMultiplier);
					colorMultipliers.push(blueMultiplier);
					colorMultipliers.push(1.0);
				}

				colorOffsets.push(redOffset);
				colorOffsets.push(greenOffset);
				colorOffsets.push(blueOffset);
				colorOffsets.push(alphaOffset);

				angles.push(0);

				this.indices.push(prevNumberOfVertices + index);
				i++;
			}
		}
		else while (i < indicesLength) {
			angles.push(0);
			alphas.push(1.0);
			this.indices.push(prevNumberOfVertices + indices[i]);
			i++;
		}
	}

	override public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform)
	{
		final prevNumberOfVertices = numVertices;

		inline function addVertex(x:Float, y:Float) {
			vertices.push(point.set(x, y).transform(matrix).x);
			vertices.push(point.y);
		}

		addVertex(0, 0);
		addVertex(frame.frame.width, 0);
		addVertex(frame.frame.width, frame.frame.height);
		addVertex(0, frame.frame.height);

		uvtData.push(frame.uv.left); uvtData.push(frame.uv.top);
		uvtData.push(frame.uv.right); uvtData.push(frame.uv.top);
		uvtData.push(frame.uv.right); uvtData.push(frame.uv.bottom);
		uvtData.push(frame.uv.left); uvtData.push(frame.uv.bottom);

		indices.push(prevNumberOfVertices);
		indices.push(prevNumberOfVertices + 1);
		indices.push(prevNumberOfVertices + 2);
		indices.push(prevNumberOfVertices + 2);
		indices.push(prevNumberOfVertices + 3);
		indices.push(prevNumberOfVertices);

		final alpha = transform?.alphaMultiplier ?? 1.0;
		var i = 0;

		if (colored || hasColorOffsets) {
			var redMultiplier = 1.0, greenMultiplier = 1.0, blueMultiplier = 1.0;
			var redOffset = 1.0, greenOffset = 1.0, blueOffset = 1.0, alphaOffset = 1.0;

			if (transform != null) {
				redMultiplier = transform.redMultiplier;
				greenMultiplier = transform.greenMultiplier;
				blueMultiplier = transform.blueMultiplier;

				redOffset = transform.redOffset;
				greenOffset = transform.greenOffset;
				blueOffset = transform.blueOffset;
				alphaOffset = transform.alphaOffset;
			}

			while (i < INDICES_PER_QUAD) {
				colorMultipliers.push(redMultiplier);
				colorMultipliers.push(greenMultiplier);
				colorMultipliers.push(blueMultiplier);
				colorMultipliers.push(1.0);

				colorOffsets.push(redOffset);
				colorOffsets.push(greenOffset);
				colorOffsets.push(blueOffset);
				colorOffsets.push(alphaOffset);

				angles.push(frame.angle);
				alphas.push(alpha);
				i++;
			}
		}
		else while (i < INDICES_PER_QUAD) {
			angles.push(frame.angle);
			alphas.push(alpha);
			i++;
		}
	}

	override public function render(camera:FlxCamera) {
		if (graphics.isDestroyed) throw 'Attempted to render an invalid FlxDrawTrianglesItem, did you destroy a cached sprite?';
		if (vertices.length == 0) return;

		final shader = shader != null ? shader : graphics.shader;
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.filter = (camera.antialiasing || antialiasing) ? LINEAR : NEAREST;
		shader.frameRect.value = @:privateAccess untyped (uvtData).__array;
		shader.frameAngle.value = angles;
		shader.alpha.value = alphas;

		if (colored || hasColorOffsets) {
			setParameterValue(shader.hasColorTransform, true);
			shader.colorMultiplier.value = colorMultipliers;
			shader.colorOffset.value = colorOffsets;
		}
		else {
			setParameterValue(shader.hasColorTransform, false);
			shader.colorMultiplier.value = null;
			shader.colorOffset.value = null;
		}

		setParameterValue(shader.hasTransform, true);

		camera.canvas.graphics.overrideBlendMode(blend);
		camera.canvas.graphics.beginShaderFill(shader);
		if (depthCompareMode == null) camera.canvas.graphics.overrideDepthTest(false, null);
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

	override function get_numVertices():Int return Math.floor(vertices.length / 2);
	override function get_numTriangles():Int return Math.floor(indices.length / 3);
}