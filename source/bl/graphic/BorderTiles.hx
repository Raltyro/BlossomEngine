package bl.graphic;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.Vector;

import bl.util.BitmapDataUtil;

class BorderTiles extends Bitmap {
	public var pixelPerfect(default, set):Bool;

	var _bitmapData:BitmapData;
	var _visible:Bool = true;
	var _shape:Shape = new Shape();
	var _rects:Vector<Float> = new Vector<Float>();
	var _transforms:Vector<Float> = new Vector<Float>();

	public function new(?bitmapData:BitmapData) {
		super(BitmapDataUtil.create(FlxG.stage.stageWidth, FlxG.stage.stageHeight));

		@:bypassAccessor pixelPerfect = false;
		this.bitmapData = bitmapData;

		//FlxG.stage.addEventListener(Event.RESIZE, onResize);
		FlxG.signals.gameResized.add(onResize);
	}

	private function refresh() {
		BitmapDataUtil.clear(__bitmapData);
		if (!(__visible = _visible && _bitmapData != null)) return;

		//FlxG.scaleMode.onMeasure(FlxG.stage.stageWidth, FlxG.stage.stageHeight);
		__visible = FlxG.scaleMode.gameSize.x + 3 < FlxG.scaleMode.deviceSize.x || FlxG.scaleMode.gameSize.y + 3 <= FlxG.scaleMode.deviceSize.y;

		var scale = Math.min(FlxG.scaleMode.scale.x, FlxG.scaleMode.scale.y);
		if (pixelPerfect) scale = Math.round(scale);

		_shape.graphics.clear();
		_shape.graphics.beginBitmapFill(_bitmapData, true);

		final width = Math.round(FlxG.stage.stageWidth / scale), height = Math.round(FlxG.stage.stageHeight / scale);

		_rects.length = 0;
		_rects.push(Math.round(-width / 2 + _bitmapData.width / 2));
		_rects.push(Math.round(-height / 2 + _bitmapData.height / 2));
		_rects.push(width);
		_rects.push(height);

		_transforms.length = 0;
		_transforms.push(Math.min(scale, 1));
		_transforms.push(0);
		_transforms.push(0);
		_transforms.push(Math.min(scale, 1));
		_transforms.push(0);
		_transforms.push(0);

		_shape.graphics.drawQuads(_rects, null, _transforms);

		BitmapDataUtil.resize(__bitmapData,
			Math.floor(Math.max(Math.min(width, FlxG.stage.stageWidth), __bitmapData.width)),
			Math.floor(Math.max(Math.min(height, FlxG.stage.stageHeight), __bitmapData.height))
		);
		BitmapDataUtil.draw(__bitmapData, _shape, false, true);

		smoothing = scale != Math.round(scale);
		scaleY = scaleX = Math.max(scale, 1);

		__setRenderDirty();
	}

	function onResize(_, _) refresh();

	override function get_bitmapData():BitmapData return _bitmapData;
	override function set_bitmapData(v:BitmapData):BitmapData {
		_bitmapData = v;
		refresh();
		return v;
	}

	override function get_visible():Bool return _visible;
	override function set_visible(v:Bool):Bool {
		super.set_visible(_visible = v);
		refresh();
		return v;
	}

	function set_pixelPerfect(v:Bool):Bool {
		pixelPerfect = v;
		refresh();
		return v;
	}

	override function __cleanup() {
		super.__cleanup();

		//stage.removeEventListener(Event.RESIZE, onResize);
		FlxG.signals.gameResized.remove(onResize);
		_shape.__cleanup();
		_rects = null;
		_transforms = null;
	}

	override function set_width(v:Float):Float return FlxG.stage.stageWidth;
	override function set_height(v:Float):Float return FlxG.stage.stageHeight;
	override function __getBounds(r:Rectangle, m:Matrix) r.setTo(0, 0, FlxG.stage.stageWidth, FlxG.stage.stageHeight);
	override function __getFilterBounds(r:Rectangle, m:Matrix) r.setTo(0, 0, FlxG.stage.stageWidth, FlxG.stage.stageHeight);
	override function __getRenderBounds(r:Rectangle, m:Matrix) r.setTo(0, 0, FlxG.stage.stageWidth, FlxG.stage.stageHeight);
}