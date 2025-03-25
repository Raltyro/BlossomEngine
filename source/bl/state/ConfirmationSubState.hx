package bl.state;

import bl.input.Controls.Control;

using StringTools;

class ConfirmationSubState extends BLState {
	public var text(default, set):String;
	public var inputText(default, set):String;

	var allowInput:Bool;
	var label:BLText;
	var inputLabel:BLText;
	var onConfirm:Void->Void;
	var onCancel:Void->Void;
	var prevPersistUpdate:Bool;

	public function new(text = 'Are you sure?', inputText = 'Press %ACCEPT to continue | Press %BACK to cancel',
		?onConfirm:Void->Void, ?onCancel:Void->Void
	) {
		super();

		this.text = text;
		this.inputText = inputText;
		this.onConfirm = onConfirm;
		this.onCancel = onCancel;
	}

	override function create() {
		super.create();

		if (parent != null) {
			prevPersistUpdate = parent.persistentUpdate;
			parent.persistentUpdate = false;
		}

		add(label = new BLText('', 24));
		add(inputLabel = new BLText('', 18));
		text = text;
		inputText = inputText;
		inputLabel.alpha = label.alpha = 0;

		FlxTween.color(0.8, bgColor = FlxColor.TRANSPARENT, FlxColor.fromRGB(0, 0, 0, 153), {ease: FlxEase.quartOut,
			onUpdate: (t) -> bgColor = cast(t, ColorTween).color, onComplete: (_) -> allowInput = true});
		FlxTween.tween(label, {alpha: 1}, 0.35);
		FlxTween.tween(inputLabel, {alpha: 1}, 0.35);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (allowInput) {
			if (controls.justPressed.ACCEPT) {
				exit();
				if (onConfirm != null) onConfirm();
			}
			else if (controls.justPressed.BACK) {
				exit();
				if (onCancel != null) onCancel();
			}
		}
	}

	override function close() {
		super.close();
		if (parent != null) parent.persistentUpdate = prevPersistUpdate;
	}

	function exit() {
		if (!allowInput) return;
		allowInput = false;

		FlxTween.color(0.3, bgColor, FlxColor.TRANSPARENT, {onUpdate: (t) -> bgColor = cast(t, ColorTween).color,
			onComplete: (_) -> close()});
		FlxTween.tween(label, {alpha: 0}, 0.3);
		FlxTween.tween(inputLabel, {alpha: 0}, 0.3);
	}

	function set_text(value:String) {
		if (label != null) {
			label.text = value;
			label.screenCenter(XY);
			label.y -= 16;
		}
		return text = value;
	}

	function set_inputText(value:String) {
		if (inputLabel != null) {
			@:privateAccess inputLabel.text = value.replace("%ACCEPT", controls.controls[ACCEPT].keys[0].toString()).replace(
				"%BACK", controls.controls[BACK].keys[0].toString());
			inputLabel.screenCenter(XY);
			inputLabel.y += 12;
		}
		return inputText = value;
	}
}