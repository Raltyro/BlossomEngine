package blossom.graphic.shaders;

import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.display.Shader;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.util.FlxStringUtil;

@:access(openfl.display.Shader)
class BlossomShader extends FlxGraphicsShader {
	@:glVertexHeader("varying vec4 worldPosition;
varying vec4 viewPosition;

vec4 project(vec4 vertex, mat4 projectionMatrix, mat4 viewMatrix, mat4 modelMatrix) {
	mat4 internalMatrix = openfl_Matrix;
	vec4 internalOffset = vec4(internalMatrix[3].xy / vec2(internalMatrix[0][0], internalMatrix[1][1]), 0.0, 0.0);
	internalMatrix[3].xy = vec2(0.0);

	return projectionMatrix * internalMatrix * (viewPosition = viewMatrix * (worldPosition = (modelMatrix * vertex) + internalOffset));
}")

	@:glFragmenHeader("varying vec4 worldPosition;
varying vec4 viewPosition;")

	private static var _fragmentCache:Map<String, String> = [];
	private static var _vertexCache:Map<String, String> = [];

	public static function getShaderCode(key:String, ?library:String, isFragment = true):Null<String> {
		if (library == null) library = Paths.getLibrary(key);
		final prefix = Paths.shader("", library);

		var path:String;
		if (StringTools.startsWith(key, prefix)) path = Paths.shader(key = key.substr(prefix.length), library);
		else key = Paths.stripLibrary(path = key);

		key = Paths.withoutExtension(key);

		var ext = Paths.extension(path);
		if (ext == "") path = Paths.fix(path, isFragment ? "frag" : "vert");
		else isFragment = ext != "vert";

		final cache = isFragment ? _fragmentCache : _vertexCache;
		if (cache.exists(key)) return cache.get(key);
		else if (!AssetUtil.textExists(path)) return null;

		final text = AssetUtil.getText(path);
		cache.set(key, text);

		return text;
	}

	private static function processGLSLText(source:String, glVersion:String, isFragment:Bool, ?pragmas:Map<String, String>):String
		return Shader.processGLSLText(_processGLSLText(source, glVersion, isFragment, pragmas), glVersion, isFragment);

	private static function _processGLSLText(source:String, glVersion:String, isFragment:Bool, ?pragmas:Map<String, String>):String {
		if (pragmas != null) {
			final pragmaKeyword = ~/#pragma (\w+)/g;
			source = pragmaKeyword.map(source, (_) -> {
				var name = pragmaKeyword.matched(1);
				var pragma = pragmas.get(name) ?? "";
				if (name == "header" && isFragment && !StringTools.contains(pragma, "(location = 0)")) switch (glVersion) { // im blaming swordcube
					case "300 es", "330", "400", "410", "420", "430", "440", "450", "460":
						#if desktop
						pragma = "layout (location = 0) out vec4 ofl_FragColor;\n" + pragma;
						#else
						pragma = "out vec4 ofl_FragColor;\n" + pragma;
						#end
				}

				return processGLSLText(pragma, glVersion, isFragment, pragmas);
			});
		}

		final includeKeyword = ~/#include ['"](.+)['"]/g;
		return includeKeyword.map(source, (_) ->
			return processGLSLText(getShaderCode(includeKeyword.matched(1), isFragment), glVersion, isFragment, pragmas) ?? "");
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
		__glVersionDefault = __glVersionRaw ?? Shader.getDefaultGLVersion();
		__glFragmentExtensionsDefault = __glFragmentExtensions ?? [];
		__glVertexExtensionsDefault = __glVertexExtensions ?? [];
		__immediate = immediate;

		if (vertexExtensions != null) glVertexExtensions = vertexExtensions;
		if (fragmentExtensions != null) glFragmentExtensions = fragmentExtensions;
		if (vertexSource != null) __glVertexSourceRaw = vertexSource;
		if (fragmentSource != null) __glFragmentSourceRaw = fragmentSource;
		if (version != null) glVersion = version;

		super();

		if (!__isGenerated) {
			__isGenerated = true;
			__initGL();
		}
	}

	public function loadShader(name:String, ?glVersion:String, ?library:String):BlossomShader {
		final fragment = getShaderCode(name, library, true), vertex = getShaderCode(name, library, false);

		if (vertex == null) __glVertexSourceRaw = __glVertexSourceDefault;
		else __glVertexSourceRaw = vertex;

		if (fragment == null) __glFragmentSourceRaw = __glFragmentSourceDefault;
		else __glFragmentSourceRaw = fragment;

		this.glVersion = glVersion;

		return this;
	}

	override function __initGL() {
		super.__initGL();

		if (__immediate) {
			__context = FlxG.stage.context3D;
			__enable();
		}
	}

	override function set_glFragmentExtensions(value:Array<ShaderExtension>):Array<ShaderExtension> {
		if (value == null) value = __glFragmentExtensionsDefault;
		if (value != __glFragmentExtensions) __glSourceDirty = true;
		return __glFragmentExtensions = value;
	}

	override function set_glVertexExtensions(value:Array<ShaderExtension>):Array<ShaderExtension> {
		if (value == null) value = __glVertexExtensionsDefault;
		if (value != __glVertexExtensions) __glSourceDirty = true;
		return __glVertexExtensions = value;
	}

	override function set_glVersion(value:Null<String>):String {
		__glVersionRaw = value;
		if (value == null || value == "") value = __glVersionDefault;
		if (value != __glVersion) {
			__glSourceDirty = true;
			if (__glVertexSourceRaw != null) __glVertexSource = processGLSLText(__glVertexSourceRaw, value, false, __glVertexPragmas);
			if (__glFragmentSourceRaw != null) __glFragmentSource = processGLSLText(__glFragmentSourceRaw, value, true, __glFragmentPragmas);
		}

		return __glVersion = value;
	}

	override function set_glFragmentSource(value:String):String {
		if (value == null || value == "") value = __glFragmentSourceDefault;
		if ((__glFragmentSourceRaw = value) != null) value = processGLSLText(value, __glVersion, true, __glFragmentPragmas);

		if (value != __glFragmentSource) __glSourceDirty = true;
		return __glFragmentSource = value;
	}

	override function set_glVertexSource(value:String):String {
		if (value == null || value == "") value = __glVertexSourceDefault;
		if ((__glVertexSourceRaw = value) != null) value = processGLSLText(value, __glVersion, false, __glVertexPragmas);

		if (value != __glVertexSource) __glSourceDirty = true;
		return __glVertexSource = value;
	}

	public function toString():String
		return FlxStringUtil.getDebugString([for (field in Reflect.fields(data)) LabelValuePair.weak(field, Reflect.field(data, field))]);
}