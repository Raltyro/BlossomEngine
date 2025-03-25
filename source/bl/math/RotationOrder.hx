package bl.math;

enum abstract RotationOrder(String) from String to String {
	var ZYX = 'zyx';
	var XYZ = 'xyz';
	var YXZ = 'yxz';
	var YZX = 'yzx';
	var XZY = 'xzy';
	var ZXY = 'zxy';
}