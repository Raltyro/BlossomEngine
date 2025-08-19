package blossom.backend.util;

final class StringUtil {
	public static var intervalSizes:Array<String> = ["B", "KB", "MB", "GB"];
	public static function getSizeString(size:Float, from:Int = 0, precision:Int = 2):String {
		while (size >= 1024 && from < 3) {size /= 1024; from++;}
		return '${FlxMath.roundDecimal(size, precision)} ${intervalSizes[from]}';
	}
}