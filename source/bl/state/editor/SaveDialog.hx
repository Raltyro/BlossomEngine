package bl.state.editor;

import haxe.io.Bytes;
import lime.ui.FileDialog;
import flixel.util.typeLimit.OneOfTwo;
import bl.util.FileUtil;

class SaveDialog extends flixel.FlxSubState {
	var content:OneOfTwo<String, Bytes>;
	var defaultPath:Null<String>;
	var title:Null<String>;
	var onSave:Void->Void;

	var prevPersistUpdate:Bool;

	public function new(content:OneOfTwo<String, Bytes>, ?defaultPath:String, ?title:String, ?onSave:Void->Void) {
		super();

		this.content = content;
		this.defaultPath = defaultPath;
		this.title = title;
		this.onSave = onSave;
	}

	override function create() {
		super.create();

		if (_parentState != null) {
			prevPersistUpdate = _parentState.persistentUpdate;
			_parentState.persistentUpdate = false;
		}

		var fileDialog = new FileDialog();
		fileDialog.onCancel.add(close.bind());
		fileDialog.onSelect.add((path:String) -> {
			FileUtil.saveFile(path, content);
			close();
			if (onSave != null) onSave();
		});
		fileDialog.browse(SAVE, Paths.ext(defaultPath), defaultPath, title);
	}

	override function close() {
		super.close();
		if (_parentState != null) _parentState.persistentUpdate = prevPersistUpdate;
	}
}