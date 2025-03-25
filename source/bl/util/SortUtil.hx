package bl.util;

import flixel.util.FlxSort;

import bl.data.Song.ChartCharacterID;
import bl.play.component.Character;
import bl.play.component.Stage.StageCharPos;

class SortUtil {
	public static function sortByTime<T>(array:Array<T>, reverse = false):Array<T> {
		array.sort((a:Dynamic, b:Dynamic) -> 
			return FlxSort.byValues(reverse ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.time, b.time)
		);
		return array;
	}

	public static function sortCharacterByLayer(array:Array<Character>, charPos:Map<ChartCharacterID, StageCharPos>, reverse = false):Array<Character> {
		array.sort((a, b) ->
			return FlxSort.byValues(reverse ? FlxSort.DESCENDING : FlxSort.ASCENDING,
				charPos.get(a.ID)?.layer ?? 0,
				charPos.get(b.ID)?.layer ?? 0
			)
		);
		return array;
	}
}