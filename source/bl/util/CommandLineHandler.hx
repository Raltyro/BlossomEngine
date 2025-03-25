package bl.util;

class CommandLineHandler {
	public static function parse(args:Array<String>):Bool {
		var i = -1, success = false;
		while (++i < args.length) if (args[i] != null) switch (args[i]) {
			case '-song':
				final song = args[++i];
				if (!(success = song != null)) break;

				PlayState.playSong(song);
			case '-songdiff':
				final song = args[++i];
				final diff = args[++i];
				if (!(success = (song != null && diff != null))) break;

				if (diff.charAt(0) == '-') diff = diff.substr(1);
				PlayState.playSong(song, diff);
			case '-char':
				final char = args[++i];
				if (!(success = char != null)) break;

				//FlxG.switchState(bl.state.editor.CharacterEditor.new.bind(char, false));
			case '-livereload':
			default:
				Sys.println('Unknown argument command (${args[1]})');
		}
		return success;
	}
}