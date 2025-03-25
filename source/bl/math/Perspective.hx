package bl.math;

import openfl.display.Shader;
import openfl.geom.Matrix3D;

import flixel.math.FlxAngle;
import flixel.util.FlxDestroyUtil;

import bl.object.Object3D;
import bl.util.ShaderUtil;

class Perspective implements IFlxDestroyable {
	/**
	 * Projection matrix that'll be used for to project world space coordinates to screen.
	 */
	public var projectionMatrix:Matrix3D = new Matrix3D();

	/**
	 * View Matrix that'll be used for to modify world position and rotation.
	 */
	public var viewMatrix:Matrix3D = new Matrix3D();

	/**
	 * Perspective Up Vector.
	 */
	public var upVector:Vector3 = Vector3.Y_AXIS;

	/**
	 * Perspective Look At Vector.
	 */
	public var lookVector:Vector3 = Vector3.Z_AXIS;

	/**
	 * X position of the world position view.
	 */
	public var x:Float;

	/**
	 * Y position of the world position view.
	 */
	public var y:Float;

	/**
	 * Z position of the world position view.
	 */
	public var z:Float;

	/**
	 * Rotation of the world position view.
	 */
	public var rotation:Vector3 = Vector3.get();

	/**
	 * Rotation order for this Perspective view.
	 */
	public var rotationOrder:RotationOrder = ZYX;

	/**
	 * Scaling of this perspective view.
	 */
	public var scale:Vector3 = Vector3.ONE;

	/**
	 * How much the depth gets affected to nearest coordinates.
	 */
	public var near:Float = -512.0;

	/**
	 * How much the depth gets affected to farest coordinates.
	 */
	public var far:Float = 1024.0;

	/**
	 * Determines how strong the perspective transformation and distortion apply.
	 */
	public var fieldOfView:Float;

	/**
	 * Determines how much length the focal can see. (?)
	 */
	public var focalLength(get, set):Float;

	/**
	 * 
	 */
	public var useLookAt:Bool = false;

	var _focalLength:Float;
	var _focalLengthLastFOV:Float;
	var _forward:Vector3;
	var _right:Vector3;
	var _up:Vector3;

	public function new(fov = 90.0, x = 0.0, y = 0.0, z = 0.0) {
		this.fieldOfView = fov;
		this.x = x;
		this.y = y;
		this.z = z;

		updateMatrix();
	}

	public function destroy() {
		rotation = FlxDestroyUtil.put(rotation);
		scale = FlxDestroyUtil.put(scale);
		upVector = FlxDestroyUtil.put(upVector);
		lookVector = FlxDestroyUtil.put(lookVector);
		_forward = FlxDestroyUtil.put(_forward);
		_right = FlxDestroyUtil.put(_right);
		_up = FlxDestroyUtil.put(_up);
		projectionMatrix = null;
		viewMatrix = null;
	}

	public function setPosition(x = 0.0, y = 0.0, z = 0.0):Perspective {
		this.x = x;
		this.y = y;
		this.z = z;
		return this;
	}

	public function applyShaderParameters(shader:Shader) {
		ShaderUtil.safeSetParameterMatrix3D(shader, 'projectionMatrix', projectionMatrix);
		ShaderUtil.safeSetParameterMatrix3D(shader, 'viewMatrix', viewMatrix);
	}

	public function updateMatrix() {
		updateProjectionMatrix();
		updateViewMatrix();
	}

	public function updateProjectionMatrix() {
		//projectionMatrix.rawData[5] = projectionMatrix.rawData[0] = focalLength;
		//projectionMatrix.rawData[11] = 1.0;
		//projectionMatrix.rawData[15] = 0.0;

		final z = 1.0 / (far - near);
		projectionMatrix.rawData[10] = -2.0 * z;
		projectionMatrix.rawData[14] = -(near + far) * z;
		projectionMatrix.rawData[11] = 1.0 / focalLength;
	}

	public function updateViewMatrix() {
		if (useLookAt) {
			(_forward = _forward ?? Vector3.get()).copyFrom(lookVector).subtract(x, y, z).normalize();
			(_right = _right ?? Vector3.get()).copyFrom(upVector).crossProduct(_forward).normalize();
			(_up = _up ?? Vector3.get()).copyFrom(_forward).crossProduct(_right);

			viewMatrix.rawData[15] = viewMatrix.rawData[11] = viewMatrix.rawData[7] = viewMatrix.rawData[3] = 0.0;
			viewMatrix.rawData[0] = _right.x;
			viewMatrix.rawData[1] = _up.x;
			viewMatrix.rawData[2] = _forward.x;
			viewMatrix.rawData[4] = _right.y;
			viewMatrix.rawData[5] = _up.y;
			viewMatrix.rawData[6] = _forward.y;
			viewMatrix.rawData[8] = _right.z;
			viewMatrix.rawData[9] = _up.z;
			viewMatrix.rawData[10] = _forward.z;
			viewMatrix.rawData[12] = _right.x * -x + _right.y * -y + _right.z * -z;
			viewMatrix.rawData[13] = _up.x * -x + _up.y * -y + _up.z * -z;
			viewMatrix.rawData[14] = _forward.x * -x + _forward.y * -y + _forward.z * -z;
		}
		else {
			Object3D.composeMatrix3D(Vector3.weak(-x, -y, -z), rotation, scale, rotationOrder, viewMatrix, false);
		}
	}

	function get_focalLength():Float {
		return if (_focalLengthLastFOV == fieldOfView) _focalLength
			else _focalLength = 1.0 / Math.tan(((_focalLengthLastFOV = fieldOfView) * FlxAngle.TO_RAD) * 0.5);
	}

	function set_focalLength(value:Float):Float {
		if (value == _focalLength) return _focalLength;
		else {
			fieldOfView = 2 * Math.atan(1 / value) * FlxAngle.TO_DEG;
			return _focalLength = value;
		}
	}
}