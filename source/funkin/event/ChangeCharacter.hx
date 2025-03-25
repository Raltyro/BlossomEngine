package funkin.event;

class ChangeCharacter extends PlayEvent {
	public static var classEventID = 'change-character';
	public static var classEventName = 'Change Character';

	public static function preload(data:ChartEvent) {
		if (data.params == null || !(data.params[1] is String)) return Future.withValue(true);
		else return Character.preloadCharacter(cast data.params[1]);
	}

	override function trigger(data:ChartEvent) {
		if (data.params == null || !(data.params[1] is String)) return;

		final characterID:String = data.params[1];

		var idx = null;
		if (data.params[0] is Int) {
			if (data.params[2] == true) idx = data.params[0];
			else {
				final id:Int = data.params[0];
				for (i => character in playState.characters) {
					if (character.ID == id) {
						idx = i;
						break;
					}
				}
			}
		}
		else if (data.params[0] is String) {
			final str:String = data.params[0];
			switch (str.charAt(0).toLowerCase()) {
				case 'b': idx = playState.characters.indexOf(playState.bf);
				case 'g': idx = playState.characters.indexOf(playState.gf);
				case 'd': idx = playState.characters.indexOf(playState.dad);
			}
		}

		if (idx > playState.characters.length || idx < 0) return trace('Invalid Character Index $idx');

		var character = Character.make(characterID);
		if (character == null) return trace('Invalid Character $characterID');

		if (idx == playState.characters.length) playState.insertCharacter(character);
		else playState.replaceCharacter(idx, character);
	}
}