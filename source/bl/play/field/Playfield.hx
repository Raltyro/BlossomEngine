package bl.play.field;

import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;

import bl.data.Skin;
import bl.play.component.Character;
import bl.play.component.JudgmentArea;
import bl.play.Highscore.Judgment;

class Playfield extends Notefield {
	public var characters:Array<Character>;
	public var voice:Null<FlxSound>;
	public var controlVoice:Bool = true;

	public var judgmentArea:JudgmentArea;
	public var legacyJudgment:Bool = false;

	public var currentDirection:Null<NoteDirection>;
	public var currentHold:Null<Note>;
	public var pressedHolds:Array<Note>;

	var _curHold:Null<Note>;
	var _curDirection:Null<NoteDirection>;

	public function new(x:Float = 0, y:Float = 0, id:Int = 0, ?characters:Array<Character>, ?voice:FlxSound, ?skin:Skin, keys = 4) {
		super(x, y, skin, keys);

		this.ID = id;
		this.characters = characters ?? [];
		this.voice = voice;
	}

	override function initVars() {
		super.initVars();
		pressedHolds = [for (i in 0...keys) null];
		judgmentArea = new JudgmentArea(x, y + 64, conductor, skin);
	}

	override function destroy() {
		super.destroy();
		judgmentArea = FlxDestroyUtil.destroy(judgmentArea);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (judgmentArea.container == null) judgmentArea.update(elapsed);
	}

	override function draw() {
		if (judgmentArea.visible) @:privateAccess {
			if (legacyJudgment) {
				final character = characters[0];
				if (character != null)
					judgmentArea.setPosition(
						character.x + (character.cameraFocus.x - 100) * (character.stageFlipX ? -1 : 1),
						character.y + character.cameraFocus.y
					);

				if (judgmentArea.container == null) judgmentArea.draw();
			}
			else if (judgmentArea.container == null) {
				final oldDefaultCameras = FlxCamera._defaultCameras;
				if (_cameras != null) FlxCamera._defaultCameras = _cameras;
				judgmentArea.draw();
				FlxCamera._defaultCameras = oldDefaultCameras;
			}
		}
		super.draw();
	}

	function singNote(note:Note) {
		currentDirection = NoteDirection.fromColumn(note.column, keys);
		pressedHolds[note.column] = currentHold = note.duration > 1 ? note : null;

		for (character in characters) character.sing(currentDirection, currentHold != null ? -1 : 0);
		if (controlVoice && voice != null) voice.muted = false;
	}

	function checkSingHold(time:Float) {
		for (hold in pressedHolds) if (hold != null) if (time < hold.time + hold.duration) singNote(hold);
	}

	override function onNoteHit(note:Note, time:Float) {
		singNote(note);
		judgmentArea.popUp(tallies, note.judgment, time - note.time);

		super.onNoteHit(note, time);
	}

	override function onHoldHit(note:Note, time:Float) {
		if (note == currentHold || currentDirection != null) {
			for (character in characters) character.stopSinging();
			currentDirection = null;
			pressedHolds[note.column] = currentHold = null;
		}
		checkSingHold(time);

		super.onHoldHit(note, time);
	}

	override function onRelease(column:Int, time:Float) {
		final direction = NoteDirection.fromColumn(column, keys);
		for (character in characters) if (character.currentDirection == direction) character.stopSinging();
		if (direction == currentDirection) {
			currentDirection = null;
			pressedHolds[column] = currentHold = null;
		}
		checkSingHold(time);

		super.onRelease(column, time);
	}

	override function onMissPress(column:Int, time:Float) {
		currentDirection = null;
		pressedHolds[column] = currentHold = null;

		for (character in characters) character.sing(NoteDirection.fromColumn(column, keys), true);
		if (controlVoice && voice != null) voice.muted = true;

		judgmentArea.popUp(tallies);

		super.onMissPress(column, time);
	}

	override function onNoteMiss(note:Note) {
		currentDirection = null;
		pressedHolds[note.column] = currentHold = null;

		for (character in characters) character.sing(NoteDirection.fromColumn(note.column, keys), true);
		if (controlVoice && voice != null) voice.muted = true;

		judgmentArea.popUp(tallies, MISS);

		super.onNoteMiss(note);
	}
}