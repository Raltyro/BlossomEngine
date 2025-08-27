package blossom.math;

import openfl.geom.Vector3D;
#if !macro
import flixel.util.FlxStringUtil;
#if FLX_POINT_POOL
import flixel.util.FlxPool;
#end
#end

@:forward abstract Vector3(BaseVector3) to BaseVector3 from BaseVector3 {
	public static inline var EPSILON:Float = 0.0000001;
	public static inline var EPSILON_SQUARED:Float = EPSILON * EPSILON;

	static var _temp1 = new Vector3();
	static var _temp2 = new Vector3();
	static var _temp3 = new Vector3();

	public static var ZERO(get, never):Vector3; inline static function get_ZERO() return get(0, 0, 0);
	public static var ONE(get, never):Vector3; inline static function get_ONE() return get(1, 1, 1);
	public static var X_AXIS(get, never):Vector3; inline static function get_X_AXIS() return get(1, 0, 0);
	public static var Y_AXIS(get, never):Vector3; inline static function get_Y_AXIS() return get(0, 1, 0);
	public static var Z_AXIS(get, never):Vector3; inline static function get_Z_AXIS() return get(0, 0, 1);

	public static inline function get(x:Float = 0, y:Float = 0, z:Float = 0):Vector3
		return BaseVector3.get(x, y, z);

	public static inline function weak(x:Float = 0, y:Float = 0, z:Float = 0):Vector3
		return BaseVector3.weak(x, y, z);

	@:noCompletion @:op(A + B)
	static inline function plusOp(a:Vector3, b:Vector3):Vector3 {
		final result = get(a.x + b.x, a.y + a.y, a.z + a.z);
		a.putWeak(); b.putWeak();
		return result;
	}

	@:noCompletion @:op(A - B)
	static inline function minusOp(a:Vector3, b:Vector3):Vector3 {
		final result = get(a.x - b.x, a.y - a.y, a.z - a.z);
		a.putWeak(); b.putWeak();
		return result;
	}

	@:noCompletion @:op(A * B)
	static inline function scaleOp(a:Vector3, b:Vector3):Vector3 {
		final result = get(a.x * b.x, a.y * a.y, a.z * a.z);
		a.putWeak(); b.putWeak();
		return result;
	}

	@:noCompletion @:op(A / B)
	static inline function divideOp(a:Vector3, b:Vector3):Vector3 {
		final result = get(a.x / b.x, a.y / a.y, a.z / a.z);
		a.putWeak(); b.putWeak();
		return result;
	}

	@:noCompletion @:op(A += B)
	static inline function plusEqualOp(a:Vector3, b:Vector3):Vector3 return a.addVector3(b);

	@:noCompletion @:op(A -= B)
	static inline function minusEqualOp(a:Vector3, b:Vector3):Vector3 return a.subtractVector3(b);

	@:noCompletion @:op(A *= B)
	static inline function scaleEqualOp(a:Vector3, b:Float):Vector3 return a.scale(b);

	public var x(get, set):Float; inline function get_x() return this.x; inline function set_x(x:Float) return this.x = x;
	public var y(get, set):Float; inline function get_y() return this.y; inline function set_y(y:Float) return this.y = y;
	public var z(get, set):Float; inline function get_z() return this.z; inline function set_z(z:Float) return this.z = z;

	public var lengthSquared(get, never):Float; inline function get_lengthSquared() return x * x + y * y + z * z;
	public var length(get, set):Float;
	inline function get_length() return Math.sqrt(lengthSquared);
	inline function set_length(v:Float) {
		scale(1 / length * v);
		return v;
	}

	public var dx(get, never):Float;
	inline function get_dx():Float {
		if (isZero()) return 0.0;
		return x / length;
	}

	public var dy(get, never):Float;
	inline function get_dy():Float {
		if (isZero()) return 0.0;
		return y / length;
	}

	public var dz(get, never):Float;
	inline function get_dz():Float {
		if (isZero()) return 0.0;
		return z / length;
	}

	public inline function new(x:Float = 0, y:Float = 0, z:Float = 0) this = Vector3.get(x, y, z);
	public inline function clone(?v:Vector3):Vector3 return copyTo(v);
	public inline function set(x:Float = 0, y:Float = 0, z:Float = 0):Vector3 return this.set(x, y, z);

	public overload extern inline function add(x:Float = 0, y:Float = 0, z:Float = 0):Vector3 return set(this.x + x, this.y + y, this.z + z);
	public overload extern inline function add(v:Vector3):Vector3 {
		set(this.x + v.x, this.y + v.y, this.z + v.z);
		v.putWeak();
		return this;
	}
	public overload extern inline function add(v:Vector3D):Vector3 return set(this.x + v.x, this.y + v.y, this.z + v.z);
	public inline function addVector3(v:Vector3):Vector3 return add(v);
	public inline function addFromFlash(v:Vector3D):Vector3 return add(v);
	public inline function addToFlash(v:Vector3D):Vector3D {
		v.x += x;
		v.y += y;
		v.y += z;
		return v;
	}

	public overload extern inline function subtract(x:Float = 0, y:Float = 0, z:Float = 0):Vector3 return set(this.x - x, this.y - y, this.z - z);
	public overload extern inline function subtract(v:Vector3):Vector3 {
		set(this.x - v.x, this.y - v.y, this.z - v.z);
		v.putWeak();
		return this;
	}
	public overload extern inline function subtract(v:Vector3D):Vector3 return set(this.x - v.x, this.y - v.y, this.z - v.z);
	public inline function subtractVector3(v:Vector3):Vector3 return subtract(v);
	public inline function subtractFromFlash(v:Vector3D):Vector3 return subtract(v);
	public inline function subtractToFlash(v:Vector3D):Vector3D {
		v.x -= x;
		v.y -= y;
		v.y -= z;
		return v;
	}

	public overload extern inline function scale(x:Float, y:Float, z:Float):Vector3 return set(this.x * x, this.y * y, this.z * z);
	public overload extern inline function scale(amount:Float):Vector3 return set(this.x * amount, this.y * amount, this.z * amount);
	public overload extern inline function scale(v:Vector3):Vector3 {
		set(this.x * v.x, this.y * v.y, this.z * v.z);
		v.putWeak();
		return this;
	}
	public overload extern inline function scale(v:Vector3D):Vector3 return set(this.x * v.x, this.y * v.y, this.z * v.z);
	public inline function scaleVector3(v:Vector3):Vector3 return scale(v);
	public inline function scaleFromFlash(v:Vector3D):Vector3 return scale(v);
	public inline function scaleToFlash(v:Vector3D):Vector3D {
		v.x *= x;
		v.y *= y;
		v.z *= z;
		return v;
	}

	public inline function addNew(v:Vector3):Vector3 return clone().add(v);
	public inline function subtractNew(v:Vector3):Vector3 return clone().subtract(v);
	public overload extern inline function scaleNew(x:Float, y:Float, z:Float):Vector3 return clone().scale(x, y, z);
	public overload extern inline function scaleNew(amount:Float):Vector3 return clone().scale(amount);

	public overload extern inline function copyTo(?v:Vector3):Vector3 return (v ?? get()).set(x, y, z);
	public overload extern inline function copyTo(v:Vector3D):Vector3D {
		v.x = x;
		v.y = y;
		v.z = z;
		return v;
	}
	public inline function copyToFlash(?v:Vector3D):Vector3D return v != null ? copyTo(v) : new Vector3D(x, y, z);

	public overload extern inline function copyFrom(v:Vector3):Vector3 {
		set(v.x, v.y, v.z);
		v.putWeak();
		return this;
	}
	public overload extern inline function copyFrom(v:Vector3D):Vector3 return set(v.x, v.y, v.z);
	public inline function copyFromFlash(v:Vector3D):Vector3 return copyFrom(v);

	public inline function isZero():Bool return Math.abs(x) < EPSILON && Math.abs(y) < EPSILON && Math.abs(z) < EPSILON;
	public inline function isValid():Bool return !Math.isNaN(x) && !Math.isNaN(y) && !Math.isNaN(z) && Math.isFinite(x) && Math.isFinite(y)&& Math.isFinite(z);

	public inline function zero():Vector3 return set(0, 0, 0);
	public inline function negate():Vector3 return set(-x, -y, -z);
	public inline function floor():Vector3 return set(Math.floor(x), Math.floor(y), Math.floor(z));
	public inline function ceil():Vector3 return set(Math.ceil(x), Math.ceil(y), Math.ceil(z));
	public inline function round():Vector3 return set(Math.round(x), Math.round(y), Math.round(z));

	public inline function normalize():Vector3 {
		if (isZero()) return this;
		return scale(1 / length);
	}

	public inline function truncate(max:Float):Vector3 {
		length = Math.min(max, length);
		return this;
	}

	public inline function cross(v:Vector3, ?r:Vector3):Vector3 return crossProduct(v, r);
	public inline function crossProduct(v:Vector3, ?r:Vector3):Vector3 {
		if (r == null) r = get();
		r.set(y * v.z - z * v.y, z * v.x - x * v.z, x * v.y - y * v.x);
		v.putWeak();
		return r;
	}

	public inline function dot(v:Vector3):Float return dotProduct(v);
	public inline function dotProduct(v:Vector3):Float {
		final d = x * v.x + y * v.y + z * v.z;
		v.putWeak();
		return d;
	}

	//public inline function degreesTo();

	//@:deprecated("angleBetween is deprecated, use degreesTo instead")
	//public inline function angleBetween(v:Vector3):Float return degreesTo(v);

	@:arrayAccess public inline function getAtIndex(index:Int):Float return switch (index) {
		case 0: x;
		case 1: y;
		case 2: z;
		default: 0.0;
	}

	@:arrayAccess public inline function setAtIndex(index:Int, value:Float):Float return switch (index) {
		case 0: x = value;
		case 1: y = value;
		case 2: z = value;
		default: value;
	}
}

@:noCompletion
@:allow(blossom.math.Vector3)
class BaseVector3 implements IFlxPooled {
	#if (FLX_POINT_POOL && !macro)
	static var pool:FlxPool<BaseVector3> = new FlxPool(BaseVector3.new.bind(0, 0, 0));
	#end

	public static inline function get(x = 0.0, y = 0.0, z = 0.0):BaseVector3 {
		#if (FLX_POINT_POOL && !macro)
		var vector3 = pool.get().set(x, y, z);
		vector3._inPool = false;
		return vector3;
		#else
		return new BaseVector3(x, y, z);
		#end
	}

	public static inline function weak(x = 0.0, y = 0.0, z = 0.0):BaseVector3 {
		var vector3 = get(x, y, z);
		#if (FLX_POINT_POOL && !macro)
		vector3._weak = true;
		#end
		return vector3;
	}

	public var x(default, set):Float; function set_x(v:Float):Float return x = v;
	public var y(default, set):Float; function set_y(v:Float):Float return y = v;
	public var z(default, set):Float; function set_z(v:Float):Float return z = v;

	#if (FLX_POINT_POOL && !macro)
	var _weak:Bool = false;
	var _inPool:Bool = false;
	#end

	@:keep
	public inline function new(x = 0.0, y = 0.0, z = 0.0)
		set(x, y, z);

	public function set(x = 0.0, y = 0.0, z = 0.0):BaseVector3 {
		@:bypassAccessor this.x = x;
		@:bypassAccessor this.y = y;
		@:bypassAccessor this.z = z;
		return this;
	}

	public function put():Void {
		#if (FLX_POINT_POOL && !macro)
		if (!_inPool) {
			_inPool = true;
			_weak = false;
			pool.putUnsafe(this);
		}
		#end
	}

	public inline function putWeak()
		#if (FLX_POINT_POOL && !macro)
		if (_weak) put();
		#end

	public inline function equals(vector3:BaseVector3):Bool {
		var result = FlxMath.equal(x, vector3.x) && FlxMath.equal(y, vector3.y) && FlxMath.equal(z, vector3.z);
		vector3.putWeak();
		return result;
	}

	public function destroy() {}

	public inline function toString():String
		#if !macro
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("x", x),
			LabelValuePair.weak("y", y),
			LabelValuePair.weak("z", z)
		]);
		#else
		return '(x: $x | y: $y | z: $z)';
		#end
}

class CallbackVector3 extends BaseVector3 {
	var _setCallback:Vector3->Void;

	public function new(setCallback:Vector3->Void) {
		super();
		_setCallback = setCallback;
	}

	override public function set(x = 0.0, y = 0.0, z = 0.0):CallbackVector3 {
		super.set(x, y, z);
		if (_setCallback != null) _setCallback(this);
		return this;
	}

	override function set_x(value:Float):Float {
		super.set_x(value);
		if (_setCallback != null) _setCallback(this);
		return value;
	}

	override function set_y(value:Float):Float {
		super.set_y(value);
		if (_setCallback != null) _setCallback(this);
		return value;
	}

	override function set_z(value:Float):Float {
		super.set_z(value);
		if (_setCallback != null) _setCallback(this);
		return value;
	}

	override public function destroy() {
		super.destroy();
		_setCallback = null;
	}

	override public function put() {} // don't pool
}