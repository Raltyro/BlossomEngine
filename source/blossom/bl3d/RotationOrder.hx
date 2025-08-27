package blossom.bl3d;

import openfl.geom.Vector3D;
import blossom.math.Vector3;

enum abstract RotationAxis(UInt8) from UInt8 to UInt8 {
	var X = 0;
	var Y = 1;
	var Z = 2;

	public overload extern inline function to(?v:Vector3):Vector3 return switch (this) {
		case X: v == null ? v.set(1, 0, 0) : Vector3.X_AXIS;
		case Y: v == null ? v.set(0, 1, 0) : Vector3.Y_AXIS;
		case Z: v == null ? v.set(0, 0, 1) : Vector3.Z_AXIS;
		default: v == null ? v.set(0, 0, 0) : Vector3.ZERO;
	}

	public overload extern inline function to(v:Vector3D):Vector3D switch (this) {
		case X:
			v.setTo(1, 0, 0);
			return v;
		case Y:
			v.setTo(0, 1, 0);
			return v;
		case Z:
			v.setTo(0, 0, 1);
			return v;
		default:
			v.setTo(0, 0, 0);
			return v;
	}

	public inline function toVector3(?v:Vector3):Vector3 return to(v);
	public inline function toFlash(v:Vector3D):Vector3D return to(v);
}

enum abstract RotationOrder(UInt8) from UInt8 to UInt8 {
	var DEFAULT = ZYX;

	var XYZ = 0x012;
	var YXZ = 0x102;
	var YZX = 0x120;
	var XZY = 0x021;
	var ZXY = 0x201;
	var ZYX = 0x210;

	public var x(get, set):RotationAxis;
	public var y(get, set):RotationAxis;
	public var z(get, set):RotationAxis;

	inline function get_x():RotationAxis return this >> 8;
	inline function get_y():RotationAxis return this >> 4 & 15;
	inline function get_z():RotationAxis return this & 15;

	inline function set_x(axis:RotationAxis):RotationAxis {
		this = (this & 0x0ff) | (axis << 8);
		return axis;
	}

	inline function set_y(axis:RotationAxis):RotationAxis {
		this = (this & 0xf0f) | (axis << 4);
		return axis;
	}

	inline function set_z(axis:RotationAxis):RotationAxis {
		this = (this & 0xff0) | axis;
		return axis;
	}

	public inline function iterator() return new RotationOrderIterator(this);

	@:arrayAccess public inline function get(index:Int):RotationAxis return switch (index) {
		case 0: get_x();
		case 1: get_y();
		case 2: get_z();
		default: -1;
	}

	@:arrayAccess public inline function set(index:Int, value:RotationAxis):RotationAxis return switch (index) {
		case 0: set_x(value);
		case 1: set_y(value);
		case 2: set_z(value);
		default: value;
	}
}

final class RotationOrderIterator {
	final rotationOrder:RotationOrder;
	var current:Int = 0;

	#if !hl inline #end public function new(rotationOrder:RotationOrder) this.rotationOrder = rotationOrder;
	#if !hl inline #end public function hasNext() return current < 3;
	#if !hl inline #end public function next() return switch (current++) {
		case 0: rotationOrder.x;
		case 1: rotationOrder.y;
		case 2: rotationOrder.z;
		default: -1;
	}
}