package bl;

import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.util.FlxSignal;
import flixel.util.FlxStringUtil;
import flixel.FlxG;

import bl.audio.Music;
import bl.util.SortUtil;

enum abstract BeatType(UInt8) from UInt8 to UInt8 {
	var BEAT = 0;
	var MEASURE = 1;
	var STEP = 2;
}

@:structInit
class TimeChange {
	@:optional public var time:Null<Float>;
	public var bpm:Float;
	public var numerator:Float = 4;
	public var denominator:Float = 4;
	public var tuplet:Float = 4;

	public var continuous:Bool = false;
	public var endTime:Float = 0;

	public var stepTime:Float = 0;
	@:optional public var beatTime:Null<Float>;
	public var measureTime:Float = 0;
}

class Conductor {
	public static final DEFAULT_TIMECHANGE:TimeChange = {bpm: 100};

	public static var instance(get, set):Conductor;

	static var _instance:Null<Conductor> = null;
	static function get_instance():Conductor {
		if (Conductor._instance == null) inline reset();
		return Conductor._instance;
	}

	static function set_instance(instance:Conductor):Conductor return Conductor._instance = instance;

	public static function reset():Void instance = new Conductor();

	public function getBeats(?every:BeatType, interval:Float, offset:Float = 0):Float {
		final beat = switch(every) {
			case MEASURE: currentMeasureTime;
			case STEP: currentStepTime;
			default: currentBeatTime;
		}
		if (interval <= 0) return beat - offset;
		else return Math.floor((beat - offset) / interval) * interval;
	}

	public var metronome(get, never):Metronome;
	var _metronome:Metronome;
	function get_metronome() {
		if (_metronome == null) _metronome = new Metronome(this, false);
		return _metronome;
	}

	public var attachedMusic(default, null):Music;
	var _attachedMusicHandler:Void->Void;
	public function attachToMusic(music:Music) {
		if (attachedMusic != null) attachedMusic.onMusicChanged.remove(_attachedMusicHandler);
		if ((attachedMusic = music) != null) {
			mapTimeChanges(music.timeChanges);
			music.onMusicChanged.add(_attachedMusicHandler = () -> mapTimeChanges(music.timeChanges));
		}
		else
			_attachedMusicHandler = null;
	}

	public var onTimeChange(default, null):FlxSignal = new FlxSignal();
	public var onMeasureHit(default, null):FlxSignal = new FlxSignal();
	public var onBeatHit(default, null):FlxSignal = new FlxSignal();
	public var onStepHit(default, null):FlxSignal = new FlxSignal();
	public var onMetronomeHit(default, null):FlxTypedSignal<Bool->Void> = new FlxTypedSignal();

	public var songPosition(default, null):Float = 0;
	public var offset:Float = Save.settings.songOffset ?? 0;
	public var appliedOffset:Null<Float>;

	public var oldMeasure(default, null):Int = 0;
	public var oldBeat(default, null):Int = 0;
	public var oldStep(default, null):Int = 0;

	public var currentMeasure(default, null):Int = 0;
	public var currentBeat(default, null):Int = 0;
	public var currentStep(default, null):Int = 0;

	public var currentMeasureTime(default, null):Float = 0;
	public var currentBeatTime(default, null):Float = 0;
	public var currentStepTime(default, null):Float = 0;

	public var timeChanges:Array<TimeChange> = [];

	public function new() {}

	public var currentTimeChange(get, never):Null<TimeChange>;
	var currentTimeChangeIdx:Int = 0;
	function get_currentTimeChange() return timeChanges[currentTimeChangeIdx];

	public var bpm(get, never):Float;
	function get_bpm() {
		if (currentTimeChangeIdx > 0)
			return getTimeWithIdxInBPM(songPosition, currentTimeChangeIdx);
		else
			return startingBPM;
	}

	public var startingBPM(get, never):Float;
	function get_startingBPM()
		return (timeChanges[0] ?? DEFAULT_TIMECHANGE).bpm;

	public var beatLength(get, never):Float;
	function get_beatLength() return 240000 / bpm / denominator;
	public function getBeatLength(?timeChange:TimeChange)
		return 240000 / (timeChange?.bpm ?? bpm) / getDenominator(timeChange);

	public var stepLength(get, never):Float;
	function get_stepLength() return beatLength / tuplet;
	public function getStepLength(?timeChange:TimeChange)
		return getBeatLength(timeChange) / getTuplet(timeChange);

	public var measureLength(get, never):Float;
	function get_measureLength() return beatLength * numerator;
	public function getMeasureLength(?timeChange:TimeChange)
		return getBeatLength(timeChange) * getNumerator(timeChange);

	public var numerator(get, never):Float;
	function get_numerator() return (currentTimeChange ?? DEFAULT_TIMECHANGE).numerator;
	public function getNumerator(?timeChange:TimeChange)
		return (timeChange ?? currentTimeChange ?? DEFAULT_TIMECHANGE).numerator;

	public var denominator(get, never):Float;
	function get_denominator() return (currentTimeChange ?? DEFAULT_TIMECHANGE).denominator;
	public function getDenominator(?timeChange:TimeChange)
		return (timeChange ?? currentTimeChange ?? DEFAULT_TIMECHANGE).denominator;

	public var tuplet(get, never):Float;
	function get_tuplet() return (currentTimeChange ?? DEFAULT_TIMECHANGE).tuplet;
	public function getTuplet(?timeChange:TimeChange)
		return (timeChange ?? currentTimeChange ?? DEFAULT_TIMECHANGE).tuplet;

	public var stepsPerMeasure(get, never):Float;
	function get_stepsPerMeasure() return numerator * tuplet;
	public function getStepsPerMeasure(?timeChange:TimeChange)
		return getNumerator(timeChange) * getTuplet(timeChange);

	public function update(?sound:flixel.util.typeLimit.OneOfTwo<FlxSound, Float>, rate = 1.0, ?forceDispatch:Bool, applyOffsets = true) {
		//if (sound == null) sound = FlxG.sound.music;

		final oldSongPosition = Math.isNaN(songPosition) ? 0 : songPosition, oldTimeChangeIdx = currentTimeChangeIdx;

		if (sound != null || FlxG.sound.music != null) {
			final snd:FlxSound = (sound is FlxSound) ? sound : null;
			songPosition = sound == null ? FlxG.sound.music.time : (snd != null ? snd.time : cast sound);
			if (applyOffsets) songPosition -= (appliedOffset = offset * (snd != null ? snd.getActualPitch() : 1.0) * rate);
			else appliedOffset = null;
		}

		if (oldSongPosition == songPosition) {
			if (forceDispatch != false && forceDispatch) {
				onStepHit.dispatch();
				onBeatHit.dispatch();
				onMeasureHit.dispatch();
				onMetronomeHit.dispatch(false);
			}
			return;
		}

		oldBeat = currentBeat;
		oldMeasure = currentMeasure;
		oldStep = currentStep;
		if ((currentTimeChangeIdx = getTimeInChangeIdx(songPosition, currentTimeChangeIdx)) > 0) {
			final timeChange = currentTimeChange;
			currentBeatTime = getTimeWithBPMInBeats(songPosition, currentTimeChangeIdx, getTimeWithIdxInBPM(songPosition, currentTimeChangeIdx));
			currentMeasureTime = timeChange.measureTime + (currentBeatTime - timeChange.beatTime) / getNumerator(timeChange);
			currentStepTime = timeChange.stepTime + (currentBeatTime - timeChange.beatTime) * getTuplet(timeChange);
		}
		else {
			currentMeasureTime = (currentBeatTime = songPosition / beatLength) / numerator;
			currentStepTime = currentBeatTime * tuplet;
		}

		currentBeat = Math.floor(currentBeatTime);
		currentMeasure = Math.floor(currentMeasureTime);
		currentStep = Math.floor(currentStepTime);

		if (forceDispatch) {
			onTimeChange.dispatch();
			onStepHit.dispatch();
			onBeatHit.dispatch();
			onMeasureHit.dispatch();
			onMetronomeHit.dispatch(currentMeasure != oldMeasure);
		}
		else if (forceDispatch != false) {
			final beatTicked = currentBeat != oldBeat, measureTicked = currentMeasure != oldMeasure;
			if (currentTimeChangeIdx != oldTimeChangeIdx) onTimeChange.dispatch();
			if (currentStep != oldStep) onStepHit.dispatch();
			if (beatTicked) onBeatHit.dispatch();
			if (measureTicked) onMeasureHit.dispatch();
			if (beatTicked || measureTicked) onMetronomeHit.dispatch(measureTicked);
		}

		if (_metronome != null) _metronome.update();
	}

	public function getTimeInChangeIdx(time:Float, idx:Int = 0):Int {
		if (timeChanges.length < 2) return timeChanges.length - 1;
		else if (timeChanges[idx = Math.floor(FlxMath.bound(idx, 0, timeChanges.length - 1))].time > time) {
			while (--idx > 0) if (time > timeChanges[idx].time) return idx;
			return 0;
		}
		else {
			for (i in idx...timeChanges.length) if (timeChanges[i].time > time) return i - 1;
			return timeChanges.length - 1;
		}
	}

	public function getBeatsInChangeIdx(beatTime:Float, idx:Int = 0):Int {
		if (timeChanges.length < 2) return timeChanges.length - 1;
		else if (timeChanges[idx = Math.floor(FlxMath.bound(idx, 0, timeChanges.length - 1))].beatTime > beatTime) {
			while (--idx > 0) if (beatTime > timeChanges[idx].beatTime) return idx;
			return 0;
		}
		else {
			for (i in idx...timeChanges.length) if (timeChanges[i].beatTime > beatTime) return i - 1;
			return timeChanges.length - 1;
		}
	}

	public function getMeasuresInChangeIdx(measureTime:Float, idx:Int = 0):Int {
		if (timeChanges.length < 2) return timeChanges.length - 1;
		else if (timeChanges[idx = Math.floor(FlxMath.bound(idx, 0, timeChanges.length - 1))].measureTime > measureTime) {
			while (--idx > 0) if (measureTime > timeChanges[idx].measureTime) return idx;
			return 0;
		}
		else {
			for (i in idx...timeChanges.length) if (timeChanges[i].measureTime > measureTime) return i - 1;
			return timeChanges.length - 1;
		}
	}

	public function getStepsInChangeIdx(stepTime:Float, idx:Int = 0):Int {
		if (timeChanges.length < 2) return timeChanges.length - 1;
		else if (timeChanges[idx = Math.floor(FlxMath.bound(idx, 0, timeChanges.length - 1))].stepTime > stepTime) {
			while (--idx > 0) if (stepTime > timeChanges[idx].stepTime) return idx;
			return 0;
		}
		else {
			for (i in idx...timeChanges.length) if (timeChanges[i].stepTime > stepTime) return i - 1;
			return timeChanges.length - 1;
		}
	}

	public function getTimeWithIdxInBPM(time:Float, idx:Int):Float {
		final timeChange = timeChanges[idx];
		if (timeChange.continuous && time < timeChange.endTime && idx > 0) {
			final prevBPM = timeChanges[idx - 1].bpm;
			if (time <= timeChange.time) return prevBPM;

			final ratio = (time - timeChange.time) / (timeChange.endTime - timeChange.time);
			return Math.pow(prevBPM, 1 - ratio) * Math.pow(timeChange.bpm, ratio);
		}
		return timeChange.bpm;
	}

	public function getBeatsWithIdxInBPM(beatTime:Float, idx:Int):Float {
		final timeChange = timeChanges[idx];
		if (timeChange.continuous && idx > 0) {
			final prevBPM = timeChanges[idx - 1].bpm;
			if (beatTime <= timeChange.beatTime) return prevBPM;

			final endBeatTime = timeChange.beatTime + (timeChange.endTime - timeChange.time) * (timeChange.bpm - prevBPM) / Math.log(timeChange.bpm / prevBPM) / 240000 * getDenominator(timeChange);
			if (beatTime < endBeatTime) return FlxMath.remapToRange(beatTime, timeChange.beatTime, endBeatTime, prevBPM, timeChange.bpm);
		}
		return timeChange.bpm;
	}

	public function getTimeInBPM(time:Float):Float {
		if (timeChanges.length == 0) return DEFAULT_TIMECHANGE.bpm;
		return getTimeWithIdxInBPM(time, getTimeInChangeIdx(time));
	}

	public function getBeatsInBPM(beatTime:Float):Float {
		if (timeChanges.length == 0) return DEFAULT_TIMECHANGE.bpm;
		return getBeatsWithIdxInBPM(beatTime, getBeatsInChangeIdx(beatTime));
	}

	public function getMeasuresInBPM(measureTime:Float):Float {
		final idx = getMeasuresInChangeIdx(measureTime);
		if (idx == -1) return DEFAULT_TIMECHANGE.bpm;
		else {
			final timeChange = timeChanges[idx];
			return getBeatsWithIdxInBPM(timeChange.beatTime + (measureTime - timeChange.measureTime) * getNumerator(timeChange), idx);
		}
	}

	public function getStepsInBPM(stepTime:Float):Float {
		final idx = getStepsInChangeIdx(stepTime);
		if (idx == -1) return DEFAULT_TIMECHANGE.bpm;
		else {
			final timeChange = timeChanges[idx];
			return getBeatsWithIdxInBPM(timeChange.beatTime + (stepTime - timeChange.stepTime) / getTuplet(timeChange), idx);
		}
	}

	public function getTimeWithBPMInBeats(time:Float, idx:Int, bpm:Float):Float {
		final timeChange = timeChanges[idx];
		if (timeChange.continuous && time > timeChange.time && idx > 0) {
			final prevBPM = timeChanges[idx - 1].bpm;
			if (time > timeChange.endTime)
				return timeChange.beatTime + (((timeChange.endTime - timeChange.time) * (bpm - prevBPM))
					/ Math.log(bpm / prevBPM) + (time - timeChange.endTime) * bpm) / 240000 * getDenominator(timeChange);
			else
				return timeChange.beatTime + (time - timeChange.time) * (bpm - prevBPM) / Math.log(bpm / prevBPM) / 240000 * getDenominator(timeChange);
		}
		else {
			return timeChange.beatTime + (time - timeChange.time) / getBeatLength(timeChange);
		}
	}

	public function getTimeInBeats(time:Float):Float {
		final idx = getTimeInChangeIdx(time);
		return idx < 1 ? time / getBeatLength(timeChanges[idx]) : getTimeWithBPMInBeats(time, idx, getTimeWithIdxInBPM(time, idx));
	}

	public function getTimeInMeasures(time:Float):Float {
		final idx = getTimeInChangeIdx(time);
		if (idx < 1) return time / getMeasureLength(timeChanges[idx]);
		else {
			final timeChange = timeChanges[idx];
			return timeChange.measureTime + (getTimeWithBPMInBeats(time, idx, getTimeWithIdxInBPM(time, idx)) - timeChange.beatTime) / getNumerator(timeChange);
		}
	}

	public function getTimeInSteps(time:Float):Float {
		final idx = getTimeInChangeIdx(time);
		if (idx < 1) return time / getStepLength(timeChanges[idx]);
		else {
			final timeChange = timeChanges[idx];
			return timeChange.stepTime + (getTimeWithBPMInBeats(time, idx, getTimeWithIdxInBPM(time, idx)) - timeChange.beatTime) * getTuplet(timeChange);
		}
	}

	public function getBeatsWithBPMInTime(beatTime:Float, idx:Int, bpm:Float):Float {
		final timeChange = timeChanges[idx];
		if (timeChange.continuous && beatTime > timeChange.beatTime && idx > 0) {
			final prevBPM = timeChanges[idx - 1].bpm;
			final time = timeChange.time + (beatTime - timeChange.beatTime) / (bpm - prevBPM) * Math.log(bpm / prevBPM) * 240000 / getDenominator(timeChange);
			if (time > timeChange.endTime)
				return (240000 / getDenominator(timeChange) * (beatTime - timeChange.beatTime) - ((timeChange.endTime - timeChange.time)
					* (timeChange.bpm - prevBPM)) / Math.log(timeChange.bpm / prevBPM)) / bpm + timeChange.endTime;
			else
				return time;
		}
		else {
			return timeChange.time + (beatTime - timeChange.beatTime) * getBeatLength(timeChange);
		}
	}

	public function getBeatsInTime(beatTime:Float):Float {
		final idx = getBeatsInChangeIdx(beatTime);
		return idx < 1 ? beatTime * beatLength : getBeatsWithBPMInTime(beatTime, idx, getBeatsWithIdxInBPM(beatTime, idx));
	}

	public function getMeasuresInTime(measureTime:Float):Float {
		final idx = getMeasuresInChangeIdx(measureTime);
		if (idx < 1) return measureTime * getMeasureLength(timeChanges[idx]);
		else {
			final timeChange = timeChanges[idx];
			final beatTime = timeChange.beatTime + (measureTime - timeChange.measureTime) * getNumerator(timeChange);
			return getBeatsWithBPMInTime(beatTime, idx, getBeatsWithIdxInBPM(beatTime, idx));
		}
	}

	public function getStepsInTime(stepTime:Float):Float {
		final idx = getStepsInChangeIdx(stepTime);
		if (idx < 1) return stepTime * getStepLength(timeChanges[idx]);
		else {
			final timeChange = timeChanges[idx];
			final beatTime = timeChange.beatTime + (stepTime - timeChange.stepTime) / getTuplet(timeChange);
			return getBeatsWithBPMInTime(beatTime, idx, getBeatsWithIdxInBPM(beatTime, idx));
		}
	}

	public function setBPM(bpm:Float) timeChanges = [{bpm: bpm}];

	public function updateTimeChanges(timeChanges:Array<TimeChange>, from:Int) {
		this.timeChanges.resize(timeChanges.length);

		var change:TimeChange = null, next:TimeChange = null, current:TimeChange = null, prev:TimeChange = null;
		for (i in from...timeChanges.length) {
			change = timeChanges[i];
			prev = current ?? this.timeChanges[i - 2];
			current = next ?? this.timeChanges[i - 1];

			if ((next = this.timeChanges[i]) == null) this.timeChanges[i] = next = {bpm: change.bpm};
			else next.bpm = change.bpm;

			next.time = change.time ?? 0;
			next.beatTime = change.beatTime ?? 0;
			next.endTime = change.endTime;
			next.continuous = change.continuous;
			next.tuplet = change.tuplet;
			next.numerator = change.numerator;
			next.denominator = change.denominator;

			if (current == null) {
				if (change.time == null) next.time = next.beatTime * 240000 / next.bpm / next.denominator;
				else next.beatTime = next.time / 240000 * next.bpm * next.denominator;
			
				next.stepTime = next.beatTime * next.tuplet;
				next.measureTime = next.beatTime / next.numerator;
			}
			else {
				if (change.beatTime != null) {
					/*if (current.continuous)
						next.time = current.endTime + (next.beatTime - (

						)) * 240 / current.bpm / current.denominator;
					else*/
						next.time = current.time + (next.beatTime - current.beatTime) * 240000 / current.bpm / current.denominator;
				}
				else {
					if (current.continuous && prev != null)
						next.beatTime = current.beatTime + (((current.endTime - current.time) * (current.bpm - prev.bpm))
							/ Math.log(current.bpm / prev.bpm) + (next.time - current.endTime) * next.bpm) / 240 * current.denominator;
					else
						next.beatTime = current.beatTime + (next.time - current.time) / 240000 * current.bpm * current.denominator;
				}

				next.stepTime = current.stepTime + (next.beatTime - current.beatTime) * current.tuplet;
				next.measureTime = current.measureTime + (next.beatTime - current.beatTime) / current.numerator;

				if (next.numerator != current.numerator || next.denominator != current.denominator) {
					next.stepTime = Math.ceil(next.stepTime - .000001);
					next.beatTime = Math.ceil(next.beatTime - .000001);
					next.measureTime = Math.ceil(next.measureTime - .000001);
				}
			}
		}
	}

	public function mapTimeChanges(timeChanges:Array<TimeChange>, updateAfter:Bool = true) {
		if (timeChanges == null) return;

		updateTimeChanges(SortUtil.sortByTime(timeChanges.copy()), 0);
		if (updateAfter) update(songPosition, true);
	}

	function toString():String {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("songPosition", songPosition),
			LabelValuePair.weak("offset", offset),
			LabelValuePair.weak("bpm", bpm),
			LabelValuePair.weak("numerator", numerator),
			LabelValuePair.weak("denominator", denominator),
			LabelValuePair.weak("tuplet", tuplet),
			LabelValuePair.weak("currentMeasureTime", currentMeasureTime),
			LabelValuePair.weak("currentBeatTime", currentBeatTime),
			LabelValuePair.weak("currentStepTime", currentStepTime),
			LabelValuePair.weak("currentTimeChangeIdx", currentTimeChangeIdx)
		]);
	}
}

// TODO: improve the sync on metronome sounds
class Metronome {
	public function getBeats(?every:BeatType, interval:Float, offset:Float = 0):Float {
		final beat = switch(every) {
			case MEASURE: currentMeasureTime;
			case STEP: currentStepTime;
			default: currentBeatTime;
		}
		if (interval <= 0) return beat - offset;
		else return Math.floor((beat - offset) / interval) * interval;
	}

	public var conductor:Conductor;

	public var onMeasureHit(default, null):FlxSignal = new FlxSignal();
	public var onBeatHit(default, null):FlxSignal = new FlxSignal();
	public var onStepHit(default, null):FlxSignal = new FlxSignal();
	public var onMetronomeHit(default, null):FlxTypedSignal<Bool->Void> = new FlxTypedSignal();

	public var currentMeasure(default, null):Int = 0;
	public var currentBeat(default, null):Int = 0;
	public var currentStep(default, null):Int = 0;

	public var currentMeasureTime(default, null):Float = 0;
	public var currentBeatTime(default, null):Float = 0;
	public var currentStepTime(default, null):Float = 0;

	public var playMetronome:Bool;

	var currentTimeChangeIdx:Int = 0;

	public function new(conductor:Conductor, playMetronome = true) {
		this.conductor = conductor;
		this.playMetronome = playMetronome;
	}

	public function update(?conductor:Conductor) @:privateAccess {
		conductor = (this.conductor = conductor ?? this.conductor);

		final timePosition = conductor.songPosition + (conductor.appliedOffset ?? 0);
		final oldBeat = currentBeat, oldMeasure = currentMeasure, oldStep = currentStep;
		if ((currentTimeChangeIdx = conductor.getTimeInChangeIdx(timePosition, currentTimeChangeIdx)) > 0) {
			final timeChange = conductor.timeChanges[currentTimeChangeIdx];
			currentBeatTime = conductor.getTimeWithBPMInBeats(timePosition, currentTimeChangeIdx,
				conductor.getTimeWithIdxInBPM(timePosition, currentTimeChangeIdx));
			currentMeasureTime = timeChange.measureTime + (currentBeatTime - timeChange.beatTime) / conductor.getNumerator(timeChange);
			currentStepTime = timeChange.stepTime + (currentBeatTime - timeChange.beatTime) * conductor.getTuplet(timeChange);
		}
		else {
			final timeChange = conductor.timeChanges[0] ?? Conductor.DEFAULT_TIMECHANGE;
			currentBeatTime = timePosition / conductor.getBeatLength(timeChange);
			currentMeasureTime = currentBeatTime / conductor.getNumerator(timeChange);
			currentStepTime = currentBeatTime * conductor.getTuplet(timeChange);
		}

		currentBeat = Math.floor(currentBeatTime);
		currentMeasure = Math.floor(currentMeasureTime);
		currentStep = Math.floor(currentStepTime);

		final beatTicked = currentBeat != oldBeat, measureTicked = currentMeasure != oldMeasure;
		if (currentStep != oldStep) onStepHit.dispatch();
		if (beatTicked) onBeatHit.dispatch();
		if (measureTicked) onMeasureHit.dispatch();
		if (beatTicked || measureTicked) {
			if (playMetronome) FlxG.sound.play(Paths.sound(measureTicked ? 'clav1' : 'clav2'));
			onMetronomeHit.dispatch(measureTicked);
		}
	}
}