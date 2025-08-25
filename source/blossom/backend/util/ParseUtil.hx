package blossom.backend.util;

import openfl.display.BlendMode;

final class ParseUtil {
	public static function parseColor(data:Dynamic, defaultColor = FlxColor.WHITE):FlxColor {
		if (data is String) return FlxColor.fromString(data);
		else if (data is Int) return FlxColor.fromInt(data);

		return defaultColor;
	}

	public static function parseBlendMode(data:Dynamic, ?defaultBlendMode:BlendMode):Null<BlendMode> {
		if (data is String) return @:privateAccess BlendMode.fromString((cast data).toLowerCase()) ?? defaultBlendMode;
		else if (data is Int) {
			#if openfljs
			return switch (data) {
				case 0: ADD;
				case 1: ALPHA;
				case 2: DARKEN;
				case 3: DIFFERENCE;
				case 4: ERASE;
				case 5: HARDLIGHT;
				case 6: INVERT;
				case 7: LAYER;
				case 8: LIGHTEN;
				case 9: MULTIPLY;
				case 10: NORMAL;
				case 11: OVERLAY;
				case 12: SCREEN;
				case 13: SHADER;
				case 14: SUBTRACT;

				case 15: EXCLUDE;
				case 16: SOFTLIGHT;
				case 17: BURN;
				case 18: DODGE;
				default: defaultBlendMode;
			}
			#else
			return cast data;
			#end
		}

		return defaultBlendMode;
	}

	public static function parseTimeChanges(data:Dynamic, ?result:Array<TimeChange>):Array<TimeChange> {
		if (result == null) result = [];
		// vanilla

		return result;
	}
}