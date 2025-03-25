package bl;

import haxe.io.Path;

#if sys
import sys.FileSystem;
#end

#if !macro
import openfl.utils.Assets;
#end

import openfl.utils.AssetType;

using StringTools;

class Paths {
	public static final EXT_SOUND:String = 'ogg';
	public static final EXT_IMAGE:String = 'png';
	public static final EXT_VIDEO:String = 'mp4';

	inline public static function fixExt(file:String, defaultExt:String):String return Path.extension(file) == '' ? '$file.$defaultExt' : file;

	public static var currentLevel:Null<String> = null;
	inline public static function setCurrentLevel(?name:String):Void
		currentLevel = name == null ? null : name.toLowerCase();

	public static function stripLibrary(path:String):String
		return path.substr(path.indexOf(':') + 1);

	public static function getLibrary(path:String):String {
		var idx = path.indexOf(':');
		return if (idx == -1) 'default'; else path.substr(0, idx);
	}

	static function getPath(file:String, ?type:AssetType, ?library:String):String {
		#if macro
		return getLibraryPath(file, library);
		#else
		if (library != null || library == 'default') return getLibraryPath(file, library);
		if (currentLevel != null) {
			var levelPath:String = getLibraryPath(file, currentLevel);
			if (Assets.exists(levelPath, type)) return levelPath;
		}

		var sharedPath:String = getLibraryPathForce(file, 'shared');
		if (Assets.exists(sharedPath, type)) return sharedPath;

		return getDefaultPath(file);
		#end
	}

	public static function getLibraryPath(file:String, library = 'default'):String
		return if (library == 'default') getDefaultPath(file); else getLibraryPathForce(file, library);

	inline static function getLibraryPathForce(file:String, library:String):String return '$library:assets/$library/$file';
	inline static function getDefaultPath(file:String):String return 'assets/$file';

	public static function file(file:String, type:AssetType = TEXT, ?library:String):String
		return getPath(file, type, library);

	public static function txt(key:String, ?library:String):String
		return getPath(fixExt('data/$key', 'txt'), TEXT, library);

	public static function xml(key:String, ?library:String):String
		return getPath(fixExt('data/$key', 'xml'), TEXT, library);

	public static function json(key:String, ?library:String):String
		return getPath(fixExt('data/$key', 'json'), TEXT, library);

	public static function character(key:String, ?library:String):String
		return getPath(fixExt('data/characters/$key', 'json'), TEXT, library);

	public static function frag(key:String, ?library:String):String
		return getPath(fixExt('data/shaders/$key', 'frag'), TEXT, library);

	public static function vert(key:String, ?library:String):String
		return getPath(fixExt('data/shaders/$key', 'vert'), TEXT, library);

	public static function sound(key:String, ?library:String):String
		return getPath(fixExt('sounds/$key', EXT_SOUND), SOUND, library);

	#if !macro
	public static function soundRandom(key:String, min:Int, max:Int, ?library:String):String
		return inline sound(key + FlxG.random.int(min, max), library);
	#end

	public static function music(key:String, ?library:String):String
		return getPath(fixExt('music/$key', EXT_SOUND), MUSIC, library);

	public static function video(key:String, ?library:String):String
		return getPath(fixExt('videos/$key', EXT_VIDEO), BINARY, library);

	public static function mesh(key:String, ?library:String):String
		return getPath(fixExt('meshes/$key', 'obj'), BINARY, library);

	// Used for songs and weeks
	static final invalidChars = ~/[~&\\;:<>#]+/g;
	static final hideChars = ~/[.,'"%?!]+/g;
	public static function formatPath(path:String):String
		return hideChars.split(invalidChars.split(path).join('-')).join('').toLowerCase();

	public static function songsSuffix(suffix:String, ?song:String):String
		return 'songs:assets/songs/' + (song != null ? '${formatPath(song)}/' : '') + suffix;

	public static function voices(song:String, ?suffix:String = ''):String
		return inline songsSuffix(fixExt('Voices$suffix', EXT_SOUND), song);

	public static function inst(song:String, ?suffix:String = ''):String
		return inline songsSuffix(fixExt('Inst$suffix', EXT_SOUND), song);

	public static function skin(id:String, key:String):String
		return getLibraryPathForce('${formatPath(id)}/$key', 'skins');

	public static function image(key:String, ?library:String):String
		return getPath(fixExt('images/$key', EXT_IMAGE), IMAGE, library);

	public static function atlas(key:String, ?library:String):String
		return getLibraryPath('images/$key', library);

	public static function font(key:String):String {
		#if !macro
		if (Path.extension(key) == '') return Assets.exists('assets/fonts/$key.otf', FONT) ? 'assets/fonts/$key.otf' : 'assets/fonts/$key.ttf';
		#end
		return 'assets/fonts/$key';
	}

	inline public static function base(x:String)
		return Path.withoutDirectory(x);
	
	inline public static function dir(x:String)
		return Path.directory(x);

	inline public static function ext(x:String)
		return Path.extension(x).toLowerCase();
	
	inline public static function withoutExt(x:String)
		return Path.withoutExtension(x);

	inline public static function isAbsolute(path:String)
		return Path.isAbsolute(path);

	public static function replaceExt(x:String, ext:String)
		return '${Path.withoutExtension(x)}.$ext';

	public static function fix(path:String):String {
		final s = isAbsolute(path) ? path : stripLibrary(path);
		return #if sys FileSystem.absolutePath #end (#if linux ext(path) == 'exe' ? withoutExt(s) : #end s);
	}
}
