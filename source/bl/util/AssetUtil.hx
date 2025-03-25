package bl.util;

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#end

import sys.FileSystem;

import lime.utils.AssetType as LAssetType;
import lime.utils.Bytes;

import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.AssetType;
import openfl.utils.Assets;

import flixel.graphics.frames.FlxFramesCollection.FlxFrameCollectionType;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxGraphicAsset;

import bl.util.CoolUtil;

#if flxanimate
import flxanimate.animate.FlxAnim;
import flxanimate.data.SpriteMapData.AnimateAtlas;
import flxanimate.frames.FlxAnimateFrames;
#end

using StringTools;

class AssetUtil {
	inline public static function gc() {
		#if cpp
		Gc.run(true);
		#end
	}

	public static function exists(path:String, ?dir:Bool) {
		return dir == null ? Assets.exists(path) : FileSystem.exists(path = Paths.fix(path)) && FileSystem.isDirectory(path) == dir;
	}

	// Sounds
	public static var usedSounds:Array<String> = [];
	private static var streamSounds:Map<String, Array<Sound>> = [];

	public static function getMusic(path:String) return inline getSound(path, true);
	public static function getSound(path:String, stream:Bool = false):Null<Sound> {
		var snd = Assets.cache.getSound(path);
		if (snd == null && soundExists(path) && (snd = Assets.getSound(path, !stream, stream, false)) != null && stream)
			(streamSounds[path] = streamSounds[path] ?? []).push(snd);
		
		if (snd != null) usedSounds.push(path);
		return snd;
	}

	public static function loadSound(path:String):Future<Null<Sound>> {
		var snd = Assets.cache.getSound(path);
		if (snd != null) {
			usedSounds.push(path);
			return Future.withValue(snd);
		}
		else if (soundExists(path)) {
			final promise = new Promise<Null<Sound>>();
			Assets.loadSound(path, true).onComplete((snd) -> {
				usedSounds.push(path);
				promise.complete(snd);
			}).onError((_) -> promise.complete(null));
			return promise.future;
		}

		return Future.withValue(null);
	}

	public static function decacheSound(path:String, force:Bool = true) @:privateAccess {
		var snd = Assets.cache.getSound(path);
		if (snd == null || (usedSounds.contains(path) && !force)) return;

		snd.__buffer.dispose();
		snd.__buffer = null;
		Assets.cache.removeSound(path);
		gc();
	}

	public static function regetMusic(path:String) return inline regetSound(path);
	public static function regetSound(path:String, stream:Bool = false):Null<Sound> {
		decacheSound(path);
		return getSound(path, stream);
	}

	inline public static function reloadSound(path:String):Future<Null<Sound>> {
		decacheSound(path);
		return loadSound(path);
	}

	public static function soundExists(path:String):Bool return Assets.exists(path, AssetType.SOUND) || Assets.exists(path, AssetType.MUSIC);
	public static function soundCached(path:String):Bool return Assets.cache.hasSound(path);

	// Graphics
	public static var usedGraphics:Array<String> = [];

	public static function getBitmap(path:String, hardware:Bool = true):Null<BitmapData> {
		var bitmap = Assets.cache.getBitmapData(path);
		if (bitmap == null && graphicExists(path)) bitmap = Assets.getBitmapData(path, true, hardware);
		if (bitmap != null) usedGraphics.push(path);
		return bitmap;
	}

	public static function loadBitmap(path:String, hardware:Bool = true):Future<Null<BitmapData>> {
		var bitmap = Assets.cache.getBitmapData(path);
		if (bitmap != null) {
			usedGraphics.push(path);
			return Future.withValue(bitmap);
		}
		else if (graphicExists(path)) {
			final promise = new Promise<Null<BitmapData>>();
			Assets.loadBitmapData(path, true, hardware).onComplete((bitmap) -> {
				usedGraphics.push(path);
				promise.complete(bitmap);
			}).onError((_) -> promise.complete(null));
			return promise.future;
		}

		return Future.withValue(null);
	}

	public static function getGraphic(path:String, persist:Bool = false, hardware:Bool = true):Null<FlxGraphic> {
		var graphic = FlxG.bitmap.get(path);
		if (graphic != null) {
			usedGraphics.push(path);
			return graphic;
		}

		var bitmap = getBitmap(path, hardware);
		if (bitmap == null) return null;

		graphic = FlxG.bitmap.add(bitmap, false, path);
		if (persist) {
			graphic.persist = true;
			graphic.destroyOnNoUse = false;
		}
		return graphic;
	}

	public static function registerGraphic(?bitmap:BitmapData, ?key:String, persist:Bool = false, hardware:Bool = true):Null<FlxGraphic> {
		var graphic = bitmap == null ? @:privateAccess FlxGraphic.createGraphic(null, key) :
			FlxGraphic.fromBitmapData(Assets.registerBitmapData(bitmap, key ?? '', false, hardware), false, key);

		if (persist) {
			graphic.persist = true;
			graphic.destroyOnNoUse = false;
		}
		if (key != null) usedGraphics.push(key);
		return graphic;
	}

	public static function loadGraphic(path:String, persist:Bool = false, hardware:Bool = true):Future<Null<FlxGraphic>> {
		var graphic = FlxG.bitmap.get(path);
		if (graphic != null) return Future.withValue(graphic);
		graphic = registerGraphic(path, persist);

		final promise = new Promise<Null<FlxGraphic>>();
		loadBitmap(path, hardware).onComplete((bitmap) -> {
			if (bitmap == null) promise.complete(null);
			else {
				graphic.bitmap = bitmap;
				promise.complete(graphic);
			}
		});

		return promise.future;
	}

	public static function decacheGraphic(path:String, force:Bool = true) @:privateAccess {
		if (usedGraphics.contains(path) && !force) return;

		var graphic = FlxG.bitmap.get(path), bitmap:BitmapData;
		if (graphic != null) {
			if ((graphic.useCount > 0 || !graphic.destroyOnNoUse) && !force) return;

			FlxG.bitmap._cache.remove(path);
			var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(graphic);
			if (frames != null) {
				frames.destroy();

				var base:String = Paths.withoutExt(path);
				decacheText(path + ".xml");
				decacheText(path + "-anims.json");
			}
			bitmap = graphic.bitmap;
		}
		else bitmap = Assets.cache.getBitmapData(path);

		if (bitmap != null) {
			Assets.cache.removeBitmapData(path);
			if (bitmap.__texture != null) bitmap.__texture.dispose();
			if (bitmap.image != null && bitmap.image.data != null) bitmap.image.data = null;
			bitmap.image = null;
			bitmap.disposeImage();
			bitmap.dispose();
			bitmap.unlock();
			gc();
		}

		if (graphic != null) graphic.destroy();
	}

	inline public static function regetGraphic(path:String, persist:Bool = false, hardware:Bool = true):Null<FlxGraphic> {
		decacheGraphic(path);
		return getGraphic(path, persist, hardware);
	}

	inline public static function reloadGraphic(path:String, persist:Bool = false, hardware:Bool = true):Future<Null<FlxGraphic>> {
		decacheGraphic(path);
		return loadGraphic(path, persist, hardware);
	}

	public static function graphicExists(path:String):Bool return Assets.exists(path, AssetType.IMAGE);
	public static function bitmapCached(path:String):Bool return Assets.cache.hasBitmapData(path);
	public static function graphicCached(path:String):Bool return FlxG.bitmap.get(path) != null;

	public static function loadHTTPGraphic(path:String, persist:Bool = false, hardware:Bool = true):Future<FlxGraphic> {
		var graphic = FlxG.bitmap.get(path);
		if (graphic != null) return Future.withValue(graphic);
		graphic = registerGraphic(path, persist, hardware);

		return Bytes.loadFromFile(path).then((bytes) -> {
			graphic.bitmap = Assets.registerBitmapData(BitmapData.fromBytes(bytes), path, false, hardware);
			return Future.withValue(graphic);
		});
	}

	// SparrowAtlas
	public static function getSparrowAtlas(asset:FlxGraphicAsset, persist:Bool = false, hardware:Bool = true):Null<FlxAtlasFrames> {
		if (asset is BitmapData) throw "BitmapData is unsupported";

		final graphic = asset is String ? getGraphic(Paths.replaceExt(cast asset, "png")) : cast asset;
		var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(graphic);
		if (frames != null) return frames;
		else return FlxAtlasFrames.fromSparrow(graphic, getText(Paths.replaceExt(graphic.key, "xml")));
	}

	public static function loadSparrowAtlas(asset:FlxGraphicAsset, persist:Bool = false, hardware:Bool = true):Future<Null<FlxAtlasFrames>> {
		if (asset is BitmapData) throw "BitmapData is unsupported";

		inline function result(graphic:FlxGraphic, ?promise:Promise<Null<FlxAtlasFrames>>) {
			if (promise == null) promise = new Promise<Null<FlxAtlasFrames>>();

			var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(graphic);
			if (frames != null) promise.complete(frames);
			else {
				loadText(Paths.replaceExt(graphic.key, "xml")).onComplete((res) -> 
					promise.complete(FlxAtlasFrames.fromSparrow(graphic, res))
				);
			}
			return promise.future;
		}
		if (asset is FlxGraphic) return result(asset);

		final graphic = FlxG.bitmap.get(cast asset);
		if (graphic != null) return result(graphic);

		final promise = new Promise<Null<FlxAtlasFrames>>();
		loadGraphic(Paths.replaceExt(cast asset, "png"), persist, hardware).onComplete((graphic) -> {
			if (graphic == null) promise.complete(null);
			else result(graphic, promise);
		});

		return promise.future;
	}

	#if flxanimate
	// TextureAtlas
	public static function getTextureAtlas(asset:FlxGraphicAsset, persist:Bool = false, hardware:Bool = true):Null<FlxAnimateFrames> {
		if (asset is BitmapData) throw "BitmapData is unsupported";
		
		var mainGraphic:Null<FlxGraphic> = (asset is FlxGraphic) ? asset : null, jsons:Array<AnimateAtlas> = [], gotPath:String = null;
		final dir:String = mainGraphic != null ? Paths.dir(mainGraphic.assetsKey) : cast asset;

		inline function getJson(path):AnimateAtlas return cast haxe.Json.parse(getText(path).split(String.fromCharCode(0xFEFF)).join(''));

		if (Assets.exists(gotPath = '$dir/Animation.json')) getText(gotPath);
		if (Assets.exists(gotPath = '$dir/spritemap.json')) jsons.push(getJson(gotPath));
		else {
			var i = 0;
			while (Assets.exists(gotPath = '$dir/spritemap${++i}.json')) jsons.push(getJson(gotPath));
		}

		var frames = new FlxAnimateFrames();
		for (json in jsons) {
			final graphic = json?.meta?.image is String ? getGraphic('$dir/${json.meta.image}', persist, hardware) : mainGraphic;
			final atlas = FlxAnimateFrames.fromSpriteMap(json, graphic);
			if (atlas != null) frames.addAtlas(atlas);
		}
		return frames;
	}

	public static function loadTextureAtlas(asset:FlxGraphicAsset, persist:Bool = false, hardware:Bool = true):Future<Null<FlxAnimateFrames>> {
		if (asset is BitmapData) throw "BitmapData is unsupported";

		var mainGraphic:Null<FlxGraphic> = (asset is FlxGraphic) ? asset : null, gotPath:String = null;
		final dir:String = mainGraphic != null ? Paths.dir(mainGraphic.assetsKey) : cast asset;

		var jsons:Array<AnimateAtlas> = [], graphics:Map<Int, FlxGraphic> = [], futures1:Array<Future<String>> = [], futures2:Array<Future<Null<FlxGraphic>>> = [];
		function put(res) {
			final json = haxe.Json.parse(res.split(String.fromCharCode(0xFEFF)).join(''));
			final idx = jsons.push(json);
			if (json?.meta?.image is String)
				futures2.push(loadGraphic('$dir/${json.meta.image}', persist, hardware).onComplete((graphic) -> graphics.set(idx, graphic)));
		}

		if (Assets.exists(gotPath = '$dir/Animation.json')) futures1.push(loadText(gotPath));
		if (Assets.exists(gotPath = '$dir/spritemap.json')) futures1.push(loadText(gotPath).onComplete(put));
		else {
			var i = 0;
			while (Assets.exists(gotPath = '$dir/spritemap${++i}.json')) futures1.push(loadText(gotPath).onComplete(put));
		}

		final promise = new Promise<Null<FlxAnimateFrames>>();
		CoolUtil.chainFutures(futures1).onComplete((_) -> CoolUtil.chainFutures(futures2).onComplete((_) -> {
			var frames = new FlxAnimateFrames();
			for (i => json in jsons) {
				final atlas = FlxAnimateFrames.fromSpriteMap(json, graphics.get(i) ?? mainGraphic);
				if (atlas != null) frames.addAtlas(atlas);
			}
			promise.complete(frames);
		}));

		return promise.future;
	}
	#end

	// Texts (i made this for a reason)
	private static var texts:Map<String, String> = [];

	public static function getText(path:String):Null<String> {
		final sym = Paths.stripLibrary(path).toLowerCase();
		if (texts.exists(sym)) return texts.get(sym);
		if (!textExists(path)) return null;

		final res = Assets.getText(path);
		texts.set(sym, res);
		return res;
	}

	public static function loadText(path:String):Future<Null<String>> {
		final sym = Paths.stripLibrary(path).toLowerCase();
		if (texts.exists(sym)) return Future.withValue(texts.get(sym));
		if (!textExists(path)) return Future.withValue(null);

		final promise = new Promise<Null<String>>();

		Assets.loadText(path).onComplete((res) -> {
			texts.set(sym, res);
			promise.complete(res);
		}).onError((_) -> promise.complete(null));

		return promise.future;
	}

	public static function decacheText(path:String) texts.remove(Paths.stripLibrary(path).toLowerCase());

	public static function regetText(path:String):Null<String> {
		decacheText(path);
		return getText(path);
	}

	public static function reloadText(path:String):Future<Null<String>> {
		decacheText(path);
		return loadText(path);
	}

	public static function textExists(path:String):Bool {	
		final library = Assets.getLibrary(Paths.getLibrary(path)), sym = Paths.stripLibrary(path);
		return library != null && library.exists(sym, LAssetType.TEXT) && library.isLocal(sym, LAssetType.TEXT);
	}
	public static function textCached(path:String):Bool return texts.exists(Paths.stripLibrary(path));

	// Cache
	public static var keyExclusions:Array<String> = [];

	public static function excludeAsset(key:String) {
		for (v in keyExclusions) if (key.endsWith(v)) return;
		keyExclusions.push(key);
	}

	public static function unexcludeAsset(key:String) {
		for (v in keyExclusions) if (key.endsWith(v)) keyExclusions.remove(v);
	}

	public static function assetExcluded(key:String):Bool {
		for (v in keyExclusions) if (key.endsWith(v)) return true;
		return false;
	}

	public static function clearLibrary(library:String, force:Bool = false) @:privateAccess {
		var lib = Assets.getLibrary(library);
		for (key in lib.types.keys()) {
			if (assetExcluded(key)) continue;
			var path = library == 'default' ? key : '$library:$key';

			switch (lib.types.get(key)) {
				case LAssetType.IMAGE: decacheGraphic(path, force);
				case LAssetType.SOUND | LAssetType.MUSIC: decacheSound(path, force);
				case LAssetType.TEXT | LAssetType.BINARY: decacheText(path);
				default:
			}
		}

		#if cpp Gc.compact() #else gc() #end;
	}

	public static function clearUnused() @:privateAccess {
		var obj:FlxGraphic;
		for (key in FlxG.bitmap._cache.keys()) {
			if ((obj = FlxG.bitmap.get(key)) == null) FlxG.bitmap._cache.remove(key);
			else if (obj.useCount < 1 && obj.destroyOnNoUse && !key.startsWith("flixel/") && !key.startsWith("flixel\\") && !assetExcluded(key))
				decacheGraphic(key, false);
		}

		for (path => snds in streamSounds) for (snd in snds) {
			if (!usedSounds.contains(path) || soundCached(path)) @:privateAccess {
				snd.__buffer.dispose();
				snd.__buffer = null;
				snds.remove(snd);
				gc();
			}
		}

		#if cpp Gc.compact() #else gc() #end;
	}

	public static function clearCache(force:Bool = false, ?exclude:Array<String>) @:privateAccess {
		if (exclude == null) exclude = [];

		var currentLevel = Paths.currentLevel ?? "shared";
		for (lib in lime.utils.Assets.libraries.keys())
			if (((lib != "default" && lib != currentLevel) || force) && !exclude.contains(lib)) clearLibrary(lib, force);

		usedGraphics = [];
		usedSounds = [];
		if (force) {
			FlxG.bitmap.clearCache();
			FlxG.bitmap.reset();
			texts = [];
			gc();
		}
	}
}