package blossom.bl3d;

import openfl.display.BlendMode;
import openfl.display.Shader;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

import flixel.math.FlxVelocity;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;

import blossom.backend.util.MathUtil;
import blossom.math.Vector3;

using flixel.util.FlxColorTransformUtil;

class Object3D extends FlxObject {
	private static final _tempMatrix3D:Matrix3D = new Matrix3D();
	private static final _tempVector3D:Vector3D = new Vector3D();
	private static final _tempVector3D2:Vector3D = new Vector3D();
	public static function composeMatrix3D(position:Vector3, ?rotation:Vector3, ?scale:Vector3, rotationOrder:RotationOrder = ZYX, ?pivot:Vector3, ?matrix3D:Matrix3D, prepend = true):Matrix3D {
		final matrix = (prepend ? _tempMatrix3D : matrix3D) ?? _tempMatrix3D;
		if (pivot != null) pivot.copyToFlash(_tempVector3D); else _tempVector3D.setTo(0, 0, 0);

		matrix.identity();

		if (rotation != null) {
			for (axis in rotationOrder) switch (axis) {
				case Z: if (Math.abs(rotation.z) > FlxMath.EPSILON) matrix.appendRotation(rotation.z, Vector3.Z_AXIS.copyToFlash(_tempVector3D2), _tempVector3D);
				case Y: if (Math.abs(rotation.y) > FlxMath.EPSILON) matrix.appendRotation(rotation.y, Vector3.Y_AXIS.copyToFlash(_tempVector3D2), _tempVector3D);
				case X: if (Math.abs(rotation.x) > FlxMath.EPSILON) matrix.appendRotation(rotation.x, Vector3.X_AXIS.copyToFlash(_tempVector3D2), _tempVector3D);
			}
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
}