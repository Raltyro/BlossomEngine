package blossom;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.geom.ColorTransform;

import flixel.addons.util.FlxSimplex;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import flixel.FlxBasic;
import flixel.FlxSprite;

import blossom.backend.util.BitmapDataUtil;
import blossom.graphic.BitmapDataPool;

@:access(openfl.display.Sprite)
@:access(flixel.graphics.frames.FlxFrame)
@:access(flixel.graphics.FlxGraphic)
class BLCamera extends flixel.FlxCamera {
	/**
	 * The rotation of the camera display (in degrees).
	 * In this case, the "angle" property for BLCamera are the camera's world rotation in degrees.
	 */
	public var rotation(default, set):Float = 0;

	/**
	 * The ratio of the distance to zooms to targetZoom the camera zooms per 1/60 sec.
	 * Valid values range from `0.0` to `1.0`. `1.0` means the camera always snaps to its target
	 * position. `0.5` means the camera always travels halfway to the target position, `0.0` means
	 * the camera does not move. Generally, the lower the value, the more smooth.
	 */
	public var zoomLerp:Float = 1.0;
	public var zoomSmoothScale:Float = 0.0;
	public var targetZoom:Null<Float>;
	public var zoomTween:FlxTween;

	public var followSmoothScale:Float = 0.75;
	public var disableSmoothCam:Bool = false;

	public var resolutionWidth:Null<Int>;
	public var resolutionHeight:Null<Int>;
	public var resolutionScale:Float;

	public var smoothing:Bool = true;
	public var canDraw:Bool = true;

	var _frame:FlxFrame;

	public function new(x = 0.0, y = 0.0, w = 0, h = 0, zoom = 0.0) {
		super(x, y, w, h, zoom);
		bgColor = 0;

		if (buffer == null) buffer = BitmapDataPool.get(resolutionWidth ?? width, resolutionHeight ?? height);
		else BitmapDataUtil.toHardware(buffer);

		if (_flashBitmap == null) _scrollRect.addChildAt(_flashBitmap = new Bitmap(buffer), 0);

		final graph = new FlxGraphic('BLCamera$ID', buffer, true);
		graph.destroyOnNoUse = false;
		FlxG.bitmap.addGraphic(graph);

		_frame = graph.imageFrame.frame;

		if (screen == null) screen = new FlxSprite();
		screen.frames = graph.imageFrame;
		screen.origin.set();
	}

	//inline public function setScroll(x = 0.0, y = 0.0) _scroll.copyFrom(scroll.set(x, y));

	function set_rotation(rotation:Float):Float {
		flashSprite.rotation = rotation;
		return this.rotation = rotation;
	}
}