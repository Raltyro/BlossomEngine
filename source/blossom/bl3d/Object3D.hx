package blossom.bl3d;

import openfl.display.BlendMode;
import openfl.display.Shader;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

import flixel.math.FlxVelocity;
import flixel.util.FlxAxes;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;

import blossom.bl3d.Container3D.TypedContainer3D;
import blossom.math.Vector3;

using flixel.util.FlxColorTransformUtil;

class Object3D extends FlxObject {
	private static final _tempMatrix3D:Matrix3D = new Matrix3D();
	private static final _tempVector3D:Vector3D = new Vector3D();
	private static final _tempVector3D2:Vector3D = new Vector3D();
	public static function composeMatrix3D(position:Vector3, ?rotation:Vector3, ?scale:Vector3, rotationOrder:RotationOrder = DEFAULT, ?pivot:Vector3, ?matrix3D:Matrix3D, prepend = true):Matrix3D {
		final matrix = (matrix3D == null || prepend) ? _tempMatrix3D : matrix3D;
		if (pivot != null) pivot.copyToFlash(_tempVector3D); else _tempVector3D.setTo(0, 0, 0);

		matrix.identity();

		if (rotation != null) {
			for (axis in rotationOrder) if (Math.abs(rotation[axis]) > FlxMath.EPSILON) matrix.appendRotation(rotation[axis], axis.to(_tempVector3D2), _tempVector3D);
			rotation.putWeak();
		}

		if (scale != null) {
			matrix.rawData[0] *= scale.x;
			matrix.rawData[1] *= scale.x;
			matrix.rawData[2] *= scale.x;
			matrix.rawData[12] = (matrix.rawData[12] - _tempVector3D.x) * scale.x + _tempVector3D.x;
			matrix.rawData[4] *= scale.y;
			matrix.rawData[5] *= scale.y;
			matrix.rawData[6] *= scale.y;
			matrix.rawData[13] = (matrix.rawData[13] - _tempVector3D.y) * scale.y + _tempVector3D.y;
			matrix.rawData[8] *= scale.z;
			matrix.rawData[9] *= scale.z;
			matrix.rawData[10] *= scale.z;
			matrix.rawData[14] = (matrix.rawData[14] - _tempVector3D.z) * scale.z + _tempVector3D.z;

			scale.putWeak();
		}

		matrix.appendTranslation(position.x, position.y, position.z);
		position.putWeak();

		if (matrix3D == null) return _tempMatrix3D.clone();
		else if (prepend) matrix3D.prepend(_tempMatrix3D);

		return matrix3D;
	}

	public var angularVelocity3D:Vector3;
	public var angularMaxVelocity3D:Vector3;
	public var angularAcceleration3D:Vector3;
	public var angularDrag3D:Vector3;

	public var velocity3D:Vector3;
	public var maxVelocity3D:Vector3;
	public var acceleration3D:Vector3;
	public var drag3D:Vector3;

	public var antialiasing:Bool = FlxSprite.defaultAntialiasing;
	public var alpha(default, set):Float = 1.0;
	public var blend(default, set):BlendMode;
	public var color(default, set):FlxColor = FlxColor.WHITE;
	public var colorTransform(default, null):ColorTransform;
	public var useColorTransform(default, null):Bool = false;

	public var z(default, set):Float;
	@:isVar public var depth(get, set):Float;

	public var rotation(default, null):Vector3;
	public var rotationOrder:RotationOrder = DEFAULT;

	public var origin(default, null):Vector3;
	public var offset(default, null):Vector3;
	public var scale(default, null):Vector3;

	public var flipX(default, set):Bool = false;
	public var flipY(default, set):Bool = false;
	public var flipZ(default, set):Bool = false;

	public var perspective:Perspective;
	public var useParentPerspective:Bool = true;

	var _facingHorizontalMult:Int = 1;
	var _facingVerticalMult:Int = 1;
	var _facingDepthMult:Int = 1;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, width:Float = 0, height:Float = 0, depth:Float = 0) {
		this.z = z;
		this.depth = depth;
		super(x, y);
	}

	inline function getVector3(v:Vector3, weak:Bool) return v ?? (weak ? Vector3.weak() : Vector3.get());
	inline public function getPosition3D(?v:Vector3, weak = false):Vector3 return getVector3(v, weak).set(x, y, z);
	inline public function getSize3D(?v:Vector3, weak = false):Vector3 return getVector3(v, weak).set(width, height, depth);
	inline public function getScale3D(?v:Vector3, weak = false):Vector3 return getVector3(v, weak).set(scale.x * _facingHorizontalMult, scale.y * _facingVerticalMult, scale.z * _facingDepthMult);

	override function initVars() {
		rotation = Vector3.get();
		origin = Vector3.get();
		offset = Vector3.get();
		scale = Vector3.ONE;

		colorTransform = new ColorTransform();

		super.initVars();
	}

	override function initMotionVars() {
		angularVelocity3D = Vector3.get();
		angularMaxVelocity3D = Vector3.get();
		angularAcceleration3D = Vector3.get();
		angularDrag3D = Vector3.get();

		velocity3D = Vector3.get();
		maxVelocity3D = Vector3.get();
		acceleration3D = Vector3.get();
		drag3D = Vector3.get();

		super.initMotionVars();
	}

	override function destroy() {
		super.destroy();

		rotation = FlxDestroyUtil.put(rotation);

		angularVelocity3D = FlxDestroyUtil.put(angularVelocity3D);
		angularMaxVelocity3D = FlxDestroyUtil.put(angularMaxVelocity3D);
		angularAcceleration3D = FlxDestroyUtil.put(angularAcceleration3D);
		angularDrag3D = FlxDestroyUtil.put(angularDrag3D);

		velocity3D = FlxDestroyUtil.put(velocity3D);
		maxVelocity3D = FlxDestroyUtil.put(maxVelocity3D);
		acceleration3D = FlxDestroyUtil.put(acceleration3D);
		drag3D = FlxDestroyUtil.put(drag3D);

		perspective = FlxDestroyUtil.destroy(perspective);

		colorTransform = null;
	}

	override function updateMotion(elapsed:Float) {
		super.updateMotion(elapsed);

		final velocityDelta = 0.5 * (FlxVelocity.computeVelocity(angularVelocity3D.x, angularAcceleration3D.x, angularDrag3D.x, angularMaxVelocity3D.x, elapsed) - angularVelocity3D.x);
		rotation.x += (angularVelocity3D.x += velocityDelta) * elapsed;
		angularVelocity3D.x += velocityDelta;

		final velocityDelta = 0.5 * (FlxVelocity.computeVelocity(angularVelocity3D.y, angularAcceleration3D.y, angularDrag3D.y, angularMaxVelocity3D.y, elapsed) - angularVelocity3D.y);
		rotation.y += (angularVelocity3D.y += velocityDelta) * elapsed;
		angularVelocity3D.y += velocityDelta;

		final velocityDelta = 0.5 * (FlxVelocity.computeVelocity(angularVelocity3D.z, angularAcceleration3D.z, angularDrag3D.z, angularMaxVelocity3D.z, elapsed) - angularVelocity3D.z);
		rotation.z += (angularVelocity3D.z += velocityDelta) * elapsed;
		angularVelocity3D.z += velocityDelta;

		final velocityDelta = 0.5 * (FlxVelocity.computeVelocity(velocity3D.x, acceleration3D.x, drag3D.x, maxVelocity3D.x, elapsed) - velocity3D.x);
		x += (velocity3D.x += velocityDelta) * elapsed;
		velocity3D.x += velocityDelta;

		final velocityDelta = 0.5 * (FlxVelocity.computeVelocity(velocity3D.y, acceleration3D.y, drag3D.y, maxVelocity3D.y, elapsed) - velocity3D.y);
		y += (velocity3D.y += velocityDelta) * elapsed;
		velocity3D.y += velocityDelta;

		final velocityDelta = 0.5 * (FlxVelocity.computeVelocity(velocity3D.z, acceleration3D.z, drag3D.z, maxVelocity3D.z, elapsed) - velocity3D.z);
		z += (velocity3D.z += velocityDelta) * elapsed;
		velocity3D.z += velocityDelta;
	}

	override function screenCenter(axes:FlxAxes = XY):Object3D {
		if (axes.x) x = FlxG.width / 2;
		if (axes.y) y = FlxG.height / 2;
		z = 0;

		return this;
	}

	public function getPerspective(?camera:FlxCamera):Perspective {
		if (useParentPerspective && container is TypedContainer3D) {
			final parent = (cast container:Container3D).parentObject;
			if (parent != null) return parent.getPerspective(camera);
		}
		if (camera is BLCamera) return cast(camera, BLCamera).perspective;
		return perspective;
	}

	override function isOnScreen(?camera:FlxCamera):Bool {
		return true;
	}

	@:haxe.warning("-WDeprecated")
	public function setColorTransform(redMultiplier = 1.0, greenMultiplier = 1.0, blueMultiplier = 1.0, alphaMultiplier = 1.0,
			redOffset = 0.0, greenOffset = 0.0, blueOffset = 0.0, alphaOffset = 0.0)
	{
		if (colorTransform == null) colorTransform = new ColorTransform();

		@:bypassAccessor color = FlxColor.fromRGBFloat(redMultiplier, greenMultiplier, blueMultiplier, 1.0);
		@:bypassAccessor alpha = FlxMath.bound(alphaMultiplier, 0, 1);

		colorTransform.setMultipliers(redMultiplier, greenMultiplier, blueMultiplier, alpha);
		colorTransform.setOffsets(redOffset, greenOffset, blueOffset, alphaOffset);
		useColorTransform = hasColorTransformRaw();
	}

	@:haxe.warning("-WDeprecated")
	function updateColorTransform() {
		if (colorTransform == null) colorTransform = new ColorTransform();

		colorTransform.setMultipliers(color.redFloat, color.greenFloat, color.blueFloat, alpha);
		useColorTransform = hasColorTransformRaw();
	}

	@:haxe.warning("-WDeprecated")
	public function hasColorTransform()
		return useColorTransform || hasColorTransformRaw();

	function hasColorTransformRaw()
		return alpha != 1 || color.rgb != 0xffffff || colorTransform.hasRGBAOffsets();

	function set_alpha(value:Float):Float {
		if (alpha == (alpha = FlxMath.bound(value, 0, 1))) return value;
		updateColorTransform();
		return color;
	}


	function set_color(value:FlxColor):Int {
		if (color == (color = value)) return value;
		updateColorTransform();
		return color;
	}

	function set_blend(value:BlendMode):BlendMode return blend = value;

	function set_flipX(value:Bool) {
		_facingHorizontalMult = value ? -1 : 1;
		return flipX = value;
	}

	function set_flipY(value:Bool) {
		_facingVerticalMult = value ? -1 : 1;
		return flipY = value;
	}

	function set_flipZ(value:Bool) {
		_facingDepthMult = value ? -1 : 1;
		return flipZ = value;
	}

	function set_z(value:Float):Float return z = value;

	function set_depth(value:Float):Float {
		#if FLX_DEBUG
		if (value < 0) {
			FlxG.log.warn("An object's depth cannot be smaller than 0. Use offset for object3Ds to control the hitbox position!");
			return value;
		}
		#end

		return depth = value;
	}

	function get_depth():Float return depth;
}