package bl.util;

import openfl.display.BlendMode;

class ParseUtil {
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
				case 0: BlendMode.ADD;
				case 1: BlendMode.ALPHA;
				case 2: BlendMode.DARKEN;
				case 3: BlendMode.DIFFERENCE;
				case 4: BlendMode.ERASE;
				case 5: BlendMode.HARDLIGHT;
				case 6: BlendMode.INVERT;
				case 7: BlendMode.LAYER;
				case 8: BlendMode.LIGHTEN;
				case 9: BlendMode.MULTIPLY;
				case 10: BlendMode.NORMAL;
				case 11: BlendMode.OVERLAY;
				case 12: BlendMode.SCREEN;
				case 13: BlendMode.SHADER;
				case 14: BlendMode.SUBTRACT;

				case 15: BlendMode.EXCLUDE;
				case 16: BlendMode.SOFTLIGHT;
				case 17: BlendMode.BURN;
				case 18: BlendMode.DODGE;
				default: defaultBlendMode;
			}
			#else
			return cast data;
			#end
		}

		return defaultBlendMode;
	}

	public static function parseTimeChanges(data:Dynamic, result:Array<TimeChange>):Array<TimeChange> {
		if (result == null) result = [];
		// vanilla

		return result;
	}
}