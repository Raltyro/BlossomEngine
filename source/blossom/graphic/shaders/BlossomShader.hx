package blossom.graphic.shaders;

import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.display.Shader;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.util.FlxStringUtil;

class BlossomShader extends FlxGraphicsShader {
	private static var _fragmentCache:Map<String, String> = [];
	private static var _vertexCache:Map<String, String> = [];

	public static function getShaderCode(key:String, isFragment = true, ?library:String):String {
		if (library == null) library = Paths.getLibrary(key);
		final prefix = Paths.shader("", library);

		key = Paths.fix(key, isFragment ? "frag" : "vert");

		var path:String;
		if (StringTools.startsWith(key, prefix)) path = Paths.shader(key = key.substr(prefix.length), library);
		else key = Paths.stripLibrary(path = key);

		final cache = isFragment ? _fragmentCache : _vertexCache;
		if (cache.exists(key)) return cache.get(key);

		trace(path);
		return processShaderCode(AssetUtil.getText(path), isFragment, key);
	}

	public static function processShaderCode(source:String, isFragment:Bool, ?key:String):String {
		final cache = isFragment ? _fragmentCache : _vertexCache;
		if (key == null) key = source;
		else if (cache.exists(key)) return cache.get(key);

		final includeKeyword = ~/#include ['"](.+)['"]/g;
		source = includeKeyword.map(source, (_) -> return getShaderCode(includeKeyword.matched(1), isFragment));

		cache.set(key, source);
		return source;
	}

	@:noCompletion private var __glFragmentSourceDefault:String;
	@:noCompletion private var __glVertexSourceDefault:String;
	@:noCompletion private var __glVersionDefault:String;
	@:noCompletion private var __glFragmentExtensionsDefault:Array<ShaderExtension>;
	@:noCompletion private var __glVertexExtensionsDefault:Array<ShaderExtension>;
	@:noCompletion private var __immediate:Bool;

	public function new(?fragmentSource:String, ?vertexSource:String, ?version:String,
		?fragmentExtensions:Array<ShaderExtension>, ?vertexExtensions:Array<ShaderExtension>, immediate = false
	) {
		__glFragmentSourceDefault = __glFragmentSourceRaw;
		__glVertexSourceDefault = __glVertexSourceRaw;
		__glVersionDefault = __glVersionRaw;
		__glFragmentExtensionsDefault = __glFragmentExtensions;
		__glVertexExtensionsDefault = __glVertexExtensions;
		__immediate = immediate;

		if (version != null) glVersion = version;
		if (fragmentExtensions != null) glFragmentExtensions = fragmentExtensions;
		if (vertexExtensions != null) glVertexExtensions = vertexExtensions;
		if (fragmentSource != null) glFragmentSource = fragmentSource;
		if (vertexSource != null) glVertexSource = vertexSource;

		super();

		if (!__isGenerated) {
			__isGenerated = true;
			__initGL();
		}
	}

	override function __initGL() {
		super.__initGL();

		if (__immediate) {
			__context = FlxG.stage.context3D;
			__enable();
		}
	}

	public function toString():String
		return FlxStringUtil.getDebugString([for (field in Reflect.fields(data)) LabelValuePair.weak(field, Reflect.field(data, field))]);
}