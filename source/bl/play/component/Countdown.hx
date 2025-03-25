package bl.play.component;

import flixel.group.FlxGroup;
import bl.data.Skin;

typedef CountdownData = {
	?sprite:String,
	?sound:String,
	?volume:Float
}

class Countdown extends FlxGroup {
	public static final DEFAULT_COUNTDOWNDATA = [
		{sprite: 'prepare', sound: 'intro3'},
		{sprite: 'ready', sound: 'intro2'},
		{sprite: 'set', sound: 'intro1'},
		{sprite: 'go', sound: 'introGo'}
	];

	public var conductor:Null<Conductor>;
	public var skin(default, set):Skin;
	public var counting:Bool;

	var countInterval:Float = 1;
	var countEvery:BeatType = BEAT;
	var countStart:Float = 0;
	var datas:Array<CountdownData>;
	var _lastBeat:Int = -1;
	var _lastSoundBeat:Int = -1;

	public function new(conductor:Conductor, skin:Skin) {
		super();

		this.conductor = conductor;
		this.skin = skin;
	}

	public function start(timePosition:Float, interval = 1.0, every:BeatType = BEAT) {
		if (conductor == null) return;
		counting = true;

		countInterval = interval;
		_lastBeat = _lastSoundBeat = -1;
		switch (countEvery = every) {
			case MEASURE: countStart = conductor.getTimeInMeasures(timePosition);
			case STEP: countStart = conductor.getTimeInSteps(timePosition);
			default: countStart = conductor.getTimeInBeats(timePosition);
		}
	}

	public function stop() {
		counting = false;
	}

	public function doCountdown(beat:Int, playSound = true) {
		final data = datas[beat];
		if (data == null || skin == null) return;

		if (data.sprite != null) {
			final sprite = BLSprite.fromData(skin.getSpriteData(data.sprite));
			sprite.screenCenter();
			add(sprite);
			FlxTween.tween(sprite, {alpha: 0}, conductor.beatLength / 1000,
				{ease: FlxEase.cubeInOut, onComplete: (_) -> remove(sprite).destroy()});
		}
		if (playSound && data.sound != null) FlxG.sound.play(skin.sound(data.sound), data.volume ?? 1);
	}

	public function getBeats():Int
		return datas.length;

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (counting && conductor != null) {
			final beat = Math.floor(conductor.getBeats(countEvery, 0, countStart) / countInterval);
			if (_lastBeat != beat) {
				_lastBeat = beat;
				doCountdown(beat, false);
			}

			final beat = Math.floor(conductor.metronome.getBeats(countEvery, 0, countStart) / countInterval);
			if (_lastSoundBeat != beat) {
				_lastSoundBeat = beat;
				final data = datas[beat];
				if (data != null && skin != null && data.sound != null) FlxG.sound.play(skin.sound(data.sound), data.volume ?? 1);
			}
		}
	}

	function set_skin(skin:Skin) {
		this.skin = skin;
		datas = skin == null || skin.countdowns == null ? DEFAULT_COUNTDOWNDATA : skin.countdowns;
		return skin;
	}
}