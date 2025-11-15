package flixel.graphics.tile;

import openfl.geom.ColorTransform;
import openfl.Vector;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxShader;
import flixel.FlxCamera;

class FlxDrawQuadsItem extends FlxDrawBaseItem<FlxDrawQuadsItem> {
	static inline final VERTICES_PER_QUAD = 4;

	public var shader:FlxShader;
	public var rects:Vector<Float> = new Vector<Float>();
	public var transforms:Vector<Float> = new Vector<Float>();

	var angles:Array<Float> = [];
	var alphas:Array<Float> = [];

	var colorMultipliers:Array<Float> = [];
	var colorOffsets:Array<Float> = [];

	public function new() {
		super();
		type = TILES;
	}

	override public function reset() {
		baseReset();

		rects.length = 0;
		transforms.length = 0;

		angles.resize(0);
		alphas.resize(0);

		colorMultipliers.resize(0);
		colorOffsets.resize(0);
	}

	override public function dispose() {
		baseDispose();

		rects = null;
		transforms = null;

		angles = null;
		alphas = null;

		colorMultipliers = null;
		colorOffsets = null;
	}

	override public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform) {
		rects.push(frame.frame.x); rects.push(frame.frame.y);
		rects.push(frame.frame.width); rects.push(frame.frame.height);

		transforms.push(matrix.a); transforms.push(matrix.b); transforms.push(matrix.c);
		transforms.push(matrix.d); transforms.push(matrix.tx); transforms.push(matrix.ty);

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

			while (i < VERTICES_PER_QUAD) {
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
		else while (i < VERTICES_PER_QUAD) {
			angles.push(frame.angle);
			alphas.push(alpha);
			i++;
		}
	}

	override public function render(camera:FlxCamera):Void {
		if (graphics.isDestroyed) throw 'Attempted to render an invalid FlxDrawQaudsItem, did you destroy a cached sprite?';
		if (rects.length == 0) return;

		final shader = shader != null ? shader : graphics.shader;
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.filter = (camera.antialiasing || antialiasing) ? LINEAR : NEAREST;
		//shader.frameRect.value = untyped (rects).__array;
		//shader.frameAngle.value = angles;
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
		camera.canvas.graphics.drawQuads(rects, null, transforms);
		camera.canvas.graphics.endFill();

		FlxDrawBaseItem.drawCalls++;
	}

	override function get_numVertices():Int return rects.length;
	override function get_numTriangles():Int return Math.floor(rects.length / 2);
}