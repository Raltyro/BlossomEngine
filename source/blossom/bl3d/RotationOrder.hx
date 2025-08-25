package blossom.bl3d;

enum abstract RotationAxes(UInt8) from UInt8 to UInt8 {
	var X = 0;
	var Y = 1;
	var Z = 2;
}

enum abstract RotationOrder(UInt8) from UInt8 to UInt8 {
	var XYZ = 0x012;
	var YXZ = 0x102;
	var YZX = 0x120;
	var XZY = 0x021;
	var ZXY = 0x201;
	var ZYX = 0x210;

	public var x(get, set):RotationAxes;
	public var y(get, set):RotationAxes;
	public var z(get, set):RotationAxes;

	inline function get_x():RotationAxes return this >> 8;
	inline function get_y():RotationAxes return this >> 4 & 15;
	inline function get_z():RotationAxes return this & 15;

	inline function set_x(axis:RotationAxes):RotationAxes {
		this = (this & 0x0ff) | (axis << 8);
		return axis;
	}

	inline function set_y(axis:RotationAxes):RotationAxes {
		this = (this & 0xf0f) | (axis << 4);
		return axis;
	}

	inline function set_z(axis:RotationAxes):RotationAxes {
		this = (this & 0xff0) | axis;
		return axis;
	}

	public inline function iterator() return new RotationOrderIterator(this);

	@:arrayAccess public inline function get(index:Int):RotationAxes return switch (index) {
		case 0: get_x();
		case 1: get_y();
		case 2: get_z();
		default: -1;
	}

	@:arrayAccess public inline function set(index:Int, value:RotationAxes):RotationAxes return switch (index) {
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