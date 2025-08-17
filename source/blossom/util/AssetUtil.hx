package blossom.util;

import lime.app.Future;
import lime.app.Promise;
import lime.utils.Bytes;

import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.AssetType;
import openfl.utils.Assets;

final class AssetUtil {
	inline public static function gc() {
		#if cpp
		cpp.vm.Gc.compact();
		cpp.vm.Gc.run(true);
		#elseif hl
		hl.Gc.major();
		#end
	}

	inline public static function exists(path:String) return Assets.exists(path);

	// Sounds
	public static var usedSounds:Array<String> = [];
	private static var streamedSounds:Map<String, Array<Sound>> = [];

	inline public static function getMusic(path:String) return getSound(path, true);
	public static function getSound(path:String, streamed = false):Null<Sound> {
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

	public static function decacheSound(path:String, force:Bool = true) @:privateAccess {
		var sound = Assets.cache.getSound(path);
		if (sound == null || (usedSounds.contains(path) && !force)) return;

		sound.__buffer.dispose();
		sound.__buffer = null;
		Assets.cache.removeSound(path);
	}

	public static function soundExists(path:String):Bool return Assets.exists(path, SOUND) || Assets.exists(path, MUSIC);
	public static function soundCached(path:String):Bool return Assets.cache.hasSound(path);

	// Graphics
	public static var usedGraphics:Array<String> = [];

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
}