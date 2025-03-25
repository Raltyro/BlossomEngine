package bl.play.field;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxStringUtil;

import bl.data.Skin;
import bl.data.Song.ChartNote;
import bl.play.Highscore;
import bl.util.ShaderUtil;

class Note extends NoteObject {
	public static final NOTE_WIDTH:Int = Math.floor(160 * 0.7);

	// ITG2 time per pixels is 100, converted to 150 to suit approriately for FNF.
	// It is 3x faster than ITG2 note speed.
	inline public static function timeInPosition(time:Float, speed = 1.0):Float return time * 0.45 * speed;

	inline public static function fromChartNote(chartNote:ChartNote, ?skin:Skin):Note {
		return new Note(chartNote.time, chartNote.column, chartNote.duration, chartNote.type, skin);
	}

	public var time:Float;
	public var duration(default, set):Float;
	public var speed:Float = 1;

	public var ignore:Bool = false;
	public var type:String = "";
	public var priority:Int = 0;
	public var earlyHitMult:Float = 1.0;
	public var lateHitMult:Float = 1.0;

	public var missed:Bool;
	public var hit:Bool;
	public var holdHit:Bool;
	public var judgment:Null<Judgment>;

	public var holdSprite:Null<NoteObject>;
	public var holdBottomSprite:Null<NoteObject>;
	public var holdTopSprite:Null<NoteObject>;

	var _holdSprite:Null<NoteObject>;
	var _holdBottomSprite:Null<NoteObject>;
	var _holdTopSprite:Null<NoteObject>;

	public function new(time:Float, column:Int, duration:Float = 0.0, ?type:String, ?skin:Skin) {
		resetNote();
		super('note', column, skin);

		this.time = time;
		this.duration = duration;
		this.type = type;
	}

	public function resetNote() {
		missed = false;
		hit = false;
		holdHit = false;
		judgment = null;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		holdSprite?.update(elapsed);
		holdBottomSprite?.update(elapsed);
		holdTopSprite?.update(elapsed);
	}

	override function destroy() {
		holdSprite = _holdSprite = FlxDestroyUtil.destroy(holdSprite);
		holdBottomSprite = _holdBottomSprite = FlxDestroyUtil.destroy(holdBottomSprite);
		holdTopSprite = _holdTopSprite = FlxDestroyUtil.destroy(holdTopSprite);
	}

	override function set_field(value:Notefield):Notefield {
		if (value == field) return value;
		field = value;
		resetNote();
		return value;
	}

	override function reloadSkin() {
		reloadHoldSpriteSkins();
		super.reloadSkin();
	}

	inline function reloadSpriteSkin(noteObj:NoteObject) {
		if (noteObj == null) return;
		noteObj.skin = null;
		noteObj.field = field;
		noteObj.column = column;
		noteObj.skin = skin;
	}

	function reloadHoldSpriteSkins() {
		reloadSpriteSkin(holdSprite);
		reloadSpriteSkin(holdBottomSprite);
		reloadSpriteSkin(holdTopSprite);
	}

	function set_duration(value:Float):Float {
		if (value == duration) return value;
		if ((duration = value) >= 1 && holdSprite == null) {
			reloadSpriteSkin(holdSprite = _holdSprite ?? (_holdSprite = new NoteObject('hold', column)));
			reloadSpriteSkin(holdBottomSprite = _holdBottomSprite ?? (_holdBottomSprite = new NoteObject('holdBottom', column)));
			reloadSpriteSkin(holdTopSprite = _holdTopSprite ?? (_holdTopSprite = new NoteObject('holdTop', column)));
		}
		else if (holdSprite != null && duration < 1) {
			_holdSprite = holdSprite;
			_holdBottomSprite = holdBottomSprite;
			_holdTopSprite = holdTopSprite;
			holdSprite = null;
			holdBottomSprite = null;
			holdTopSprite = null;
		}
		return value;
	}

	override function toString() {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("column", column),
			LabelValuePair.weak("visible", visible),
			LabelValuePair.weak("time", time),
			LabelValuePair.weak("duration", duration)
		]);
	}
}