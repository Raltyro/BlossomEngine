package blossom.backend.util;

import lime.app.Future;
import lime.app.Promise;
import lime.utils.Bytes;

import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.AssetType;
import openfl.utils.Assets;

import flixel.graphics.FlxGraphic;

using StringTools;

final class AssetUtil {
	inline public static function gc() {
		#if cpp
		cpp.vm.Gc.run(true);
		cpp.vm.Gc.compact();
		#elseif hl
		hl.Gc.major();
		#end
	}

	inline public static function exists(path:String) return Assets.exists(path);

	// Sounds
	public static var usedSounds:Array<String> = [];
	private static var streamedSounds:Map<String, Array<Sound>> = [];

	inline public static function getMusic(path:String) return getSound(path, true);
	public static function getSound(path:String, streamed = false):Sound {
		var sound = Assets.cache.getSound(path);
		if (sound != null) usedSounds.push(path);
		else if (soundExists(path)) {
			if (streamed && (sound = Assets.getSound(path, false, true, false)) != null) {
				(streamedSounds[path] = streamedSounds[path] ?? []).push(sound);
				usedSounds.push(path);
			}
			else if ((sound = Assets.getSound(path, true, false)) != null)
				usedSounds.push(path);
		}

		return sound;
	}

	inline public static function loadMusic(path:String) return loadSound(path, true);
	public static function loadSound(path:String, streamed = false):Future<Sound> {
		var sound = Assets.cache.getSound(path);
		if (sound != null) {
			usedSounds.push(path);
			return Future.withValue(sound);
		}
		else if (soundExists(path)) {
			if (streamed && (sound = Assets.getSound(path, false, true, false)) != null) {
				(streamedSounds[path] = streamedSounds[path] ?? []).push(sound);
				usedSounds.push(path);
				return Future.withValue(sound);
			}

			final promise = new Promise<Sound>();

			Assets.loadSound(path, true).onComplete((sound) -> {
				usedSounds.push(path);
				promise.complete(sound);
			}).onError(promise.error).onProgress(promise.progress);

			return promise.future;
		}

		return Future.withValue(null);
	}

	public static function decacheSound(path:String, force = true):Bool @:privateAccess {
		final sound = Assets.cache.getSound(path);
		if (sound == null || (usedSounds.contains(path) && !force)) return false;

		sound.__buffer.dispose();
		sound.__buffer = null;
		Assets.cache.removeSound(path);

		return true;
	}

	public static function soundExists(path:String):Bool return Assets.exists(path, SOUND) || Assets.exists(path, MUSIC);
	public static function soundCached(path:String):Bool return Assets.cache.hasSound(path);

	// Graphics
	public static var usedGraphics:Array<String> = [];

	public static function getBitmap(path:String, hardware = true, useCache = true):BitmapData {
		var bitmap = Assets.cache.getBitmapData(path);
		if (bitmap != null || (graphicExists(path) && (bitmap = Assets.getBitmapData(path, useCache, hardware)) != null) && useCache)
			usedGraphics.push(path);

		return bitmap;
	}

	public static function loadBitmap(path:String, hardware = true, useCache = true):Future<BitmapData> {
		final bitmap = Assets.cache.getBitmapData(path);
		if (bitmap != null) {
			usedGraphics.push(path);
			return Future.withValue(bitmap);
		}
		else if (graphicExists(path)) {
			final promise = new Promise<BitmapData>();

			Assets.loadBitmapData(path, useCache, hardware).onComplete((bitmap) -> {
				if (useCache) usedGraphics.push(path);
				promise.complete(bitmap);
			}).onError(promise.error).onProgress(promise.progress);

			return promise.future;
		}

		return Future.withValue(null);
	}

	public static function getGraphic(path:String, persist = false, hardware = true):FlxGraphic {
		var graphic = FlxG.bitmap.get(path);
		if (graphic != null) {
			usedGraphics.push(path);
			return graphic;
		}

		final bitmap = getBitmap(path, hardware);
		if (bitmap == null) return null;

		graphic = FlxG.bitmap.add(bitmap, false, path);
		if (persist) {
			graphic.persist = true;
			graphic.destroyOnNoUse = false;
		}
		return graphic;
	}

	public static function registerGraphic(?bitmap:BitmapData, ?key:String, persist = false, ?hardware:Bool):FlxGraphic {
		final graphic = bitmap == null ? @:privateAccess FlxGraphic.createGraphic(null, key) :
			FlxGraphic.fromBitmapData(Assets.registerBitmapData(bitmap, key), false, key);

		if (hardware) BitmapDataUtil.toHardware(bitmap);
		if (persist) {
			graphic.persist = true;
			graphic.destroyOnNoUse = false;
		}
		if (key != null) usedGraphics.push(key);
		return graphic;
	}

	public static function loadGraphic(path:String, persist = false, hardware = true):Future<FlxGraphic> {
		var graphic = FlxG.bitmap.get(path);
		if (graphic != null) {
			usedGraphics.push(path);
			return Future.withValue(graphic);
		}

		final promise = new Promise<Null<FlxGraphic>>();
		loadBitmap(path, hardware).onComplete((bitmap) -> {
			if (bitmap == null) promise.complete(null);
			else {
				usedGraphics.push(path);
				promise.complete(registerGraphic(bitmap, path, persist));
			}
		}).onError(promise.error).onProgress(promise.progress);

		return promise.future;
	}

	public static function decacheGraphic(path:String, force = true):Bool @:privateAccess {
		if (usedGraphics.contains(path) && !force) return false;

		var graphic = FlxG.bitmap.get(path), bitmap:BitmapData;
		if (graphic != null) {
			if ((graphic.useCount > 0 || !graphic.destroyOnNoUse) && !force) return false;
			FlxG.bitmap._cache.remove(path);
			bitmap = graphic.bitmap;
		}
		else
			bitmap = Assets.cache.getBitmapData(path);

		Assets.cache.removeBitmapData(path);
		if (bitmap != null) {
			bitmap.__texture?.dispose();
			bitmap.dispose();
		}

		if (graphic != null) graphic.destroy();
		return true;
	}

	public static function graphicExists(path:String):Bool return Assets.exists(path, AssetType.IMAGE);
	public static function bitmapCached(path:String):Bool return Assets.cache.hasBitmapData(path);
	public static function graphicCached(path:String):Bool return FlxG.bitmap.get(path) != null;

	// Texts
	public static function getText(path:String):String return Assets.getText(path, true);
	public static function loadText(path:String):Future<String> return Assets.loadText(path, true);
	public static function decacheText(path:String) Assets.cache.removeText(path);
	public static function textExists(path:String):Bool return Assets.exists(path, TEXT);
	public static function textCached(path:String):Bool return Assets.cache.hasText(path);

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

	public static function clearUnused() @:privateAccess {
		var obj:FlxGraphic;
		for (key in FlxG.bitmap._cache.keys()) {
			if ((obj = FlxG.bitmap.get(key)) == null) FlxG.bitmap._cache.remove(key);
			else if (!key.startsWith("flixel") && !assetExcluded(key))
				decacheGraphic(key, false);
		}

		var i;
		for (path => sounds in streamedSounds) {
			i = sounds.length;
			while (i-- > 0) if (!usedSounds.contains(path) || soundCached(path)) {
				sounds[i].__buffer.dispose();
				sounds[i].__buffer = null;
				sounds.swapAndPop(i);
			}
		}

		gc();
	}

	public static function clearCache(force = false, ?excludes:Array<String>) @:privateAccess {
		final currentLevel = Paths.currentLevel ?? "shared", cache:openfl.utils.AssetCache = cast Assets.cache;

		var lib:String;
		function check(key:String) {
			if (excludes != null) for (exclude in excludes) if (key.startsWith(exclude)) return false;
			return (force || (lib = Paths.getLibrary(key)) != currentLevel && lib == "default") && !key.startsWith("flixel") && !assetExcluded(key);
		}

		for (key in cache.bitmapData.keys()) if (check(key)) decacheGraphic(key, true);
		for (key in cache.font.keys()) if (check(key)) cache.removeFont(key);
		for (key in cache.sound.keys()) if (check(key)) decacheSound(key, true);
		for (key in cache.text.keys()) if (check(key)) cache.removeText(key);
		for (key in cache.bytes.keys()) if (check(key)) cache.removeBytes(key);

		usedGraphics = [];
		usedSounds = [];

		if (force) {
			FlxG.bitmap.clearCache();
			FlxG.bitmap.reset();
		}

		gc();
	}
}