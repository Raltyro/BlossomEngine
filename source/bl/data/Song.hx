package bl.data;

import sys.FileSystem;

import hxjson5.Json5;

import openfl.media.Sound;

import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.util.FlxStringUtil;

import bl.audio.Music;
import bl.audio.SoundGroup;
import bl.util.ParseUtil;
import bl.Conductor.TimeChange;

using StringTools;

// meta.json
class Song {
	public static final DEFAULT_DIFFICULTY:String = 'normal'; // what difficulty should it counts as default and ignore as a formatted song
	public static final DEFAULT_DIFFICULTIES:Array<String> = ['easy', 'normal', 'hard']; // for PlayState.weekDiffs

	public final id:String;

	public var title:String;
	public var artist:Null<String>;
	public var album:Null<String>;
	public var charter:Null<String>;

	public var ratings:Map<String, Int> = [];
	public var difficulties:Array<String> = [];
	public var defaultDifficulty:String;

	public var volume:Float = 1;
	public var offset:Float = 0;
	public var timeChanges:Array<TimeChange> = [];
	public var voices:Array<String> = ['']; // leave this in for default
	public var previewStart:Float = 0;
	public var previewDuration:Float = 15000;

	public var icon:Null<String>;
	public var color:FlxColor = FlxColor.WHITE;

	private var isVanilla:Bool;
	private var vanillaPlayData:Dynamic;

	public static function parseEntry(id:String, reload:Bool = true):Song {
		id = Paths.formatPath(id);

		final metaPath = Paths.songsSuffix('$id/meta.json');
		if (!AssetUtil.textExists(metaPath)) {
			trace('$metaPath doesn\'t exists, returning an temporary Song');
			return new Song(id);
		}

		var vanillaMetaPath = Paths.songsSuffix('$id/v-meta.json'), vanillaMetaData:String = null;
		if (AssetUtil.textExists(vanillaMetaPath) || AssetUtil.textExists(vanillaMetaPath = Paths.songsSuffix('$id/metadata.json')))
			vanillaMetaData = reload ? AssetUtil.regetText(vanillaMetaPath) : AssetUtil.getText(vanillaMetaPath);

		var data:String = reload ? AssetUtil.regetText(metaPath) : AssetUtil.getText(metaPath);
		return new Song(id, Json5.parse(data), vanillaMetaData != null ? Json5.parse(vanillaMetaData) : null);
	}

	public static function getDefaultDifficultyFromDiffs(difficulties:Array<String>):String
		return (difficulties != null && difficulties.length != 0) ? difficulties[Math.floor((difficulties.length - 1) / 2)] : 'normal';

	public function new(id:String, ?data:Dynamic, ?vanillaMeta:Dynamic) {
		this.id = id;
		title = data?.title ?? vanillaMeta?.songName ?? id;

		if (isVanilla = vanillaMeta != null) {
			artist = vanillaMeta.artist;
			charter = vanillaMeta.charter;
			if (Type.typeof(vanillaMeta.timeChanges) == TObject) ParseUtil.parseTimeChanges(vanillaMeta.timeChanges, timeChanges);

			vanillaPlayData = vanillaMeta.playData;
			difficulties = vanillaPlayData.difficulties;
			album = vanillaPlayData.album;
			previewDuration = vanillaPlayData.previewEnd - (previewStart = vanillaPlayData.previewStart);

			if (Reflect.isObject(vanillaPlayData.ratings)) {
				for (difficulty in Reflect.fields(vanillaPlayData.ratings)) {
					final val = Reflect.field(vanillaPlayData.ratings, difficulty);
					ratings.set(difficulty, val is Int ? cast val : 0);
				}
			}
		}

		if (data != null) {
			artist = artist ?? data.artist;
			album = album ?? data.album;
			charter = charter ?? data.charter;
			color = ParseUtil.parseColor(data.color);

			if (data.offset is Float) offset = data.offset;
			if (data.volume is Float) volume = data.volume;
			if (data.previewStart is Float) previewStart = data.previewStart;
			if (data.previewDuration is Float) previewDuration = data.previewDuration;
			if (data.defaultDifficulty is String) defaultDifficulty = data.defaultDifficulty;
			if (data.icon is String) icon = data.icon;
			if (Type.typeof(data.voices) == TObject) voices = cast data.voices;
			if (Type.typeof(data.difficulties) == TObject) difficulties = cast data.difficulties;
			if (Reflect.isObject(data.ratings)) {
				for (difficulty in Reflect.fields(data.ratings)) {
					final val = Reflect.field(data.ratings, difficulty);
					ratings.set(difficulty, val is Int ? cast val : 0);
				}
			}

			if (timeChanges.length == 0) {
				if (Type.typeof(data.timeChanges) == TObject) ParseUtil.parseTimeChanges(data.timeChanges, timeChanges);
				else if (data.bpm is Float) timeChanges.push({bpm: data.bpm});
			}
		}
		else 
			timeChanges.push(Conductor.DEFAULT_TIMECHANGE);

		if (difficulties.length == 0)
		#if desktop
		// probably deprecate this, this isnt ok
		{
			var chartsPath = Paths.songsSuffix('$id/charts');
			if (!AssetUtil.exists(chartsPath, true)) difficulties.push('normal');
			else for (v in FileSystem.readDirectory(chartsPath)) if (SongChart.isPathValid(v)) difficulties.push(Paths.base(Paths.withoutExt(v)));
		}
		#else
			difficulties.push('normal');
		#end
	}

	private var charts:Map<String, SongChart> = [];
	private function _getChart(chart:SongChart, path:String):Bool {
		for (ext => parser in SongChart.PARSERS) if (AssetUtil.textExists('$path.$ext')) {
			final data = AssetUtil.regetText('$path.$ext');
			if (chart._created = parser.parseChart(chart, data)) return true;
		}
		return false;
	}

	public function getChart(?difficulty:String):SongChart {
		if (difficulty != null) {
			var chart = charts.get(difficulty);
			if (chart == null) charts.set(difficulty, chart = new SongChart(this, difficulty));
			else if (chart._created) return chart;

			if (isVanilla && difficulties.contains(difficulty) && _getChart(chart, Paths.songsSuffix('$id/chart'))) return chart;
			else {
				if (_getChart(chart, Paths.songsSuffix('$id/charts/$difficulty'))) return chart;
				else if (!isVanilla && difficulty == 'normal' && _getChart(chart, Paths.songsSuffix('$id/chart'))) return chart;
			}
		}

		final internalDefaultDiff = getDefaultDifficultyFromDiffs(difficulties);
		var defaultDiff = (defaultDifficulty == null || difficulty == defaultDifficulty) ?
			(difficulty == internalDefaultDiff ? 'normal' : internalDefaultDiff) : defaultDifficulty;

		if (defaultDiff == difficulty || difficulty == internalDefaultDiff) {
			if (difficulty == 'normal') {
				trace('Can\'t get default difficulty $defaultDiff for $id');
				return null;
			}
			else defaultDiff = 'normal';
		}

		if (difficulty != null) trace('Can\'t get $difficulty for $id, getting $defaultDiff instead');
		return getChart(defaultDiff);
	}

	function buildSound(asset:FlxSoundAsset):Music
		return cast FlxG.sound.list.add(new Music().loadMusic({music: asset, volume: volume, offset: offset, looped: false}));

	public function getInstrumental(stream:Bool = true):Sound return AssetUtil.getSound(Paths.inst(id), stream);
	public function loadInstrumental():Future<Sound> return AssetUtil.loadSound(Paths.inst(id));

	public function buildInstrumental(?stream:Bool):Music
		return buildSound(getInstrumental(stream));

	public function getInstPath(?suffix:String):String
		return Paths.inst(id, (suffix != null && suffix.trim().length == 0) ? null : '-$suffix');

	public function getVoicePath(?voice:String):String
		return Paths.voices(id, (voice != null && voice.trim().length == 0) ? null : '-$voice');

	public function getVoicePaths(?array:Array<String>):Array<String> {
		if (array == null) array = [];
		for (voice in voices) {
			final path = getVoicePath(voice);
			if (AssetUtil.soundExists(path)) array.push(path);
		}
		return array;
	}

	public function getVoices(?array:Array<Sound>):Array<Sound> {
		if (array == null) array = [];
		for (path in getVoicePaths()) array.push(AssetUtil.getSound(path));
		return array;
	}

	public function loadVoices(?array:Array<Sound>):Future<Array<Sound>> {
		if (array == null) array = [];

		final paths = getVoicePaths();
		if (paths.length == 0) return Future.withValue(array);

		var promise = new Promise<Array<Sound>>(), got:Int = 0;
		for (path in paths) AssetUtil.loadSound(path).onComplete((sound) -> {
			array.push(sound);
			if (++got == paths.length) promise.complete(array);
		}).onError((e) -> {
			trace(e);
			if (++got == paths.length) promise.complete(array);
		});

		return promise.future;
	}

	public function buildVoices(?group:SoundGroup):SoundGroup {
		if (group == null) group = new SoundGroup();
		for (sound in getVoices()) group.add(buildSound(sound));
		return group;
	}

	public function getVoice(voice:String):Sound
		return AssetUtil.getSound(getVoicePath(voice));

	public function buildVoice(voice:String):Music
		return buildSound(getVoice(voice));

	public function toString():String {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("id", id),
			LabelValuePair.weak("title", title),
			LabelValuePair.weak("artist", artist),
			LabelValuePair.weak("difficulties", difficulties),
			LabelValuePair.weak("defaultDifficulty", defaultDifficulty)/*,
			LabelValuePair.weak("icon", icon),
			LabelValuePair.weak("color", color),
			LabelValuePair.weak("bpm", bpm)*/
		]);
	}
}

enum abstract ChartCharacterID(Int) from Int to Int {
	var BF = -1;
	var DAD = -2;
	var GF = -3;
}

@:structInit
class ChartCharacter {
	public var ID:ChartCharacterID = 0;
	public var character:String;

	function toString():String {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("ID", ID),
			LabelValuePair.weak("character", character)
		]);
	}
}

@:structInit
class ChartPlayfield {
	public var ID:ChartCharacterID = 0;
	public var keys:Int = 4;
	public var speed:Float = 1;
	public var notes:Array<ChartNote>;
	@:optional public var voice:Null<String>;
	@:optional public var skin:Null<String>;

	public var scale:Float = 1;
	@:optional public var x:Null<Float>;
	@:optional public var y:Null<Float>;

	public var flipX:Bool = false;
	public var flipY:Bool = false;

	public var visible:Bool = true;

	function toString():String {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("ID", ID),
			LabelValuePair.weak("speed", speed),
			LabelValuePair.weak("voice", voice),
			LabelValuePair.weak("scale", scale),
			LabelValuePair.weak("x", x),
			LabelValuePair.weak("y", y),
			LabelValuePair.weak("notes", notes)
		]);
	}
}

typedef ChartNote = {
	time:Float,
	column:Int,
	?duration:Float,
	?type:String
}

typedef ChartEvent = {
	?time:Float,
	event:String,
	?params:Array<Dynamic>
}

// charts/difficulty.json || chart.json || charts/difficulty.blc || chart.blc
@:allow(bl.data.Song)
class SongChart {
	public static final PARSERS:Map<String, ChartParser> = [
		'json' => new bl.data.parser.FNFJSONParser(),
		'blc' => new bl.data.parser.BlossomParser(),
		'sm' => new bl.data.parser.StepmaniaParser(),
	];

	public static function isPathValid(path:String):Bool {
		path = Paths.ext(path);
		for (ext => parser in PARSERS) if (path == ext) return true;
		return false;
	}

	public final song:Song;
	public final difficulty:String;

	public var volume:Float = 1;
	public var offset:Float = 0;
	public var initialBPM(get, never):Float; function get_initialBPM() return timeChanges[0].bpm;
	public var timeChanges(get, set):Array<TimeChange>;
	private var _timeChanges:Array<TimeChange>;
	function get_timeChanges() return _timeChanges == null ? song.timeChanges : _timeChanges;
	function set_timeChanges(timeChanges) return _timeChanges = timeChanges;

	public var inst:Null<String>;
	public var stage:String;
	public var characters:Array<ChartCharacter>;
	public var playfields:Array<ChartPlayfield>;
	public var events:Array<ChartEvent>;

	private var _created:Bool = false;

	function buildSound(asset:FlxSoundAsset):Music
		return cast FlxG.sound.list.add(new Music().loadMusic({music: asset, volume: volume, offset: offset, looped: false}));

	public function getInstrumental(stream:Bool = true):Sound return AssetUtil.getSound(song.getInstPath(inst), stream);
	public function loadInstrumental():Future<Sound> return AssetUtil.loadSound(song.getInstPath(inst));
	public function buildInstrumental(?stream:Bool):Music return buildSound(getInstrumental(stream));

	public function getVoicePaths(?array:Array<String>):Array<String> {
		if (array == null) array = [];
		for (playfield in playfields) {
			final path = song.getVoicePath(playfield.voice);
			if (array.indexOf(path) == -1 && AssetUtil.soundExists(path)) array.push(path);
		}
		return array;
	}

	public function getVoices(?array:Array<Sound>):Array<Sound> {
		if (array == null) array = [];
		for (path in getVoicePaths()) array.push(AssetUtil.getSound(path));
		return array;
	}

	public function loadVoices(?array:Array<Sound>):Future<Array<Sound>> {
		if (array == null) array = [];

		final paths = getVoicePaths();
		if (paths.length == 0) return Future.withValue(array);

		var promise = new Promise<Array<Sound>>(), got:Int = 0;
		for (path in paths) AssetUtil.loadSound(path).onComplete((sound) -> {
			array.push(sound);
			if (++got == paths.length) promise.complete(array);
		}).onError((e) -> {
			trace(e);
			if (++got == paths.length) promise.complete(array);
		});

		return promise.future;
	}

	public function buildVoices(?group:SoundGroup):SoundGroup {
		if (group == null) group = new SoundGroup();
		for (sound in getVoices()) group.add(buildSound(sound));
		return group;
	}

	public function getVoice(voice:String):Sound
		return AssetUtil.getSound(song.getVoicePath(voice));

	public function buildVoice(voice:String):Music
		return buildSound(getVoice(voice));

	public function new(song:Song, ?difficulty:String) {
		this.song = song;
		this.difficulty = difficulty ?? Song.DEFAULT_DIFFICULTY;

		volume = song.volume;
		offset = song.offset;
	}
}

class ChartParser {
	public function new() {}
	public function parseChart(chart:SongChart, data:String):Bool return false;
}