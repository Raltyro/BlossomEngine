package openfl.utils;

#if lime
import haxe.io.Bytes;

#if (lime_vorbis && lime > "7.9.0")
import lime.media.vorbis.VorbisFile;
#end

import lime.app.Promise;
import lime.graphics.PixelFormat;
import lime.graphics.ImageBuffer;
import lime.media.AudioBuffer;
import lime.utils.AssetLibrary as LimeAssetLibrary;
import lime.utils.Assets as LimeAssets;
import lime.utils.UInt8Array as LUInt8Array;

import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFI;
#end

import openfl.utils._internal.Log;
import openfl.display.BitmapData;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.media.Sound;
import openfl.text.Font;

import openfl.system.System;
import openfl.Lib;

/**
	The Assets class provides a cross-platform interface to access
	embedded images, fonts, sounds and other resource files.

	The contents are populated automatically when an application
	is compiled using the OpenFL command-line tools, based on the
	contents of the *.xml project file.

	For most platforms, the assets are included in the same directory
	or package as the application, and the paths are handled
	automatically. For web content, the assets are preloaded before
	the start of the rest of the application. You can customize the
	preloader by extending the `NMEPreloader` class,
	and specifying a custom preloader using <window preloader="" />
	in the project file.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

#if lime
@:access(lime._internal.backend.native.NativeCFFI)
#end

@:access(openfl.display.BitmapData)
@:access(openfl.display.Sprite)
@:access(openfl.text.Font)
@:access(openfl.utils.AssetLibrary)
@:accesS(openfl.display3D.textures.TextureBase.__uploadFromImage)
class Assets
{
	public static var cache:IAssetCache = new AssetCache();
	public static var defaultHardware:Bool = true;

	@:noCompletion private static var dispatcher:EventDispatcher #if !macro = new EventDispatcher() #end;
	private static var libraryBindings:Map<String, AssetLibrary> = new Map();

	public static function addEventListener(type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
	{
		#if lime
		if (!LimeAssets.onChange.has(LimeAssets_onChange))
		{
			LimeAssets.onChange.add(LimeAssets_onChange);
		}
		#end

		dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
	}

	public static function dispatchEvent(event:Event):Bool
	{
		return dispatcher.dispatchEvent(event);
	}

	/**
		Returns whether a specific asset exists
		@param	id 		The ID or asset path for the asset
		@param	type	The asset type to match, or null to match any type
		@return		Whether the requested asset ID and type exists
	**/
	public static function exists(id:String, type:AssetType = null):Bool
	{
		#if lime
		return LimeAssets.exists(id, cast type);
		#else
		return false;
		#end
	}

	/**
		Gets an instance of an embedded bitmap
		@usage		var bitmap = new Bitmap (Assets.getBitmapData ("image.png"));
		@param	id		The ID or asset path for the bitmap
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key		(Optional) The Key for the bitmap
		@param	hardware		Hardware Caching (Default: false)
		@return		A new BitmapData object
	**/
	public static function getBitmapData(id:String, useCache:Bool = true, ?key:String, ?hardware:Bool):BitmapData
	{
		#if (lime && tools && !display)
		if (key == null) key = id;

		if (useCache && cache.enabled && cache.hasBitmapData(key)) {
			var bitmapData = cache.getBitmapData(key);
			if (isValidBitmapData(bitmapData)) return bitmapData;
		}

		return registerBitmapData(getRawBitmapData(id), key, useCache, hardware);
		#end

		return null;
	}

	/**
		Registers an instance of an embedded bitmap
		@usage		Assets.registerBitmapData(bitmapData);
		@param	bitmap		The bitmap for the asset path
		@param	key		The key for the bitmap
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@param	hardware		Hardware Caching (Default: false)
		@return		A BitmapData object
	**/
	public static function registerBitmapData(bitmap:BitmapData, key:String, useCache:Bool = true, ?hardware:Bool):BitmapData {
		if (bitmap == null || key == null) return bitmap;
		if (hardware == null) hardware = defaultHardware;

		#if (lime && tools && !display)

		#if !flash
		if (hardware) bl.util.BitmapDataUtil.toHardware(bitmap);
		#end

		if (useCache && cache.enabled)
			cache.setBitmapData(key, bitmap);
		#end

		return bitmap;
	}

	/**
	 	Gets an instance of an raw embedded bitmap, skips the cache
		@usage		var bitmap = new Bitmap (Assets.getRawBitmapData ("image.png"));
		@param	id		The ID or asset path for the bitmap
		@return		A BitmapData object
	**/
	public static function getRawBitmapData(id:String):BitmapData {
		#if (lime && tools && !display)
		var image = LimeAssets.getImage(id, false);
		if (image != null)
			#if flash
			return cast image.src;
			#else
			return BitmapData.fromImage(image);
			#end
		#end
		return null;
	}

	/**
		Gets an instance of an embedded binary asset
		@usage		var bytes = Assets.getBytes ("file.zip");
		@param	id		The ID or asset path for the asset
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: false)
		@return		A new ByteArray object
	**/
	public static function getBytes(id:String, useCache:Bool = false):ByteArray
	{
		#if lime
		return LimeAssets.getBytes(id);
		#else
		return null;
		#end
	}

	/**
		Gets an instance of an embedded font
		@usage		var fontName = Assets.getFont ("font.ttf").fontName;
		@param	id		The ID or asset path for the font
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@return		A new Font object
	**/
	public static function getFont(id:String, useCache:Bool = true, ?key:String):Font
	{
		#if (lime && tools && !display && !macro)
		key = key != null ? key : id;
		
		if (useCache && cache.enabled && cache.hasFont(key))
		{
			return cache.getFont(key);
		}

		var limeFont = LimeAssets.getFont(id, false);

		if (limeFont != null)
		{
			#if flash
			var font = limeFont.src;
			#else
			var font = new Font();
			font.__fromLimeFont(limeFont);
			#end

			if (useCache && cache.enabled)
			{
				cache.setFont(key, font);
			}

			return font;
		}
		#end

		return new Font();
	}

	public static function getLibrary(name:String):#if lime LimeAssetLibrary #else AssetLibrary #end
	{
		#if lime
		return LimeAssets.getLibrary(name);
		#else
		return null;
		#end
	}

	/**
		Gets an instance of an included MovieClip
		@usage		var movieClip = Assets.getMovieClip ("library:BouncingBall");
		@param	id		The ID for the MovieClip
		@return		A new MovieClip object
	**/
	public static function getMovieClip(id:String):MovieClip
	{
		#if (lime && tools && !display)
		var libraryName = id.substring(0, id.indexOf(":"));
		var symbolName = id.substr(id.indexOf(":") + 1);
		var limeLibrary = getLibrary(libraryName);

		if (limeLibrary != null)
		{
			if ((limeLibrary is AssetLibrary))
			{
				var library:AssetLibrary = cast limeLibrary;

				if (library.exists(symbolName, cast AssetType.MOVIE_CLIP))
				{
					if (library.isLocal(symbolName, cast AssetType.MOVIE_CLIP))
					{
						return library.getMovieClip(symbolName);
					}
					else
					{
						Log.error("MovieClip asset \"" + id + "\" exists, but only asynchronously");
						return null;
					}
				}
			}

			Log.error("There is no MovieClip asset with an ID of \"" + id + "\"");
		}
		else
		{
			Log.error("There is no asset library named \"" + libraryName + "\"");
		}
		#end

		return null;
	}

	public static function getMusic(id:String, useCache:Bool = true, ?key:String):Sound
	{
		return getSound(id, useCache, key, true);
	}

	/**
		Gets the file path (if available) for an asset
		@usage		var path = Assets.getPath ("file.txt");
		@param	id		The ID or asset path for the asset
		@return		The path to the asset, or null if it does not exist
	**/
	public static function getPath(id:String):String
	{
		#if lime
		return LimeAssets.getPath(id);
		#else
		return null;
		#end
	}

	/**
		Gets an instance of an embedded sound
		@usage		var sound = Assets.getSound ("sound.wav");
		@param	id		The ID or asset path for the sound
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key		(Optional) The Key for the sound
		@param	stream		Streaming Sounds (Default: false)
		
		@return		A new Sound object
	**/
	public static function getSound(id:String, useCache:Bool = true, ?key:String, stream:Bool = false, fromFile:Bool = false):Sound
	{
		#if (lime && tools && !display)
		key = key != null ? key : id;
		
		if (useCache && cache.enabled && cache.hasSound(key)) {
			var sound = cache.getSound(key);

			if (isValidSound(sound)) return sound;
		}

		var sound = getRawSound(id, stream, fromFile);

		if (sound != null) {
			if (useCache && cache.enabled) cache.setSound(key, sound);
			return sound;
		}
		#end

		return null;
	}

	public static function getRawAudioBuffer(id:String, stream:Bool = false, fromFile:Bool = false):AudioBuffer
	{
		var colonIdx = id.indexOf(':'), path = id.substr(colonIdx + 1), buffer:AudioBuffer = null;
		if (fromFile || stream) {
			var library = getLibrary(id.substr(0, colonIdx));
			if (library != null && library.exists(path, null)) path = library.getPath(path);
		}
		#if (lime_vorbis && lime > "7.9.0")
		if (stream) buffer = AudioBuffer.fromVorbisFile(VorbisFile.fromFile(path));
		else
		#end
		#if (js && html5 && lime_howlerjs)
		if (fromFile) buffer = AudioBuffer.fromFile(path, stream);
		if (buffer == null) buffer = LimeAssets.getAudioBuffer(id, false);
		#elseif sys
		if (fromFile) buffer = AudioBuffer.fromFile(path);
		if (buffer == null) buffer = LimeAssets.getAudioBuffer(id, false);
		#else
		buffer = LimeAssets.getAudioBuffer(id, false);
		#end
		
		return buffer;
	}
	
	public static function getRawSound(id:String, stream:Bool = false, fromFile:Bool = false):Sound
	{
		var buffer = getRawAudioBuffer(id, stream, fromFile);
		if (buffer != null)
			#if flash
			return buffer.src;
			#else
			return Sound.fromAudioBuffer(buffer);
			#end
		
		return null;
	}

	/**
		Gets an instance of an embedded text asset
		@usage		var text = Assets.getText ("text.txt");
		@param	id		The ID or asset path for the asset
		@return		A new String object
	**/
	public static function getText(id:String):String
	{
		#if lime
		return LimeAssets.getText(id);
		#else
		return null;
		#end
	}

	public static function hasEventListener(type:String):Bool
	{
		return dispatcher.hasEventListener(type);
	}

	public static function hasLibrary(name:String):Bool
	{
		#if lime
		return LimeAssets.hasLibrary(name);
		#else
		return false;
		#end
	}

	#if (openfl >= "9.2.0")
	/**
		Connects a user-defined class to a related asset class.

		This method call is added to the beginning of user-defined class constructors when
		the `@:bind` meta-data is used. This allows insertion of related asset resources in
		compatible super classes, such as `openfl.display.MovieClip`.
		@param	className 		The registered class name of the asset constructor
		@param  instance		The current class instance to be bound (default is null)
		@return		Whether asset binding was successful
	**/
	public static function initBinding(className:String, instance:Dynamic = null):Void
	{
		if (libraryBindings.exists(className))
		{
			var library = libraryBindings.get(className);
			#if !flash
			if (instance == null)
			{
				Sprite.__constructor = function(instance:Sprite)
				{
					instance.__bind(library, className);
				}
			}
			else
			{
				Sprite.__constructor = null;
				instance.__bind(library, className);
			}
			#else
			// TODO: Consolidate behavior
			library.bind(className);
			#end
		}
		else
		{
			Log.warn("No asset is registered as \"" + className + "\"");
		}
	}
	#end

	/**
		Returns whether an asset is "local", and therefore can be loaded synchronously
		@param	id 		The ID or asset path for the asset
		@param	type	The asset type to match, or null to match any type
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@return	Whether the asset is local
	**/
	public static function isLocal(id:String, type:AssetType = null, useCache:Bool = true):Bool
	{
		#if (lime && tools && !display)
		if (useCache && cache.enabled)
		{
			if (type == AssetType.IMAGE || type == null)
			{
				if (cache.hasBitmapData(id)) return true;
			}

			if (type == AssetType.FONT || type == null)
			{
				if (cache.hasFont(id)) return true;
			}

			if (type == AssetType.SOUND || type == AssetType.MUSIC || type == null)
			{
				if (cache.hasSound(id)) return true;
			}
		}

		var libraryName = id.substring(0, id.indexOf(":"));
		var symbolName = id.substr(id.indexOf(":") + 1);
		var library = getLibrary(libraryName);

		if (library != null)
		{
			return library.isLocal(symbolName, cast type);
		}
		#end

		return false;
	}

	@:analyzer(ignore) private static function isValidBitmapData(bitmapData:BitmapData):Bool
	{
		#if (lime && tools && !display)
		#if flash
		try
		{
			bitmapData.width;
			return true;
		}
		catch (e:Dynamic)
		{
			return false;
		}
		#else
		@:privateAccess return (bitmapData != null && (#if !lime_hybrid bitmapData.image != null #else bitmapData.__handle != null #end || bitmapData.__texture != null));
		#end
		#else
		return true;
		#end
	}

	@:noCompletion private static function isValidSound(sound:Sound):Bool
	{
		#if ((tools && !display) && (cpp || neko || nodejs))
		return true;
		// return (sound.__handle != null && sound.__handle != 0);
		#else
		return true;
		#end
	}

	/**
		Returns a list of all embedded assets (by type)
		@param	type	The asset type to match, or null to match any type
		@return	An array of asset ID values
	**/
	public static function list(type:AssetType = null):Array<String>
	{
		#if lime
		return LimeAssets.list(cast type);
		#else
		return [];
		#end
	}

	/**
		Loads an included bitmap asset asynchronously
		@usage	Assets.loadBitmapData ("image.png").onComplete (handleImage);
		@param	id 		The ID or asset path for the asset
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key		(Optional) The Key for the bitmap
		@param	hardware		Hardware Caching (Default: false)
		@return		Returns a Future<BitmapData>
	**/
	public static function loadBitmapData(id:String, useCache:Null<Bool> = true, ?key:String, hardware:Bool = false):Future<BitmapData>
	{
		if (useCache == null) useCache = true;
		
		#if (lime && tools && !display)
		key = key != null ? key : id;
		
		var promise = new Promise<BitmapData>();

		if (useCache && cache.enabled && cache.hasBitmapData(key))
		{
			var bitmapData = cache.getBitmapData(key);

			if (isValidBitmapData(bitmapData))
			{
				promise.complete(bitmapData);
				return promise.future;
			}
		}

		LimeAssets.loadImage(id, false).onComplete(function(image)
		{
			if (image != null)
			{
				#if flash
				var bitmapData = image.src;
				#else
				var bitmapData:BitmapData = BitmapData.fromImage(image);
				#end

				promise.complete(registerBitmapData(bitmapData, key, useCache, hardware));
			}
			else
			{
				promise.error("[Assets] Could not load Image \"" + id + "\"");
			}
		}).onError(promise.error).onProgress(promise.progress);

		return promise.future;
		#else
		return Future.withValue(getBitmapData(id, useCache, key));
		#end
	}

	/**
		Loads an included byte asset asynchronously
		@usage	Assets.loadBytes ("file.zip").onComplete (handleBytes);
		@param	id 		The ID or asset path for the asset
		@return		Returns a Future<ByteArray>
	**/
	public static function loadBytes(id:String):Future<ByteArray>
	{
		#if lime
		var promise = new Promise<ByteArray>();
		var future = LimeAssets.loadBytes(id);

		future.onComplete(function(bytes) promise.complete(bytes));
		future.onProgress(function(progress, total) promise.progress(progress, total));
		future.onError(function(msg) promise.error(msg));

		return promise.future;
		#else
		return Future.withValue(getBytes(id));
		#end
	}

	/**
		Loads an included font asset asynchronously
		@usage	Assets.loadFont ("font.ttf").onComplete (handleFont);
		@param	id 		The ID or asset path for the asset
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@return		Returns a Future<Font>
	**/
	public static function loadFont(id:String, useCache:Null<Bool> = true, ?key:String):Future<Font>
	{
		if (useCache == null) useCache = true;

		#if (lime && tools && !display && !macro)
		key = key != null ? key : id;
		
		var promise = new Promise<Font>();

		if (useCache && cache.enabled && cache.hasFont(key))
		{
			promise.complete(cache.getFont(key));
			return promise.future;
		}

		LimeAssets.loadFont(id)
			.onComplete(function(limeFont)
			{
				#if flash
				var font = limeFont.src;
				#else
				var font = new Font();
				font.__fromLimeFont(limeFont);
				#end

				if (useCache && cache.enabled)
				{
					cache.setFont(key, font);
				}

				promise.complete(font);
			})
			.onError(promise.error)
			.onProgress(promise.progress);

		return promise.future;
		#else
		return Future.withValue(getFont(id, useCache, key));
		#end
	}

	/**
		Load an included AssetLibrary
		@param	name		The name of the AssetLibrary to load
		@return		Returns a Future<AssetLibrary>
	**/
	public static function loadLibrary(name:String):#if java Future<LimeAssetLibrary> #else Future<AssetLibrary> #end
	{
		#if lime
		return LimeAssets.loadLibrary(name).then(function(library)
		{
			var _library:AssetLibrary = null;

			if (library != null)
			{
				if ((library is AssetLibrary))
				{
					_library = cast library;
				}
				else
				{
					_library = new AssetLibrary();
					_library.__proxy = library;
					LimeAssets.registerLibrary(name, _library);
				}
			}

			return Future.withValue(_library);
		});
		#else
		return cast Future.withError("Cannot load library");
		#end
	}

	/**
		Loads an included music asset asynchronously
		@usage	Assets.loadMusic ("music.ogg").onComplete (handleMusic);
		@param	id 		The ID or asset path for the asset
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@return		Returns a Future<Sound>
	**/
	public static function loadMusic(id:String, useCache:Null<Bool> = true):Future<Sound>
	{
		if (useCache == null) useCache = true;

		#if lime
		#if !html5
		var promise = new Promise<Sound>();

		LimeAssets.loadAudioBuffer(id, useCache)
			.onComplete(function(buffer)
			{
				if (buffer != null)
				{
					#if flash
					var sound = buffer.src;
					#else
					var sound = Sound.fromAudioBuffer(buffer);
					#end

					if (useCache && cache.enabled)
					{
						cache.setSound(id, sound);
					}

					promise.complete(sound);
				}
				else
				{
					promise.error("[Assets] Could not load Sound \"" + id + "\"");
				}
			})
			.onError(promise.error)
			.onProgress(promise.progress);
		return promise.future;
		#else
		var future = new Future<Sound>(function() return getMusic(id, useCache));
		return future;
		#end
		#else
		return Future.withValue(getMusic(id, useCache));
		#end
	}

	/**
		Loads an included MovieClip asset asynchronously
		@usage	Assets.loadMovieClip ("library:BouncingBall").onComplete (handleMovieClip);
		@param	id 		The ID for the asset
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@return		Returns a Future<MovieClip>
	**/
	public static function loadMovieClip(id:String):Future<MovieClip>
	{
		#if (lime && tools && !display)
		var promise = new Promise<MovieClip>();

		var libraryName = id.substring(0, id.indexOf(":"));
		var symbolName = id.substr(id.indexOf(":") + 1);
		var limeLibrary = getLibrary(libraryName);

		if (limeLibrary != null)
		{
			if ((limeLibrary is AssetLibrary))
			{
				var library:AssetLibrary = cast limeLibrary;

				if (library.exists(symbolName, cast AssetType.MOVIE_CLIP))
				{
					promise.completeWith(library.loadMovieClip(symbolName));
					return promise.future;
				}
			}

			promise.error("[Assets] There is no MovieClip asset with an ID of \"" + id + "\"");
		}
		else
		{
			promise.error("[Assets] There is no asset library named \"" + libraryName + "\"");
		}

		return promise.future;
		#else
		return Future.withValue(getMovieClip(id));
		#end
	}

	/**
		Loads an included sound asset asynchronously
		@usage	Assets.loadSound ("sound.wav").onComplete (handleSound);
		@param	id 		The ID or asset path for the asset
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@return		Returns a Future<Sound>
	**/
	public static function loadSound(id:String, useCache:Null<Bool> = true, ?key:String):Future<Sound>
	{
		if (useCache == null) useCache = true;

		#if lime
		key = key != null ? key : id;
		
		var promise = new Promise<Sound>();
		
		if (useCache && cache.enabled && cache.hasSound(key))
		{
			var sound = cache.getSound(key);

			if (isValidSound(sound))
			{
				promise.complete(sound);
				return promise.future;
			}
		}

		LimeAssets.loadAudioBuffer(id, useCache)
			.onComplete(function(buffer)
			{
				if (buffer != null)
				{
					#if flash
					var sound = buffer.src;
					#else
					var sound = Sound.fromAudioBuffer(buffer);
					#end

					if (useCache && cache.enabled)
					{
						cache.setSound(key, sound);
					}

					promise.complete(sound);
				}
				else
				{
					promise.error("[Assets] Could not load Sound \"" + id + "\"");
				}
			})
			.onError(promise.error)
			.onProgress(promise.progress);
		return promise.future;
		#else
		return Future.withValue(getSound(id, useCache, key));
		#end
	}

	/**
		Loads an included text asset asynchronously
		@usage	Assets.loadText ("text.txt").onComplete (handleString);
		@param	id 		The ID or asset path for the asset
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@return		Returns a Future<String>
	**/
	public static function loadText(id:String):Future<String>
	{
		#if lime
		var future = LimeAssets.loadText(id);
		return future;
		#else
		return Future.withValue(getText(id));
		#end
	}

	#if (openfl >= "9.2.0")
	/**
		Registers an AssetLibrary binding for use with @:bind or Assets.bind
		@param	className		The class name to use for the binding
		@param	method		The AssetLibrary responsible for the binding
	**/
	public static function registerBinding(className:String, library:AssetLibrary):Void
	{
		libraryBindings.set(className, library);
	}
	#end

	/**
		Registers a new AssetLibrary with the Assets class
		@param	name		The name (prefix) to use for the library
		@param	library		An AssetLibrary instance to register
	**/
	public static function registerLibrary(name:String, library:AssetLibrary):Void
	{
		#if lime
		LimeAssets.registerLibrary(name, library);
		#end
	}

	public static function removeEventListener(type:String, listener:Dynamic, capture:Bool = false):Void
	{
		dispatcher.removeEventListener(type, listener, capture);
	}

	@:noCompletion private static function resolveClass(name:String):Class<Dynamic>
	{
		return Type.resolveClass(name);
	}

	@:noCompletion private static function resolveEnum(name:String):Enum<Dynamic>
	{
		var value = Type.resolveEnum(name);

		#if flash
		if (value == null)
		{
			return cast Type.resolveClass(name);
		}
		#end

		return value;
	}

	public static function unloadLibrary(name:String):Void
	{
		#if lime
		LimeAssets.unloadLibrary(name);
		#end
	}

	#if (openfl >= "9.2.0")
	/**
		Unregisters an AssetLibrary binding for use with @:bind or Assets.bind
		@param	className		The class name to use for the binding
		@param	method		The AssetLibrary responsible for the binding
	**/
	public static function unregisterBinding(className:String, library:AssetLibrary):Void
	{
		if (libraryBindings.exists(className) && libraryBindings.get(className) == library)
		{
			libraryBindings.remove(className);
		}
	}
	#end

	// Event Handlers
	@:noCompletion private static function LimeAssets_onChange():Void
	{
		dispatchEvent(new Event(Event.CHANGE));
	}
}