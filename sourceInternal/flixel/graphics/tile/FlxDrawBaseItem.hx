package flixel.graphics.tile;

import openfl.display.BlendMode;
import openfl.display.ShaderParameter;
import openfl.display3D.Context3DCompareMode;
import openfl.geom.ColorTransform;
import openfl.Vector;

import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.FlxCamera;

class FlxDrawBaseItem<T> {
	public static var drawCalls:Int = 0;

	public var nextTyped:T;
	public var next:FlxDrawBaseItem<T>;
	public var type:FlxDrawItemType;

	public var graphics:FlxGraphic;
	public var antialiasing:Bool = false;
	public var colored:Bool = false;
	public var hasColorOffsets:Bool = false;
	public var blend:BlendMode;
	public var depthCompareMode:Context3DCompareMode;

	public var numVertices(get, never):Int;
	public var numTriangles(get, never):Int;

	public function new() {}

	inline function baseReset() {
		graphics = null;
		antialiasing = false;
		depthCompareMode = null;
		nextTyped = null;
		next = null;
	}
	public function reset() baseReset();

	inline function baseDispose() {
		graphics = null;
		next = null;
		type = null;
		nextTyped = null;
	}
	public function dispose() baseDispose();

	public function render(camera:FlxCamera) {}

	public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform) {}

	function get_numVertices():Int return 0;
	function get_numTriangles():Int return 0;

	inline function setParameterValue(parameter:ShaderParameter<Bool>, value:Bool) {
		if (parameter.value == null) parameter.value = [value];
		else parameter.value[0] = value;
	}
}

enum FlxDrawItemType {
	TILES;
	TRIANGLES;
}