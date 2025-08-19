package blossom.math;

enum abstract RotationOrder(UInt8) {
	var XYZ = 0x012;//'xyz';
	var YXZ = 0x102;//'yxz';
	var YZX = 0x120;//'yzx';
	var XZY = 0x021;//'xzy';
	var ZXY = 0x201;//'zxy';

	public var x(get, never):UInt8;
	public var y(get, never):UInt8;
	public var z(get, never):UInt8;

	var self(get, never):RotationOrder;
	inline function get_self() return cast this;

	inline function get_x() return self >> 8;
	inline function get_y() return self >> 4 & 3;
	inline function get_z() return self & 3;
}

enum abstract RotationAxes(UInt8) {
	var X = 0;
	var Y = 1;
	var Z = 2;
}