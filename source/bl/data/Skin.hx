package bl.data;

import hxjson5.Json5;
import openfl.display.BlendMode;
import flixel.util.typeLimit.*;

import bl.play.component.Countdown.CountdownData;
import bl.util.ParseUtil;
import bl.BLSprite;

import bl.Paths.EXT_SOUND;
import bl.Paths.EXT_IMAGE;
import bl.Paths.fixExt;

typedef NoteskinAnimData = BLAnimData & {?colors:Array<Array<FlxColor>>}

typedef NoteskinData = {
	image:String,
	?antialiasing:Bool,
	?animations:Array<NoteskinAnimData>,
	?colors:Array<Array<FlxColor>>,
	?scales:Array<Array<Float>>,
	?angles:Array<Float>,
	?offsets:Array<Array<Float>>,
	?blends:Array<Null<BlendMode>>
}

typedef Noteskin = Map<String, NoteskinData>;

class Skin {
	public static var SKIN_FALLBACK(get, null):Skin;
	static final cache:Map<String, Skin> = [];

	static function get_SKIN_FALLBACK():Skin return SKIN_FALLBACK ?? (SKIN_FALLBACK = getSkin('default'));

	public static function clearCache() {
		for (id in cache.keys()) AssetUtil.decacheText(Paths.skin(id, 'skin.json'));
		cache.clear();
		SKIN_FALLBACK = null;
	}

	public static function getSkin(id:String, reload:Bool = false):Skin {
		id = Paths.formatPath(id);
		if (cache.exists(id) && !reload) return cache.get(id);

		final path = Paths.skin(id, 'skin.json');
		if (!AssetUtil.textExists(path)) {
			trace('$path doesn\'t exists, returning a temporary Skin');
			return new Skin(id);
		}

		final data = reload ? AssetUtil.regetText(path) : AssetUtil.getText(path);
		final skin = new Skin(id, Json5.parse(data));
		cache.set(id, skin);

		return skin;
	}

	public final id:String;

	public var name:String;
	public var creator:Null<String>;
	public var description:Null<String>;
	public var countdowns(get, null):Null<Array<CountdownData>>;
	function get_countdowns() return countdowns ?? (SKIN_FALLBACK != this ? SKIN_FALLBACK.countdowns : null);

	public var missSounds(get, null):Null<Array<String>>;
	function get_missSounds() {
		if (missSounds != null) return missSounds;
		else if (_missSoundDatas == null) return SKIN_FALLBACK.missSounds;
		return missSounds = [for (key in cast(_missSoundDatas, Array<Dynamic>)) sound(key)];
	}

	private var _spriteDatas:Dynamic;
	private var _missSoundDatas:Dynamic;
	private var _noteDatas:Map<Int, Dynamic> = [];

	private var _sprites:Map<String, BLSpriteData> = [];
	private var _notes:Map<Int, Noteskin> = [];
	private var _paths:Map<String, Bool> = [];
	private var _countdowns:Array<CountdownData>;

	public function new(?id:String, ?data:Dynamic) {
		this.id = id ?? 'unknown';

		if (data != null) {
			name = data.name ?? id;
			creator = data.creator;
			description = data.description;
			countdowns = cast data.countdowns;
			_missSoundDatas = data.missSounds;
			if (data.sprites != null && Type.typeof(data.sprites) == TObject) _spriteDatas = data.sprites;
			for (field in Reflect.fields(data)) if (field.charAt(field.length - 1) == 'k') {
				var noteData = Reflect.field(data, field), keys = Std.parseInt(field.substr(0, field.length - 1));
				if (keys != null && Type.typeof(noteData) == TObject) _noteDatas.set(keys, noteData);
			}
		}
		else
			name = id;
	}

	public function getPath(key:String):String {
		if (SKIN_FALLBACK != this) {
			if (!_paths.exists(key)) _paths.set(key, AssetUtil.exists(Paths.skin(id, key)));
			if (_paths.get(key) == false) return SKIN_FALLBACK.getPath(key);
		}
		return Paths.skin(id, key);
	}

	public function image(key:String):String
		return getPath(fixExt(key, EXT_IMAGE));

	public function sound(key:String):String
		return getPath(fixExt(key, EXT_SOUND));

	public function getSpriteData(key:String, unsafe = false):BLSpriteData {
		var sprite = _sprites.get(key);
		if (sprite != null) return sprite;
		else if (_spriteDatas == null && SKIN_FALLBACK != this) {
			final fallback = SKIN_FALLBACK.getSpriteData(key, true);
			if (fallback != null) return fallback;
		}

		var data = Reflect.field(_spriteDatas, key);
		if (data == null) {
			if (unsafe) return null;
			sprite = {image: image(key)};
		}
		else {
			sprite = {
				image: image(data.image is String ? data.image : key), antialiasing: data.antialiasing, animations: data.animations,
				color: ParseUtil.parseColor(data.color), blend: ParseUtil.parseBlendMode(data.blend)
			};
			sprite.scale = data.scale is Float ? [data.scale, data.scale] : (cast data.scale ?? 1);
			if (data.scrollFactor != null) sprite.scrollFactor = data.scrollFactor is Float ? [data.scrollFactor, data.scrollFactor] : cast data.scrollFactor;
			if (data.zoomFactor != null) sprite.zoomFactor = data.zoomFactor is Float ? [data.zoomFactor, data.zoomFactor] : cast data.zoomFactor;
			if (data.offset != null) sprite.offset = cast data.offset;
		}

		_sprites.set(key, sprite);
		return sprite;
	}

	public function getNoteskin(keys:Int = 4):Noteskin {
		var notes = _notes.get(keys);
		if (notes != null) return notes;

		final data = _noteDatas.get(keys);
		final fallback = SKIN_FALLBACK != this ? SKIN_FALLBACK.getNoteskin(keys) : null;
		if (data == null && fallback != null) return fallback;

		notes = [];
		for (field in Reflect.fields(data)) {
			final props = Reflect.field(data, field);

			final skinData:NoteskinData = {image: image(props.image is String ? props.image : field), animations: [], antialiasing: props.antialiasing};

			// animations.colors
			for (animData in cast(props.animations, Array<Dynamic>)) {
				final animation:Dynamic = animData;
				animation.colors = _parseColors(animData, keys, false);
				skinData.animations.push(cast animation);
			}

			// scales
			if (Std.isOfType(props.scales, Array)) {
				skinData.scales = [for (scale in cast(props.scales, Array<Dynamic>)) scale is Float ? [scale, scale] : cast scale];
				if (skinData.scales.length >= keys) skinData.scales.resize(4);
				else for (i in skinData.scales.length...keys) skinData.scales[i] = [1.0, 1.0];
			}
			else {
				final scales:Array<Float> = (props.scale is Float ? [props.scale, props.scale] : cast props.scale) ?? [1.0, 1.0];
				skinData.scales = [for (i in 0...keys) scales];
			}

			// colors
			skinData.colors = _parseColors(props, keys, true);

			// angles
			if (Std.isOfType(props.angles, Array)) {
				skinData.angles = [for (angle in cast(props.angles, Array<Dynamic>)) angle is Float ? angle : 0];
				if (skinData.angles.length >= keys) skinData.angles.resize(4);
				else for (i in skinData.angles.length...keys) skinData.angles[i] = 0;
			}
			else {
				final angle:Float = props.angle is Float ? cast props.angle : 0;
				skinData.angles = [for (i in 0...keys) angle];
			}

			// offsets
			if (Std.isOfType(props.offsets, Array)) {
				skinData.offsets = [for (offset in cast(props.offsets, Array<Dynamic>)) cast offset];
				if (skinData.offsets.length >= keys) skinData.offsets.resize(4);
				else for (i in skinData.offsets.length...keys) skinData.offsets[i] = [0.0, 0.0];
			}
			else {
				final offsets:Array<Float> = cast props.offset ?? [0.0, 0.0];
				skinData.offsets = [for (i in 0...keys) offsets];
			}

			// blends
			if (Std.isOfType(props.blends, Array)) {
				skinData.blends = [for (blend in cast(props.blends, Array<Dynamic>)) ParseUtil.parseBlendMode(blend, null)];
				if (skinData.blends.length >= keys) skinData.blends.resize(4);
				else for (i in skinData.blends.length...keys) skinData.blends[i] = null;
			}
			else {
				final blend = ParseUtil.parseBlendMode(props.blend);
				skinData.blends = [for (i in 0...keys) blend];
			}

			notes.set(field, skinData);
		}

		// fallback
		if (fallback != null) {
			for (i => v in fallback) if (!notes.exists(i)) notes.set(i, Reflect.copy(v));
		}

		_notes.set(keys, notes);
		return notes;
	}

	inline function _parseColors(data:Dynamic, keys:Int, useDefault:Bool):Null<Array<Array<FlxColor>>> {
		var result:Array<Array<FlxColor>> = null;
		if (Std.isOfType(data.colors, Array)) {
			result = [
				for (colors in cast(data.colors, Array<Dynamic>)) [
					for (i in 0...3) colors[i] is Int ? ParseUtil.parseColor(colors[i]) : FlxColor.WHITE
				]
			];
			if (result.length >= keys) result.resize(4);
			else for (i in result.length...keys) result[i] = [FlxColor.RED, FlxColor.GREEN, FlxColor.BLUE];
		}
		else if (Std.isOfType(data.color, Array)) {
			final dataColors = cast(data.color, Array<Dynamic>);
			final colors = [for (i in 0...3) dataColors[i] is Int ? ParseUtil.parseColor(dataColors[i]) : FlxColor.WHITE];
			result = [for (i in 0...keys) colors];
		}
		else if (useDefault) {
			result = [for (i in 0...keys) [FlxColor.RED, FlxColor.GREEN, FlxColor.BLUE]];
		}

		return result;
	}
}