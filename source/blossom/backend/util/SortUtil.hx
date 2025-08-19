package blossom.backend.util;

import flixel.util.FlxSort;

class SortUtil {
	public static function sortByTime<T>(array:Array<T>, reverse = false):Array<T> {
		array.sort((a:Dynamic, b:Dynamic) -> 
			return FlxSort.byValues(reverse ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.time, b.time)
		);
		return array;
	}
}