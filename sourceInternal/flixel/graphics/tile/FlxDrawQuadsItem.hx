package flixel.graphics.tile;

import openfl.geom.ColorTransform;
import openfl.Vector;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxShader;
import flixel.FlxCamera;

class FlxDrawQuadsItem extends FlxDrawBaseItem<FlxDrawQuadsItem> {
	static inline var VERTICES_PER_QUAD = 4;

	public var shader:FlxShader;
	var angles:Array<Float>;
	var alphas:Array<Float>;
	var colorMultipliers:Array<Float>;
	var colorOffsets:Array<Float>;

	public var rects:Vector<Float> = new Vector<Float>();
	public var transforms:Vector<Float> = new Vector<Float>();

	public function new() {
		super();
		type = FlxDrawItemType.TILES;
		angles = [];
		alphas = [];
	}

	override public function reset() {
		super.reset();
		rects.length = 0;
		transforms.length = 0;

		angles.resize(0);
		alphas.resize(0);
		colorMultipliers?.resize(0);
		colorOffsets?.resize(0);
	}

	override public function dispose() {
		super.dispose();
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

		final alpha = transform?.alphaMultiplier ?? 1;
		for (i in 0...VERTICES_PER_QUAD) {
			angles.push(frame.angle);
			alphas.push(alpha);
		}

		if (colored || hasColorOffsets) {
			if (colorMultipliers == null) colorMultipliers = [];
			if (colorOffsets == null) colorOffsets = [];

			for (i in 0...VERTICES_PER_QUAD) {
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

	override public function render(camera:FlxCamera):Void {
		if (graphics.isDestroyed) throw 'Attempting to draw a destroyed FlxGraphic as Quads';
		if (rects.length == 0) return;

		final shader = shader != null ? shader : graphics.shader;
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.filter = (camera.antialiasing || antialiasing) ? LINEAR : NEAREST;
		shader.frameRect.value = @:privateAccess untyped (rects).__array;
		shader.frameAngle.value = angles;
		shader.alpha.value = alphas;
		if (colored || hasColorOffsets) {
			shader.colorMultiplier.value = colorMultipliers;
			shader.colorOffset.value = colorOffsets;
		}

		setParameterValue(shader.hasTransform, true);
		setParameterValue(shader.hasColorTransform, colored || hasColorOffsets);

		camera.canvas.graphics.overrideBlendMode(blend);
		camera.canvas.graphics.beginShaderFill(shader);
		if (depthCompareMode == null) camera.canvas.graphics.overrideDepthTest(false, null);
		else camera.canvas.graphics.overrideDepthTest(true, depthCompareMode);
		camera.canvas.graphics.drawQuads(rects, null, transforms);

		super.render(camera);
	}
}