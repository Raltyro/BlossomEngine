package openfl.utils;

import blossom.util.BitmapDataUtil;
import openfl.utils._internal.Log;
import openfl.display.BitmapData;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.media.Sound;
import openfl.text.Font;
#if lime
import lime.app.Promise;
import lime.utils.AssetLibrary as LimeAssetLibrary;
import lime.utils.Assets as LimeAssets;
#end
#if lime_vorbis
import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;
#end

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

	@see [Working with bitmap assets](https://books.openfl.org/openfl-developers-guide/working-with-bitmaps/working-with-bitmap-assets.html)
	@see [Working with byte array assets](https://books.openfl.org/openfl-developers-guide/working-with-byte-arrays/working-with-byte-array-assets.html)
	@see [Working with font assets](https://books.openfl.org/openfl-developers-guide/using-the-textfield-class/working-with-font-assets.html)
	@see [Working with sound assets](https://books.openfl.org/openfl-developers-guide/working-with-sound/working-with-sound-assets.html)
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display.BitmapData)
@:access(openfl.display.Sprite)
@:access(openfl.text.Font)
@:access(openfl.utils.AssetLibrary)
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

		```haxe
		var bitmap = new Bitmap (Assets.getBitmapData ("image.png"));
		```

		@param	id			The ID or asset path for the bitmap
		@param	useCache	(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key			(Optional) The key for asset cache (Default: id)
		@param	hardware	(Optional) Use hardware for bitmap (default: Assets.defaultHardware)
		@return		A new BitmapData object

		@see [Working with bitmap assets](https://books.openfl.org/openfl-developers-guide/working-with-bitmaps/working-with-bitmap-assets.html)
	**/
	public static function getBitmapData(id:String, useCache:Bool = true, ?key:String, ?hardware:Bool):BitmapData
	{
		#if (lime && tools && !display)
		if (key == null) key = id;
		if (useCache && cache.enabled && cache.hasBitmapData(key)) {
			var bitmapData = cache.getBitmapData(key);
			if (isValidBitmapData(bitmapData)) return bitmapData;
		}
		#end

		return registerBitmapData(getRawBitmapData(id, hardware), key, useCache);
	}

	/**
		Registers an instance of an embedded bitmap
		@param	bitmap		The bitmap for the asset path
		@param	key			The key for the asset cache
		@param	useCache	(Optional) Whether to allow use of the asset cache (Default: true)
		@return		A new BitmapData object
	**/
	public static function registerBitmapData(bitmap:BitmapData, key:String, useCache:Bool = true):BitmapData
	{
		if (bitmap == null || key == null) return bitmap;
		#if (lime && tools && !display)
		if (useCache && cache.enabled) cache.setBitmapData(key, bitmap);
		#end

		return bitmap;
	}

	/**
	 	Gets an instance of an raw embedded bitmap, skips the caching
		@param	id			The ID or asset path for the bitmap
		@param	hardware	(Optional) Use hardware for bitmap (default: Assets.defaultHardware)
		@return		A new BitmapData object
	**/
	public static function getRawBitmapData(id:String, ?hardware:Bool):BitmapData
	{
		#if lime
		var image = LimeAssets.getImage(id, false);
		if (image != null) {
			#if flash
			return cast image.src;
			#else
			var bitmapData = BitmapData.fromImage(image);
			if (hardware != null ? hardware : defaultHardware) BitmapDataUtil.toHardware(bitmapData);
			return bitmapData;
			#end
		}
		#end

		return null;
	}

	/**
		Gets an instance of an embedded binary asset

		```haxe
		var bytes = Assets.getBytes ("file.zip");
		```

		@param	id			The ID or asset path for the asset
		@param	useCache	(Optional) Whether to allow use of the asset cache (Default: false)
		@param	key			(Optional) The key for asset cache (Default: id)
		@return		A new ByteArray object

		@see [Working with byte array assets](https://books.openfl.org/openfl-developers-guide/working-with-byte-arrays/working-with-byte-array-assets.html)
	**/
	public static function getBytes(id:String, useCache:Bool = false, ?key:String):ByteArray
	{
		#if (lime && tools && !display)
		if (key == null) key = id;
		if (useCache && cache.enabled && cache.hasBytes(key)) return cache.getBytes(key);

		var bytes = LimeAssets.getBytes(id);
		if (bytes != null) {
			if (useCache && cache.enabled) cache.setBytes(key, bytes);

			return bytes;
		}
		#end

		return null;
	}

	/**
		Gets an instance of an embedded font

		```haxe
		var fontName = Assets.getFont ("font.ttf").fontName;
		```

		@param	id			The ID or asset path for the font
		@param	useCache	(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key			(Optional) The key for asset cache (Default: id)
		@return		A new Font object

		@see [Working with font assets](https://books.openfl.org/openfl-developers-guide/using-the-textfield-class/working-with-font-assets.html)
	**/
	public static function getFont(id:String, useCache:Bool = true, ?key:String):Font
	{
		#if (lime && tools && !display && !macro)
		if (key == null) key = id;
		if (useCache && cache.enabled && cache.hasFont(key)) return cache.getFont(key);

		var limeFont = LimeAssets.getFont(id, false);
		if (limeFont != null) {
			#if flash
			var font = limeFont.src;
			#else
			var font = new Font();
			font.__fromLimeFont(limeFont);
			#end

			if (useCache && cache.enabled) cache.setFont(key, font);

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

		```haxe
		var movieClip = Assets.getMovieClip ("library:BouncingBall");
		```

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

	/**
		Gets an instance of an embedded music

		```haxe
		var music = Assets.getMusic ("music.ogg");
		```

		@param	id				The ID or asset path for the music
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key				(Optional) The key for asset cache (Default: id)
		@param	staticFallback	(Optional) Use a static if it cannot get a streamed music (Default: true)
		@return		A new Sound object

		@see [Working with sound assets](https://books.openfl.org/openfl-developers-guide/working-with-sound/working-with-sound-assets.html)
	**/
	public static function getMusic(id:String, ?useCache:Bool, ?key:String, ?staticFallback:Bool):Sound
	{
		return getSound(id, useCache, key, staticFallback);
	}

	/**
		Gets the file path (if available) for an asset

		```haxe
		var path = Assets.getPath ("file.txt");
		```

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

		```haxe
		var sound = Assets.getSound ("sound.wav");
		```

		@param	id				The ID or asset path for the sound
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key				(Optional) The key for asset cache (Default: id)
		@param	streamed		(Optional) Whether should this sound be streamed (will not be cached if streamed) (Default: false)
		@param	staticFallback	(Optional) Use a static if it cannot get a streamed sound (Default: true)
		@return		A new Sound object

		@see [Working with sound assets](https://books.openfl.org/openfl-developers-guide/working-with-sound/working-with-sound-assets.html)
	**/
	public static function getSound(id:String, useCache:Bool = true, ?key:String, streamed:Bool = false, staticFallback:Bool = true):Sound
	{
		#if (lime && tools && !display)
		if (key == null) key = id;
		if (useCache && cache.enabled && cache.hasSound(id)) {
			var sound = cache.getSound(id);
			if (isValidSound(sound)) return sound;
		}

		#if (lime_vorbis && lime > "7.9.0" && !macro)
		if (streamed) {
			var vorbisFile = VorbisFile.fromFile(getPath(id));
			if (vorbisFile != null) return Sound.fromAudioBuffer(AudioBuffer.fromVorbisFile(vorbisFile));
			/*
			else {
				var bytes = getBytes(id, true, key);
				if (bytes != null && (vorbisFile = VorbisFile.fromBytes(bytes)) != null)
					return Sound.fromAudioBuffer(AudioBuffer.fromVorbisFile(vorbisFile));
			}
			*/

			if (!staticFallback) return null;
		}
		#end

		var buffer = LimeAssets.getAudioBuffer(id, false);
		if (buffer != null) {
			#if flash
			var sound = buffer.src;
			#else
			var sound = Sound.fromAudioBuffer(buffer);
			#end

			if (useCache && cache.enabled) cache.setSound(key, sound);

			return sound;
		}
		#end

		return null;
	}

	/**
		Gets an instance of an embedded text asset

		```haxe
		var text = Assets.getText ("text.txt");
		```

		@param	id			The ID or asset path for the asset
		@param	useCache	(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key			(Optional) The key for asset cache (Default: id)
		@return		A new String object
	**/
	public static function getText(id:String, useCache:Bool = true, ?key:String):String
	{
		#if (lime && tools && !display)
		if (key == null) key = id;
		if (useCache && cache.enabled && cache.hasText(key)) return cache.getText(key);

		var text = LimeAssets.getText(id);
		if (text != null) {
			if (useCache && cache.enabled) cache.setText(key, text);

			return text;
		}
		#end

		return null;
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

			if (type == AssetType.TEXT || type == null)
			{
				if (cache.hasText(id)) return true;
			}

			if (type == AssetType.BINARY || type == null)
			{
				if (cache.hasBytes(id)) return true;
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
		return (bitmapData != null && #if !lime_hybrid bitmapData.image != null #else bitmapData.__handle != null #end);
		#end
		#else
		return true;
		#end
	}

	@:noCompletion private static function isValidSound(sound:Sound):Bool
	{
		#if ((tools && !display) && (cpp || neko || nodejs))
		return sound != null;
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

		```haxe
		Assets.loadBitmapData ("image.png").onComplete (handleImage);
		```

		@param	id 			The ID or asset path for the asset
		@param	useCache	(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key			(Optional) The key for asset cache (Default: id)
		@param	hardware	(Optional) Use hardware for bitmap (default: Assets.defaultHardware)
		@return		Returns a Future<BitmapData>

		@see [Working with bitmap assets](https://books.openfl.org/openfl-developers-guide/working-with-bitmaps/working-with-bitmap-assets.html)
	**/
	public static function loadBitmapData(id:String, useCache:Bool = true, ?key:String, ?hardware:Bool):Future<BitmapData>
	{
		#if (lime && tools && !display)
		var promise = new Promise<BitmapData>();

		if (key == null) key = id;
		if (useCache && cache.enabled && cache.hasBitmapData(id)) {
			var bitmapData = cache.getBitmapData(id);
			if (isValidBitmapData(bitmapData)) {
				promise.complete(bitmapData);
				return promise.future;
			}
		}

		LimeAssets.loadImage(id, false).onComplete(function(image) {
			if (image != null) {
				#if flash
				var bitmapData = image.src;
				#else
				var bitmapData = BitmapData.fromImage(image);
				if (hardware != null ? hardware : defaultHardware) BitmapDataUtil.toHardware(bitmapData);
				#end

				promise.complete(registerBitmapData(bitmapData, key, useCache));
			}
			else {
				promise.error("[Assets] Could not load Image \"" + id + "\"");
			}
		}).onError(promise.error).onProgress(promise.progress);

		return promise.future;
		#else
		return Future.withValue(getBitmapData(id, useCache, key, hardware));
		#end
	}

	/**
		Loads an included byte asset asynchronously

		```haxe
		Assets.loadBytes ("file.zip").onComplete (handleBytes);
		```

		@param	id 			The ID or asset path for the asset
		@param	useCache	(Optional) Whether to allow use of the asset cache (Default: false)
		@param	key			(Optional) The key for asset cache (Default: id)
		@return		Returns a Future<ByteArray>

		@see [Working with byte array assets](https://books.openfl.org/openfl-developers-guide/working-with-byte-arrays/working-with-byte-array-assets.html)
	**/
	public static function loadBytes(id:String, useCache:Bool = false, ?key:String):Future<ByteArray>
	{
		#if (lime && tools && !display)
		var promise = new Promise<ByteArray>();

		if (key == null) key = id;
		if (useCache && cache.enabled && cache.hasBytes(key)) {
			promise.complete(cache.getBytes(key));
			return promise.future;
		}

		LimeAssets.loadBytes(id).onComplete(function(bytes) {
			if (useCache && cache.enabled) cache.setBytes(key, bytes);

			promise.complete(bytes);
		}).onError(promise.error).onProgress(promise.progress);

		return promise.future;
		#else
		return Future.withValue(getBytes(id, useCache, key));
		#end
	}

	/**
		Loads an included font asset asynchronously

		```haxe
		Assets.loadFont ("font.ttf").onComplete (handleFont);
		```

		@param	id			The ID or asset path for the font
		@param	useCache	(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key			(Optional) The key for asset cache (Default: id)
		@return		Returns a Future<Font>

		@see [Working with font assets](https://books.openfl.org/openfl-developers-guide/using-the-textfield-class/working-with-font-assets.html)
	**/
	public static function loadFont(id:String, useCache:Bool = true, ?key:String):Future<Font>
	{
		#if (lime && tools && !display && !macro)
		var promise = new Promise<Font>();

		if (key == null) key = id;
		if (useCache && cache.enabled && cache.hasFont(key)) {
			promise.complete(cache.getFont(key));
			return promise.future;
		}

		LimeAssets.loadFont(id, false).onComplete(function(limeFont) {
			#if flash
			var font = limeFont.src;
			#else
			var font = new Font();
			font.__fromLimeFont(limeFont);
			#end

			if (useCache && cache.enabled) cache.setFont(key, font);

			promise.complete(font);
		}).onError(promise.error).onProgress(promise.progress);

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
					// TODO: after Lime 8.2.0 is released, use conditional
					// compilation to call LimeAssets.removeLibrary(name, false)
					// since that is a new public API
					@:privateAccess LimeAssets.libraries.remove(name);
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

		```haxe
		Assets.loadMusic ("music.ogg").onComplete (handleMusic);
		```
		@param	id				The ID or asset path for the sound
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key				(Optional) The key for asset cache (Default: id)
		@param	staticFallback	(Optional) Use a static if it cannot get a streamed sound (Default: true)
		@return		Returns a Future<Sound>

		@see [Working with sound assets](https://books.openfl.org/openfl-developers-guide/working-with-sound/working-with-sound-assets.html)
	**/
	public static function loadMusic(id:String, ?useCache:Bool, ?key:String, ?staticFallback:Bool):Future<Sound>
	{
		return loadSound(id, useCache, key, true, staticFallback);
	}

	/**
		Loads an included MovieClip asset asynchronously

		```haxe
		Assets.loadMovieClip ("library:BouncingBall").onComplete (handleMovieClip);
		```

		@param	id 		The ID for the asset
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

		```haxe
		Assets.loadSound ("sound.wav").onComplete (handleSound);
		```

		@param	id				The ID or asset path for the sound
		@param	useCache		(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key				(Optional) The key for asset cache (Default: id)
		@param	streamed		(Optional) Whether should this sound be streamed (will not be cached if streamed) (Default: false)
		@param	staticFallback	(Optional) Use a static if it cannot get a streamed sound (Default: true)
		@return		Returns a Future<Sound>

		@see [Working with sound assets](https://books.openfl.org/openfl-developers-guide/working-with-sound/working-with-sound-assets.html)
	**/
	public static function loadSound(id:String, useCache:Bool = true, ?key:String, streamed:Bool = false, staticFallback:Bool = true):Future<Sound>
	{
		#if (lime && tools && !display)
		var promise = new Promise<Sound>();

		if (key == null) key = id;
		if (useCache && cache.enabled && cache.hasSound(key)) {
			var sound = cache.getSound(key);
			if (isValidSound(sound)) {
				promise.complete(sound);
				return promise.future;
			}
		}

		#if (lime_vorbis && lime > "7.9.0" && !macro)
		if (streamed) {
			var vorbisFile = VorbisFile.fromFile(getPath(id));
			if (vorbisFile != null) {
				promise.complete(Sound.fromAudioBuffer(AudioBuffer.fromVorbisFile(vorbisFile)));
				return promise.future;
			}

			if (!staticFallback) {
				promise.complete(null);
				return promise.future;
			}
		}
		#end

		LimeAssets.loadAudioBuffer(id, false).onComplete(function(buffer) {
			#if flash
			var sound = buffer.src;
			#else
			var sound = Sound.fromAudioBuffer(buffer);
			#end

			if (useCache && cache.enabled) cache.setSound(key, sound);

			promise.complete(sound);
		}).onError(promise.error).onProgress(promise.progress);

		return promise.future;
		#else
		return Future.withValue(getSound(id, useCache, key, useCache));
		#end
	}

	/**
		Loads an included text asset asynchronously

		```haxe
		Assets.loadText ("text.txt").onComplete (handleString);
		```

		@param	id 		The ID or asset path for the asset
		@param	useCache	(Optional) Whether to allow use of the asset cache (Default: true)
		@param	key			(Optional) The key for asset cache (Default: id)
		@return		Returns a Future<String>
	**/
	public static function loadText(id:String, useCache:Bool = true, ?key:String):Future<String>
	{
		#if (lime && tools && !display)
		var promise = new Promise<String>();

		if (key == null) key = id;
		if (useCache && cache.enabled && cache.hasText(key)) {
			promise.complete(cache.getText(key));
			return promise.future;
		}

		LimeAssets.loadText(id).onComplete(function(text) {
			if (useCache && cache.enabled) cache.setText(key, text);

			promise.complete(text);
		}).onError(promise.error).onProgress(promise.progress);

		return promise.future;
		#else
		return Future.withValue(getText(id, useCache, key));
		#end
	}

	/**
		Registers an AssetLibrary binding for use with @:bind or Assets.bind
		@param	className		The class name to use for the binding
		@param	method		The AssetLibrary responsible for the binding
	**/
	public static function registerBinding(className:String, library:AssetLibrary):Void
	{
		libraryBindings.set(className, library);
	}

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

	// Event Handlers
	@:noCompletion private static function LimeAssets_onChange():Void
	{
		dispatchEvent(new Event(Event.CHANGE));
	}
}
