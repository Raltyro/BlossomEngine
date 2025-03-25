package bl.graphic;

import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.geom.ColorTransform;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxImageFrame;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxContainer;
import flixel.math.FlxRect;
import flixel.math.FlxMatrix;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;

import bl.util.BitmapDataUtil;

// TODO: Capture shit in like world space instead of camera space.
// Done? no origin, offset yet.

// Captures objects behind in the camera it's in.
// Gotchas: https://craftedcart.gitlab.io/notitg_docs/lua_api/actor_frame_texture.html

@:access(openfl.display.Graphics)
@:access(flixel.graphics.FlxGraphic)
@:access(flixel.FlxCamera)
@:access(flixel.FlxGame)
class SpriteFrameBuffer extends FlxObject {
	public var buffer:BitmapData;

	public var captureAll:Bool = false;
	public var captureFilters:Bool = false;
	public var clearBehind:Bool = false;
	public var worldSpace:Bool = false;
	public var preserve:Bool = true;
	public var fixDraw:Bool = false;

	public var isolation:FlxContainer;
	public var members(get, null):Array<FlxBasic>; inline function get_members() return isolation.members;

	public var frameRate:Float;
	public var frameDuration(get, set):Float;

	function get_frameDuration():Float return frameRate < 0 ? 0 : 1 / frameRate;
	function set_frameDuration(value:Float):Float {
		frameRate = 1 / value;
		return value;
	}

	public var antialiasing:Bool = FlxSprite.defaultAntialiasing;
	public var dirty:Bool = true;

	public var graphic(default, null):FlxGraphic;
	public var frames(default, null):FlxFramesCollection;
	public var frame(default, null):FlxFrame;
	public var frameWidth(default, null):Int = 0;
	public var frameHeight(default, null):Int = 0;
	
	//public var alpha(default, set):Float = 1.0;

	public var flipX:Bool = false;
	public var flipY:Bool = false;

	//public var origin(default, null):FlxPoint;
	//public var offset(default, null):FlxPoint;
	public var scale(default, null):FlxPoint;

	//public var color(default, set):FlxColor = 0xffffff;
	public var colorTransform(default, null):ColorTransform;
	public var useColorTransform(default, null):Bool = false;

	var _frameTimer:Float = 0;
	var _matrix:FlxMatrix;
	var _graphics:Graphics;
	var _drawing:Bool;

	public function new(?x = 0.0, ?y = 0.0, frameRate = -1.0, ?buffer:BitmapData, ?width:Int, ?height:Int) {
		this.buffer = buffer ?? BufferPool.get(frameWidth = width ?? FlxG.width, frameHeight = height ?? FlxG.height);
		super(x, y, frameWidth, frameHeight);

		this.frameRate = frameRate;

		(graphic = new FlxGraphic('SpriteFrameBuffer$ID', this.buffer)).destroyOnNoUse = false;
		frames = graphic.imageFrame = FlxImageFrame.fromGraphic(graphic);
		FlxG.bitmap.addGraphic(graphic);

		frame = frames.frames[0];
	}

	@:noCompletion
	override function initVars() {
		super.initVars();

		isolation = new FlxContainer();

		//offset = FlxPoint.get();
		//origin = FlxPoint.get();
		scale = FlxPoint.get(1, 1);
		_matrix = new FlxMatrix();
		colorTransform = new ColorTransform();

		_graphics = new Graphics(null);
	}

	inline public function add(basic:FlxBasic):FlxBasic return isolation.add(basic);
	inline public function insert(position:Int, basic:FlxBasic):FlxBasic return isolation.insert(position, basic);
	inline public function remove(basic:FlxBasic, splice = false):FlxBasic return isolation.remove(basic, splice);
	inline public function replace(oldObject:FlxBasic, newObject:FlxBasic):FlxBasic return isolation.replace(oldObject, newObject);
	inline public function recycle(?objectClass:Class<FlxBasic>, ?objectFactory:Void->FlxBasic, force = false, revive = true):FlxBasic
		return isolation.recycle(objectClass, objectFactory, force, revive);

	inline public function sort(func:(Int,FlxBasic,FlxBasic)->Int, order = FlxSort.ASCENDING) isolation.sort(func, order);
	inline public function clear() isolation.clear();

	public inline function resetSizeFromFrame() {
		width = frameWidth;
		height = frameHeight;
	}

	public function updateHitbox() {
		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
		//offset.set(-0.5 * (width - frameWidth), -0.5 * (height - frameHeight));
		//centerOrigin();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		isolation.update(elapsed);

		final duration = frameDuration;
		if ((_frameTimer += elapsed) > duration) {
			_frameTimer = Math.min(_frameTimer - duration, duration);
			dirty = true;
		}
	}

	override function draw() {
		if (_drawing) capturePost(cast camera);
		else if (dirty) {
			if (container != null || members.length != 0) {
				final camera:BLCamera = cast camera;
				if (camera is BLCamera) capture(camera);
				else
					FlxG.log.warn('SpriteFrameBuffer must be in BLCamera!');
			}
			else
				FlxG.log.warn('SpriteFrameBuffer must be in a container or FlxState!');

			dirty = false;
		}

		if (!_drawing) {
			if (clearBehind) {
				camera.clearDrawStack();
				camera.canvas.graphics.clear();
			}
			#if FLX_DEBUG super.draw(); #end
		}
	}

	// Use dirty to force capture the SFB
	private function capture(camera:BLCamera) @:privateAccess {
		_drawing = true;

		final x = camera.scroll.x, y = camera.scroll.y, angle = camera.angle, sx = camera.scaleX, sy = camera.scaleY;
		final cameraGraphics = camera.canvas.graphics;

		//camera.drawScreen(false, true);
		camera.continueDraw();
		(camera.canvas.__graphics = _graphics).__owner = camera.canvas;
		_graphics.clear();
		#if FLX_DEBUG camera.debugLayer.graphics.clear(); #end

		if (worldSpace) {
			camera.scroll.set(this.x, this.y);
			camera.angle = this.angle;
			camera.setScale(scale.x, scale.y);
		}
		else {
			camera.scroll.add(this.x, this.y);
			camera.angle += this.angle;
			camera.setScale(sx * scale.x, sy * scale.y);
		}

		if (_cameras == null) _cameras = [camera];
		else {
			_cameras.resize(0);
			_cameras[0] = camera;
		}

		final oldDefaultCameras = FlxCamera._defaultCameras;
		FlxCamera._defaultCameras = _cameras;

		if (fixDraw && members.length == 0) {
			var idx = -1;
			for (i => basic in container.members) if (basic == this) {
				idx = i + 1;
				break;
			}

			final spliced = container.members.splice(idx, container.members.length - idx);
			container.draw();
			for (basic in spliced) container.members.push(basic);
		}
		else {
			for (basic in (members.length == 0 ? container.members : members)) {
				if (basic == this) {
					if (captureAll) continue;
					else break;
				}
				else if (basic != null && basic.exists && basic.visible && basic.getCamerasLegacy().contains(camera))
					basic.draw();
			}
			capturePost(camera);
		}

		FlxCamera._defaultCameras = oldDefaultCameras;

		camera.canvas.__graphics = cameraGraphics;
		camera.scroll.set(x, y);
		camera.angle = angle;
		camera.setScale(sx, sy);
	}

	private function capturePost(camera:BLCamera) {
		_drawing = false;

		if (!preserve) BitmapDataUtil.clear(buffer);
		camera.grabScreen(buffer, captureFilters);
	}

	public function resize(width:Int, height:Int) {
		BitmapDataUtil.resize(buffer, frameWidth = width, frameHeight = height);
		frame.sourceSize.set(width, height);
		frame.frame = frame.frame.set(0, 0, width, height);
	}

	@:noCompletion
	override function destroy() {
		super.destroy();

		//offset = FlxDestroyUtil.put(offset);
		//origin = FlxDestroyUtil.put(origin);
		scale = FlxDestroyUtil.put(scale);
		buffer = BufferPool.put(buffer);
		frames = FlxDestroyUtil.destroy(frames);
		isolation = FlxDestroyUtil.destroy(isolation);
		if (graphic != null) Reflect.setField(graphic, 'bitmap', null); // bypassAccessor here doesnt work for some reason
		graphic = FlxDestroyUtil.destroy(graphic);

		if (_graphics != null) _graphics.__cleanup();
		_graphics = null;

		frame = null;
	}

	#if FLX_DEBUG
	override function drawDebugBoundingBoxColor(gfx:Graphics, rect:FlxRect, color:FlxColor) {
		// fill static graphics object with square shape
		gfx.lineStyle(1, color, 0.75);
		gfx.drawRect(rect.x + 0.5, rect.y + 0.5, rect.width - 1.0, rect.height - 1.0);
	}
	#end
}