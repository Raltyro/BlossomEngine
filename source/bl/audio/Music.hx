package bl.audio;

import openfl.media.Sound;
import flixel.system.FlxAssets;
import flixel.util.FlxSignal;

import hxjson5.Json5;

typedef MusicData = {
	?path:String,

	music:FlxSoundAsset,
	?intro:FlxSoundAsset,
	?timeChanges:Array<TimeChange>,
	?title:String,
	?artist:String,
	?looped:Bool,
	?volume:Float,
	?offset:Float,
	?after:MusicAsset
}

typedef MusicAsset = flixel.util.typeLimit.OneOfTwo<String, MusicData>;

class Music extends FlxSound {
	public static function getMusicData(asset:String):MusicData {
		asset = Paths.fixExt(asset, Paths.EXT_SOUND);
		var raw:Dynamic = null, music:Sound = null, intro:Sound = null;
		try {
			final base = Paths.withoutExt(asset), ext = Paths.ext(asset);
			var isFolder:Null<Bool> = null;
			if (AssetUtil.soundExists(asset)) isFolder = false;
			else if (AssetUtil.soundExists(asset = '$base/music.$ext')) isFolder = true;

			if (isFolder != null) {
				music = AssetUtil.getMusic(asset);

				final metaPath = isFolder ? '$base/meta.json' : '$base-meta.json',
					introPath = isFolder ? '$base/intro.$ext' : '$base-intro.$ext';

				if (AssetUtil.textExists(metaPath)) raw = Json5.parse(AssetUtil.getText(metaPath));
				if (AssetUtil.soundExists(introPath)) intro = AssetUtil.getMusic(introPath);
			}
		}
		catch(e) {
			trace('Failed to getting Music Data "${asset}"\nError: ${e.message}');
		}
		if ((music = music ?? intro) == null) return null;

		final data:MusicData = raw != null ? cast raw : {music: music}
		if (intro != music && intro != null) data.intro = intro;
		if (raw != null) {
			data.music = music;

			if (raw.songName is String) data.title = raw.songName;
			if (raw.bpm is Float) data.timeChanges = [{bpm: raw.bpm}];
			else if (Type.typeof(raw.timeChanges) == TObject) {
				final dataTimeChanges = raw.timeChanges;
				data.timeChanges = [];
				// TODO
			}
		}
		else data.looped = true;

		data.path = asset;
		return data;
	}

	public var onMusicChanged:FlxSignal;

	public var musicData:MusicData;
	public var inIntro(default, null):Bool;
	public var timeChanges(get, never):Null<Array<TimeChange>>;
	function get_timeChanges() return (_musicData ?? musicData)?.timeChanges;

	var _musicData:MusicData;

	override function reset(clean:Bool = false) {
		super.reset(clean);
		onMusicChanged = new FlxSignal();
	}

	override function destroy() {
		super.destroy();
		if (onMusicChanged != null) onMusicChanged.destroy();
		onMusicChanged = null;
	}

	public function loadMusic(asset:MusicAsset, ?autoDestroy:Null<Bool>, ?onComplete:Null<Void->Void>):Music {
		if (!exists || asset == null) return this;
		cleanup(true);

		if (asset is String) musicData = getMusicData(asset);
		else if (asset != null) musicData = asset;

		init(looped, autoDestroy, onComplete);
		return this;
	}

	public function skipIntro() {
		inIntro = false;
		initMusicSound();
	}

	override function cleanup(destroySound:Bool, resetPosition:Bool = true) {
		super.cleanup(destroySound, resetPosition);
		if (destroySound) musicData = null;
		else if (resetPosition) _musicData = musicData;
	}

	override function init(?looped:Null<Bool>, ?autoDestroy:Null<Bool>, ?onComplete:Null<Void->Void>):FlxSound {
		inIntro = false;
		initMusic(musicData);
		return super.init(musicData == null ? looped : musicData.looped, autoDestroy, onComplete);
	}

	function initMusic(musicData:MusicData) {
		if ((_musicData = musicData) == null) return;
		inIntro = musicData.intro != null;
		initMusicSound();
		onMusicChanged.dispatch();
	}

	function initMusicSound() {
		if (_musicData == null) return;

		final sound = inIntro ? _musicData.intro : _musicData.music;
		if (sound is Sound) _sound = sound;
		else if (sound is Class) _sound = Type.createInstance(sound, []);
		else if (sound is String) {
			if (AssetUtil.soundExists(sound)) _sound = AssetUtil.getMusic(sound);
			else FlxG.log.error('Could not find a Sound asset with an ID of \'$sound\'.');
		}
		if (inIntro) looped = false;
		else if (_musicData.looped != null) looped = _musicData.looped;
	}

	override function updateTransform() {
		final og = _volume;
		if (_musicData != null) _volume *= _musicData.volume ?? 1;
		super.updateTransform();
		_volume = og;
	}

	override function stopped(?_) {
		if (_musicData != null) {
			if (inIntro) {
				inIntro = false;
				initMusicSound();
				startSound(0);
			}
			else if (_musicData.after != null) {
				if (_musicData.after is String) initMusic(getMusicData(_musicData.after));
				else initMusic(_musicData.after);
				startSound(0);
			}
			else super.stopped(_);
		}
		else super.stopped(_);
	}

	override function set_looped(v:Bool):Bool {
		if (playing) {
			if (v && !inIntro) _channel.loops = 999;
			else _channel.loops = 0;
		}
		return looped = v;
	}

	override function set_loopTime(v:Float):Float {
		if (playing && !inIntro) _channel.loopTime = v;
		return loopTime = v;
	}

	override function set_endTime(v:Null<Float>):Null<Float> {
		if (playing) {
			if (v != null && v > 0 && v < _length && !inIntro) _channel.endTime = v;
			else _channel.endTime = null;
		}
		return endTime = v;
	}

	override function get_offset():Float return _offset - (_musicData.offset ?? 0);
	override function set_offset(offset:Float):Float {
		offset += _musicData.offset ?? 0;

		if (offset == _offset) return _offset;
		_offset = offset;
		time = time;

		return offset - (_musicData.offset ?? 0);
	}
}