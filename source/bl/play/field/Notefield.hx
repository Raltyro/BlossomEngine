package bl.play.field;

import bl.object.ProxySprite3D;
import bl.object.Mesh;
import bl.util.OBJLoader;



import openfl.display.TriangleCulling;
import openfl.display3D.Context3DCompareMode;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix3D;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import flixel.FlxBasic;
import flixel.FlxCamera;

import bl.data.Skin;
import bl.data.Song.ChartNote;
import bl.object.Container3D;
import bl.object.Object3D;
import bl.play.scoring.BaseScoring;
import bl.play.Highscore;
import bl.util.SortUtil;
import bl.util.SoundUtil;

@:structInit
class SpeedChange {
	public var time:Float = 0;
	public var speed:Float;
	public var endTime:Float = 0;

	@:optional public var position:Null<Float>;
}

// TODO: implement Note.priority
//  earlyHitMult lateHitMult??
//  support for obj noteskins? scripted noteskins? grahh too much
//  implement missHold?
class Notefield extends Object3D {
	@:isVar public var conductor(get, default):Conductor;
	function get_conductor() return conductor ?? playState?.conductor ?? Conductor.instance;

	public var playState(get, default):PlayState;
	function get_playState() {
		if (playState == null && (container != null && container is PlayState)) playState = cast container;
		return playState;
	}

	public var skin(default, set):Skin;
	public var downscroll:Bool = false;

	public var spawnSplashes:Bool = true;
	public var missSounds:Array<FlxSoundAsset>;
	public var missSoundVolume:Float = 0.45;
	public var hitSound:FlxSoundAsset;
	public var hitSoundVolume:Float = 0;

	//public var group(default, null):Container3D;
	//public var members(get, never):Array<FlxBasic>; inline function get_members() return group.members;
	//public var length(get, never):Int; inline function get_length() return group.length;

	public final keys:Int;
	public var scoringSystem:BaseScoring = new bl.play.scoring.PBOT1Scoring();
	public var tallies:Tallies = new Tallies();
	#if (!FLX_HEALTH) public var health:Float = 1; #end
	public var maxHealth:Float = 2;
	public var minHealth:Float = 0;

	public var columnBonusScores:Array<Int>;
	public var columnBonusHealths:Array<Float>;

	public var ignoreInputs:Bool = false;
	public var autoPlay:Bool = false;
	public var ghostTap:Bool = false;
	public var columnPressed:Array<Bool>;
	public var columnLastPress:Array<Float>;
	public var columnPressedNotes:Array<Note>;

	public var visualTime(default, null):Float;
	public var speed:Float = 1.0;
	public var speedChanges:Array<SpeedChange> = [];
	public var currentSpeedChange(get, never):Null<SpeedChange>;
	var currentSpeedChangeIdx:Int = 0;
	function get_currentSpeedChange() return speedChanges[currentSpeedChangeIdx];

	public var drawOffset:Float = 0.0;
	public var drawSize:Float = 1.0;
	public var drawSizeFront:Float = 1.0;
	public var drawSizeBack:Float = 1.0;
	public var drawLaneNotesLimit:Null<Int> = 32;
	public var holdSubdivisions:Int = 1;
	public var depthTest:Bool = false;
	//public var modifiers:;

	public var notes:Array<Note> = [];
	public var availableNotes:Array<Note> = [];

	public var lanes:FlxTypedGroup<Object3D>;
	public var receptors:FlxTypedGroup<Receptor>;
	public var spawnedNotes:FlxTypedGroup<Note>;

	public var holdContinuousHit(get, never):FlxSignal;
	public var noteHit(get, never):FlxTypedSignal<Note->Float->Void>;
	public var holdHit(get, never):FlxTypedSignal<Note->Float->Void>;
	public var noteMissed(get, never):FlxTypedSignal<Note->Void>;
	public var missPressed(get, never):FlxTypedSignal<Int->Float->Void>;
	public var pressed(get, never):FlxTypedSignal<Int->Float->Void>;
	public var released(get, never):FlxTypedSignal<Int->Float->Void>;

	var _holdContinuousHit:FlxSignal;
	var _noteHit:FlxTypedSignal<Note->Float->Void>;
	var _holdHit:FlxTypedSignal<Note->Float->Void>;
	var _noteMissed:FlxTypedSignal<Note->Void>;
	var _missPressed:FlxTypedSignal<Int->Float->Void>;
	var _pressed:FlxTypedSignal<Int->Float->Void>;
	var _released:FlxTypedSignal<Int->Float->Void>;

	// most of these vars don't really do the exact purposes as it named.
	var _columnHolds:Array<Bool>;
	var _columnHoldScores:Array<Int>;
	var _columnHoldHealths:Array<Float>;
	var _spawnedNoteIndices:Array<Int>;
	var _availableNoteIndex:Int;
	var _initialHeight:Float = FlxG.height;
	var _tempNotes:Array<Note> = [];
	var _tempFront:Array<Float> = [];
	var _tempBack:Array<Float> = [];
	var _tempSpeed:Array<Float> = [];
	var _tempOffset:Array<Float> = [];

	var _matrix3D:Matrix3D;
	var _matrix3D2:Matrix3D;
	var _colorTransform:ColorTransform;

	var _verticesDummy:DrawData<Float> = new DrawData<Float>();
	var _indices:DrawData<Int> = new DrawData<Int>();
	var _uvs:DrawData<Float> = new DrawData<Float>();
	var _colors:DrawData<Int> = new DrawData<Int>();
	var _vertices:Array<Float> = [];

	public function new(x:Float = 0, y:Float = 0, ?skin:Skin, keys:Int = 4) {
		this.keys = keys;
		this.skin = skin ?? new Skin();
		super(x, y);
	}

	function _makeLane(column:Int, x = 0.0) {
		final lane = new Object3D(x, 0, 0);
		lanes.add(lane);

		final receptor = new Receptor(0, -_initialHeight * 0.7 / 2, column, skin);
		receptor.field = this;
		receptors.add(receptor);
	}

	override function initVars() {
		super.initVars();

		lanes = new FlxTypedGroup<Object3D>();
		receptors = new FlxTypedGroup<Receptor>();
		spawnedNotes = new FlxTypedGroup<Note>();

		columnPressed = [for (_ in 0...keys) false];
		columnLastPress = [for (_ in 0...keys) 0.0];
		columnPressedNotes = [for (_ in 0...keys) null];
		columnBonusScores = [for (_ in 0...keys) 0];
		columnBonusHealths = [for (_ in 0...keys) 0.0];
		_columnHolds = [for (_ in 0...keys) false];
		_columnHoldScores = [for (_ in 0...keys) 0];
		_columnHoldHealths = [for (_ in 0...keys) 0.0];
		_spawnedNoteIndices = [for (_ in 0...keys) 0];

		var x = -Note.NOTE_WIDTH * (keys + 1) / 2;
		for (i in 0...keys) _makeLane(i, x += Note.NOTE_WIDTH);

		_matrix3D = new Matrix3D();
		_matrix3D2 = new Matrix3D();
		_colorTransform = new ColorTransform();
	}

	override function destroy() {
		//group = FlxDestroyUtil.destroy(group);
		super.destroy();

		receptors = FlxDestroyUtil.destroy(receptors);
		spawnedNotes.clear();
		spawnedNotes = FlxDestroyUtil.destroy(spawnedNotes);
		notes.clearArray();

		_matrix3D = null;
		_matrix3D2 = null;
		_colorTransform = null;
	}

	public function clone():Notefield {
		//final notefield = 
		// TODO
		return null;
	}

	public function resetNotes(?time:Float, force = false) {
		time = time ?? conductor.songPosition ?? 0;
		for (note in notes) if (force || time < note.time) note.resetNote();
	}

	public function makeNote(chartNote:ChartNote):Int {
		return addNote(Note.fromChartNote(chartNote, skin));
	}

	public function addNote(note:Note):Int {
		var idx = notes.length;
		while (idx > 0 && (notes[idx - 1] == null || note.time < notes[idx - 1].time)) idx--;

		note.field = this;
		notes.insert(idx, note);
		return idx;
	}

	public function removeNoteFromIndex(idx:Int):Null<Note> {
		final note = notes[idx];
		if (note == null) return null;

		note.field = null;
		spawnedNotes.remove(note);
		availableNotes.remove(note);
		return note;
	}

	public function removeNote(note:Note):Int {
		final idx = notes.indexOf(note);
		if (idx != -1) removeNoteFromIndex(idx);

		return idx;
	}

	public function getNotes(?column:Int, ?time:Float, ?gotNotes:Array<Note>):Array<Note> {
		if (gotNotes == null) gotNotes = [];
		if (notes.length == 0) return gotNotes;
		time = time ?? conductor.songPosition ?? 0;

		var idx = Math.floor(FlxMath.bound(_availableNoteIndex, 0, notes.length - 1)), note:Note;
		while (idx < notes.length && time > notes[idx].time) idx++;
		while (idx > 0 && (time < (note = notes[idx - 1]).time || scoringSystem.judgeNote(time - note.time) != MISS)) idx--;

		while (idx < notes.length && scoringSystem.judgeNote((note = notes[idx++]).time - time) != MISS)
			if ((column == null || column == note.column) && !note.hit && !note.missed) gotNotes.push(note);
		return gotNotes;
	}

	public function hitNote(note:Note, ?time:Float, force = false):Bool {
		if (note.missed) return false;
		time = time ?? conductor.songPosition ?? 0;

		final canHitHold = note.hit || force;
		if (!note.hit) {
			final timing = time - note.time;
			final judge = scoringSystem.judgeNote(timing);
			if (judge == MISS) {
				missNote(note);
				return false;
			}

			note.hit = true;
			note.judgment = judge;
			availableNotes.remove(note);

			tallies.incrementJudgmentCount(judge);
			tallies.score += scoringSystem.scoreNote(timing);
			health = FlxMath.bound(health + scoringSystem.judgeHealth(note.judgment), minHealth, maxHealth);

			onNoteHit(note, time);
		}

		if (canHitHold && !note.holdHit && note.duration >= 1) {
			note.holdHit = true;

			final duration = FlxMath.bound(time - note.time, 0, note.duration);
			tallies.score += columnBonusScores[note.column] = scoringSystem.scoreHold(duration) - _columnHoldScores[note.column];
			health = FlxMath.bound(health + (columnBonusHealths[note.column] = scoringSystem.bonusHoldHealth(duration) - _columnHoldHealths[note.column]), minHealth, maxHealth);
			_columnHoldScores[note.column] = 0;
			_columnHoldHealths[note.column] = 0;

			final receptor = receptors.members[note.column];
			if (receptor != null && receptor.curAnimName == 'confirm-hold') receptor.playAnim('confirm');

			onHoldHit(note, time);
		}
		return true;
	}

	public function playMissSound():Null<FlxSound> {
		if (missSoundVolume <= 0) return null;
		else if (missSounds != null) return SoundUtil.playSfx(FlxG.random.getObject(missSounds), missSoundVolume);
		else if (skin?.missSounds != null) return SoundUtil.playSfx(FlxG.random.getObject(skin.missSounds), missSoundVolume);

		return null;
	}

	public function missNote(note:Note) {
		if (note.missed) return;

		note.missed = true;
		note.judgment = MISS;
		availableNotes.remove(note);

		tallies.incrementJudgmentCount(MISS);
		tallies.score += scoringSystem.scoreMiss(false);
		health = FlxMath.bound(health + scoringSystem.judgeHealth(MISS), minHealth, maxHealth);

		playMissSound();

		onNoteMiss(note);
	}

	public function missPress(column:Int, ?time:Float) {
		time = time ?? conductor.songPosition ?? 0;

		tallies.incrementJudgmentCount(MISS);
		tallies.score += scoringSystem.scoreMiss(true);
		health = FlxMath.bound(health + scoringSystem.judgeHealth(MISS), minHealth, maxHealth);

		playMissSound();

		onMissPress(column, time);
	}

	public function press(column:Int, ?time:Float, play = true):Note {
		time = time ?? conductor.songPosition ?? 0;

		_tempNotes.clearArray();
		final gotNote = getNotes(column, time, _tempNotes)[0];

		if (columnPressed[column]) release(column, time);

		columnPressed[column] = true;
		columnLastPress[column] = time;

		if ((columnPressedNotes[column] = gotNote) != null) hitNote(gotNote, time);
		else if (!ghostTap) missPress(column, time);
		final hit = gotNote != null && !gotNote.missed;

		if (play) {
			final receptor = receptors.members[column];
			if (receptor != null) {
				receptor.playAnim(hit ? (gotNote.duration >= 1 ? 'confirm-hold' : 'confirm') : 'press', true);
				if (hit && spawnSplashes && gotNote.judgment != null && gotNote.judgment.checkSplash()) receptor.spawnSplash();
			}

			if (hit && hitSoundVolume > 0) SoundUtil.playSfx(hitSound ?? skin.sound('tick'), hitSoundVolume);
		}

		onPress(column, time);

		return gotNote;
	}

	public function release(column:Int, ?time:Float, play = true):Note {
		if (!columnPressed[column]) return null;
		time = time ?? conductor.songPosition ?? 0;

		final note = columnPressedNotes[column];
		if (note != null && note.hit && !note.holdHit) hitNote(note, time);

		columnPressed[column] = false;

		if (play) {
			final receptor = receptors.members[column];
			if (receptor != null) receptor.playAnim('static');
		}

		onRelease(column, time);
		columnPressedNotes[column] = null;

		return note;
	}

	public function updateAutoPlay(?time:Float) {
		time = time ?? conductor.songPosition ?? 0;

		for (k in 0...keys) {
			if (columnPressed[k]) {
				final note = columnPressedNotes[k];
				if (note != null) {
					final releaseTime = note.time + Math.max(note.duration, 160);
					if (time >= releaseTime) release(k, time);
				}
				else if (columnLastPress[k] - 160 > time)
					release(k, time);
			}
		}

		if (notes.length == 0) return;

		var idx = _availableNoteIndex;
		while (idx < notes.length) {
			final note = notes[idx++];
			if (time < note.time) break;
			if (!note.hit && !note.ignore) press(note.column, note.time);
		}
	}

	override function update(elapsed:Float) {
		//group.update(elapsed);

		final time = conductor.songPosition;
		visualTime = getTimeWithIdxInPosition(time, currentSpeedChangeIdx = getTimeInChangeIdx(time, currentSpeedChangeIdx));

		if (path != null && path.active) path.update(elapsed);
		if (moves) updateMotion(elapsed);

		if (autoPlay) updateAutoPlay();

		var hitHold = false;
		for (k => v in _columnHoldScores) {
			final note = columnPressedNotes[k];
			if (note != null && !note.holdHit) {
				final duration = Math.max(time - note.time, 0);
				if (duration >= note.duration) hitNote(note, time, true);
				else {
					final prevHoldHealth = _columnHoldHealths[k];
					tallies.score += columnBonusScores[note.column] =  (_columnHoldScores[k] = scoringSystem.scoreHold(duration)) - v;
					health = FlxMath.bound(health + (columnBonusHealths[note.column] =  (_columnHoldHealths[k] = scoringSystem.bonusHoldHealth(duration)) - prevHoldHealth), minHealth, maxHealth);

					_columnHolds[note.column] = hitHold = true;
				}
			}
			else if (!_columnHolds[k]) {
				columnBonusScores[k] = 0;
				columnBonusHealths[k] = 0;
			}
			else
				_columnHolds[k] = false;
		}
		if (hitHold) onHoldContinuousHit();

		updateAvailableNotes();
		updateSpawnedNotes();

		receptors.update(elapsed);
		spawnedNotes.update(elapsed);
	}

	override function draw() @:privateAccess {
		//group.draw();

		Object3D.composeMatrix3D(getPosition3D(true).subtractVector3(offset), rotation, getScale3D(true), rotationOrder, origin, _matrix3D, false);

		final halfHeight = _initialHeight / 2, halfNoteSize = Note.NOTE_WIDTH / 2, time = conductor.songPosition;
		for (i in 0...keys) {
			final lane = lanes.members[i], receptor = receptors.members[i];

			_tempOffset[i] = drawOffset + receptor.drawOffset;
			_tempSpeed[i] = speed * receptor.speed;
			_tempFront[i] = (-receptor.y + halfHeight) * (receptor.drawSizeFront * drawSizeFront * receptor.drawSize * drawSize) + halfNoteSize;
			_tempBack[i] = /*note.hit ?*/ 0 /*: note.lastPress ? Note.timeInPosition(note.lastPress) : */
				/*(-receptor.y - halfHeight) * (receptor.drawSizeBack * drawSizeBack * receptor.drawSize * drawSize) - halfNoteSize)*/;

			Object3D.composeMatrix3D(lane.getPosition3D(true).subtractVector3(lane.offset), lane.rotation, lane.getScale3D(true),
				lane.rotationOrder, lane.origin, receptor._matrix3D, false).append(_matrix3D);
			receptor._matrix3D.prependTranslation(receptor.x, receptor.y, 0);

			receptor.prepareGlowSprite();
			Object3D.setModelMatrix(receptor.shader, receptor._matrix3D);
			Object3D.setModelMatrix(receptor.glowSprite.shader, receptor._matrix3D);
			for (splash in receptor.splashes.members) {
				if (splash != null && splash.exists && splash.alive)
					Object3D.setModelMatrix(splash.shader, receptor._matrix3D);
			}

			final x = receptor.x, y = receptor.y;
			receptor.setPosition();

			drawObject(receptor);

			receptor.setPosition(x, y);
		}

		var noteSpeedChangeIdx = currentSpeedChangeIdx;
		for (note in spawnedNotes.members) {
			if (note == null || !note.exists) continue;

			final receptor = receptors.members[note.column], column = note.column;
			final speed = _tempSpeed[column], back = _tempBack[column], front = _tempFront[column], offset = _tempOffset[column];
			final pos = Note.timeInPosition(
				getTimeWithIdxInPosition(note.time, noteSpeedChangeIdx = getTimeInChangeIdx(note.time, noteSpeedChangeIdx)) - visualTime,
				speed) + offset;

			_matrix3D.copyFrom(receptor._matrix3D);
			_matrix3D.prependTranslation(0, pos, 0);
			Object3D.setModelMatrix(note.shader, _matrix3D);

			if (note.holdSprite != null) {
				if (note.holdTopSprite.skinLoaded) {
					drawHold(note.holdTopSprite, note.time - offset, Math.min(Math.min(note.holdTopSprite.height, note.duration), front), speed, back,
						receptor._matrix3D, noteSpeedChangeIdx);

					if (note.duration > note.holdTopSprite.height)
						drawHold(note.holdSprite, note.time - offset + note.holdTopSprite.height, Math.min(note.duration - note.holdTopSprite.height, front),
							speed, back, receptor._matrix3D, noteSpeedChangeIdx);
				}
				else {
					drawHold(note.holdSprite, note.time - offset, Math.min(note.duration, front), speed, back, receptor._matrix3D, noteSpeedChangeIdx);
				}
				if (note.holdBottomSprite.skinLoaded) {
					drawHold(note.holdBottomSprite, note.time - offset + note.duration - note.holdBottomSprite.height,
						Math.min(note.holdBottomSprite.height, front), speed, back, receptor._matrix3D, noteSpeedChangeIdx);
				}
			}

			drawObject(note);
		}

		for (receptor in receptors.members) {
			drawObject(receptor.glowSprite);
			for (splash in receptor.splashes.members) if (splash != null && splash.exists && splash.alive) drawObject(splash);
		}
	}

	function drawHold(note:NoteObject, pos:Float, height:Float, speed:Float, back:Float, receptorMatrix3D:Matrix3D, speedChangeIdx:Int) @:privateAccess {
		if (!note.visible) return;

		note.checkEmptyFrame();
		if (note._frame.type == FlxFrameType.EMPTY) return;
		if (note.dirty) note.calcFrame(note.useFramePixels);

		final frame = note._frame;

		for (camera in getCamerasLegacy()) {
			if (!camera.visible || !camera.exists) continue;

			

			#if FLX_DEBUG FlxBasic.visibleCount++; #end
		}
	}

	inline function drawObject(note:NoteObject) @:privateAccess {
		if (!note.visible) return;
		
		note.checkEmptyFrame();
		if (note._frame.type == FlxFrameType.EMPTY) return;
		if (note.dirty) note.calcFrame(note.useFramePixels);

		final sfx = note.scrollFactor.x, sfy = note.scrollFactor.y, b = note.blend;
		note.scrollFactor.set();
		_colorTransform.__copyFrom(note.colorTransform);
		note.colorTransform.concat(colorTransform);
		if (note.blend == null) note.blend = blend;

		for (camera in getCamerasLegacy()) {
			if (!camera.visible || !camera.exists) continue;

			getPerspective(camera).applyShaderParameters(note.shader);
			note.drawComplex(camera);

			#if FLX_DEBUG FlxBasic.visibleCount++; #end
		}

		note.scrollFactor.set(sfx, sfy);
		note.colorTransform.__copyFrom(_colorTransform);
		note.blend = b;
	}

	function updateAvailableNotes() {
		final time = conductor.songPosition;

		var idx = availableNotes.length, note:Note;
		while (--idx >= 0) {
			if ((note = availableNotes[idx]).time < time && scoringSystem.judgeNote(getDiff(note, time)) == MISS) {
				if (!note.hit && !note.missed) missNote(note);
				else availableNotes.swapAndPop(idx);
			}
		}

		_availableNoteIndex = Math.floor(FlxMath.bound(_availableNoteIndex, 0, notes.length - 1));
		if (notes.length == 0) return;

		while (_availableNoteIndex < notes.length && time > (note = notes[_availableNoteIndex]).time) {
			if (!note.missed && !note.hit && scoringSystem.judgeNote(getDiff(note, time)) == MISS) missNote(note);
			_availableNoteIndex++;
		}
		while (_availableNoteIndex > 0 && (time < (note = notes[_availableNoteIndex - 1]).time
			|| scoringSystem.judgeNote(time - note.time) != MISS)) _availableNoteIndex--;

		idx = _availableNoteIndex;
		while (idx < notes.length && scoringSystem.judgeNote((note = notes[idx++]).time - time) != MISS)
			if (!note.hit && !note.missed && !availableNotes.contains(note)) availableNotes.push(note);
	}

	function updateSpawnedNotes() @:privateAccess {
		if (notes.length == 0) {
			spawnedNotes.clear();
			return;
		}
		final halfHeight = _initialHeight / 2, halfNoteSize = Note.NOTE_WIDTH / 2, time = conductor.songPosition;

		var note:Note, idx:Int, len:Int;
		for (i in 0...keys) {
			final receptor = receptors.members[i];
			final offset = drawOffset + receptor.drawOffset,
				speed = receptor.speed * speed,
				front = (-receptor.y + halfHeight) * (receptor.drawSizeFront * drawSizeFront * receptor.drawSize * drawSize) + halfNoteSize,
				back = (-receptor.y - halfHeight) * (receptor.drawSizeBack * drawSizeBack * receptor.drawSize * drawSize) - halfNoteSize;

			idx = spawnedNotes.length;
			while (--idx >= 0) {
				if ((note = spawnedNotes.members[idx]) == null || note.column == i && (!note.exists || note.hit ||
					Note.timeInPosition(note.time + note.duration - time, speed) - offset < back ||
					Note.timeInPosition(time - note.time, speed) - offset > front))
				{
					spawnedNotes.members.swapAndPop(idx);
					spawnedNotes.onMemberRemove(note);
					spawnedNotes.length--;
				}
			}

			idx = Math.floor(FlxMath.bound(_spawnedNoteIndices[i], 0, notes.length - 1));
			while (idx < notes.length && ((note = notes[idx]).column != i || note.hit || Note.timeInPosition(note.time + note.duration - time, speed) - offset < back)) idx++;
			while (idx > 0 && ((note = notes[idx - 1]).column != i || note.hit || Note.timeInPosition(note.time + note.duration - time, speed) - offset > back)) idx--;
			_spawnedNoteIndices[i] = idx;

			len = 0;
			while ((drawLaneNotesLimit == null || len < drawLaneNotesLimit) && idx < notes.length && Note.timeInPosition((note = notes[idx++]).time - time, speed) - offset <= front) {
				if (note.column == i && !note.hit && Note.timeInPosition(note.time + note.duration - time, speed) - offset >= back) {
					len++;
					if (!spawnedNotes.members.contains(note)) {
						spawnedNotes.add(note);
						if (!note.skinLoaded) note.reloadSkin();
					}
				}
			}
		}
	}

	inline function getDiff(note:Note, time:Float) return (time - note.time) * (time > note.time ? note.lateHitMult : note.earlyHitMult);

	public function getTimeInChangeIdx(time:Float, idx:Int = 0):Int {
		if (speedChanges.length < 2) return speedChanges.length - 1;
		else if (speedChanges[idx = Math.floor(FlxMath.bound(idx, 0, speedChanges.length - 1))].time > time) {
			while (--idx > 0) if (time > speedChanges[idx].time) return idx;
			return 0;
		}
		else {
			for (i in idx...speedChanges.length) if (speedChanges[i].time > time) return i - 1;
			return speedChanges.length - 1;
		}
	}

	public function getTimeWithIdxInPosition(time:Float, idx:Int):Float {
		if (idx < 0) return time;

		final speedChange = speedChanges[idx];
		if (idx == 0 && time < speedChange.time) return time;
		else if (speedChange.endTime > speedChange.time && time > speedChange.time) {
			final prev = speedChanges[idx - 1]?.speed ?? 1;
			if (time > speedChange.endTime)
				return speedChange.position + (speedChange.endTime - speedChange.time) * (prev + speedChange.speed) * 0.5
					+ (time - speedChange.endTime) * speedChange.speed;
			else {
				final factor = FlxMath.remapToRange(time, speedChange.time, speedChange.endTime, 0, 0.5);
				return speedChange.position + (time - speedChange.time) * (prev * (1 - factor) + speedChange.speed * factor);
			}
		}
		else {
			return speedChange.position + (time - speedChange.time) * speedChange.speed;
		}
	}

	public function getTimeInPosition(time:Float):Float return getTimeWithIdxInPosition(time, getTimeInChangeIdx(time));

	public function mapSpeedChanges(speedChanges:Array<SpeedChange>) {
		this.speedChanges.resize(speedChanges.length);
		speedChanges = SortUtil.sortByTime(speedChanges.copy());

		var change:SpeedChange = null, next:SpeedChange = null, current:SpeedChange = null, prev:SpeedChange = null;
		for (i in 0...speedChanges.length) {
			change = speedChanges[i];
			prev = current ?? this.speedChanges[i - 2];
			current = next ?? this.speedChanges[i - 1];

			if ((next = this.speedChanges[i]) == null) this.speedChanges[i] = next = {speed: change.speed};
			else next.speed = change.speed;

			next.time = change.time ?? 0;
			next.endTime = change.endTime;

			if (change.position != null) next.position = change.position;
			else if (current == null) next.position = next.time;
			else if (current.endTime <= current.time) next.position = current.position + (next.time - current.time) * current.speed;
			else {
				next.position = current.position + (current.endTime - current.time) * ((prev?.speed ?? 1) + current.speed) * 0.5
					+ (next.time - current.endTime) * current.speed;
			}
		}
	}

	function set_skin(skin:Skin) {
		this.skin = skin;

		// TODO

		return skin;
	}

	function onHoldContinuousHit() if (_holdContinuousHit != null) _holdContinuousHit.dispatch();

	function onNoteHit(note:Note, time:Float)
		if (_noteHit != null) _noteHit.dispatch(note, time);

	function onHoldHit(note:Note, time:Float)
		if (_holdHit != null) _holdHit.dispatch(note, time);

	function onNoteMiss(note:Note)
		if (_noteMissed != null) _noteMissed.dispatch(note);

	function onMissPress(column:Int, time:Float)
		if (_missPressed != null) _missPressed.dispatch(column, time);

	function onPress(column:Int, time:Float)
		if (_pressed != null) _pressed.dispatch(column, time);

	function onRelease(column:Int, time:Float)
		if (_released != null) _released.dispatch(column, time);

	function get_holdContinuousHit():FlxSignal {
		if (_holdContinuousHit == null) _holdContinuousHit = new FlxSignal();
		return _holdContinuousHit;
	}

	function get_noteHit():FlxTypedSignal<Note->Float->Void> {
		if (_noteHit == null) _noteHit = new FlxTypedSignal<Note->Float->Void>();
		return _noteHit;
	}

	function get_holdHit():FlxTypedSignal<Note->Float->Void> {
		if (_holdHit == null) _holdHit = new FlxTypedSignal<Note->Float->Void>();
		return _holdHit;
	}

	function get_noteMissed():FlxTypedSignal<Note->Void> {
		if (_noteMissed == null) _noteMissed = new FlxTypedSignal<Note->Void>();
		return _noteMissed;
	}

	function get_missPressed():FlxTypedSignal<Int->Float->Void> {
		if (_missPressed == null) _missPressed = new FlxTypedSignal<Int->Float->Void>();
		return _missPressed;
	}

	function get_pressed():FlxTypedSignal<Int->Float->Void> {
		if (_pressed == null) _pressed = new FlxTypedSignal<Int->Float->Void>();
		return _pressed;
	}

	function get_released():FlxTypedSignal<Int->Float->Void> {
		if (_released == null) _released = new FlxTypedSignal<Int->Float->Void>();
		return _released;
	}

	override function get_width():Float return Note.NOTE_WIDTH * keys * scale.x;
	override function get_height():Float return _initialHeight * scale.y;
}