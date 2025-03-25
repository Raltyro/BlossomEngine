package bl.util;

import openfl.display.BitmapData;
import openfl.display.Shader;
import openfl.display.ShaderParameter;
import openfl.geom.Matrix3D;

class ShaderUtil {
	public static function parameterExists(shader:Shader, fields:Array<String>):Bool {
		for (field in fields) if (!Reflect.hasField(shader.data, field)) return false;
		return true;
	}

	public static function getParameterFloat(shader:Shader, field:String):Null<ShaderParameter<Float>> return Reflect.field(shader.data, field);
	public static function getParameterInt(shader:Shader, field:String):Null<ShaderParameter<Int>> return Reflect.field(shader.data, field);
	public static function getParameterBool(shader:Shader, field:String):Null<ShaderParameter<Bool>> return Reflect.field(shader.data, field);
	public static function getParameterSampler2D(shader:Shader, field:String):Null<ShaderParameter<BitmapData>> return Reflect.field(shader.data, field);

	public static function safeSetParameterMatrix3D(shader:Shader, field:String, matrix3D:Matrix3D) inline setParameterMatrix3D(getParameterFloat(shader, field), matrix3D);
	public static function setParameterMatrix3D(param:ShaderParameter<Float>, matrix3D:Matrix3D) {
		if (param == null) return;
		if (param.value == null) param.value = [for (v in matrix3D.rawData) v];
		else for (i in 0...16) param.value[i] = matrix3D.rawData[i];
	}

	public static function safeSetParameterColor(shader:Shader, field:String, color:FlxColor) inline setParameterColor(getParameterFloat(shader, field), color);
	public static function setParameterColor(param:ShaderParameter<Float>, color:FlxColor) {
		if (param == null) return;
		if (param.value == null) param.value = [];
		param.value[0] = color.redFloat;
		param.value[1] = color.greenFloat;
		param.value[2] = color.blueFloat;
	}
}