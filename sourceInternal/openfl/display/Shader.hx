package openfl.display;

#if !flash
import openfl.display._internal.ShaderBuffer;
import openfl.display.OpenGLRenderer;
import openfl.display3D.Context3D;
import openfl.display3D.Program3D;
import openfl.display3D._internal.GLProgram;
import openfl.display3D._internal.GLShader;
import openfl.utils.ByteArray;
import openfl.utils._internal.Float32Array;
import openfl.utils._internal.Log;

/**
	// TODO: Document GLSL Shaders
	A Shader instance represents a Pixel Bender shader kernel in ActionScript.
	To use a shader in your application, you create a Shader instance for it.
	You then use that Shader instance in the appropriate way according to the
	effect you want to create. For example, to use the shader as a filter, you
	assign the Shader instance to the `shader` property of a ShaderFilter
	object.
	A shader defines a function that executes on all the pixels in an image,
	one pixel at a time. The result of each call to the function is the output
	color at that pixel coordinate in the image. A shader can specify one or
	more input images, which are images whose content can be used in
	determining the output of the function. A shader can also specify one or
	more parameters, which are input values that can be used in calculating
	the function output. In a single shader execution, the input and parameter
	values are constant. The only thing that varies is the coordinate of the
	pixel whose color is the function result. Shader function calls for
	multiple output pixel coordinates execute in parallel to improve shader
	execution performance.

	The shader bytecode can be loaded at run time using a URLLoader instance.
	The following example demonstrates loading a shader bytecode file at run
	time and linking it to a Shader instance.

	```as3
	var loader:URLLoader = new URLLoader();
	loader.dataFormat = URLLoaderDataFormat.BINARY;
	loader.addEventListener(Event.COMPLETE, onLoadComplete);
	loader.load(new URLRequest("myShader.pbj"));
	var shader:Shader;

	function onLoadComplete(event:Event):void {
		// Create a new shader and set the loaded data as its bytecode
		shader = new Shader();
		shader.byteCode = loader.data;

		// You can also pass the bytecode to the Shader() constructor like this:
		// shader = new Shader(loader.data);

		// do something with the shader
	}
	```

	You can also embed the shader into the SWF at compile time using the
	`[Embed]` metadata tag. The `[Embed]` metadata tag is only available if
	you use the Flex SDK to compile the SWF. The `[Embed]` tag's `source`
	parameter points to the shader file, and its `mimeType` parameter is
	`"application/octet-stream"`, as in this example:

	```as3
	[Embed(source="myShader.pbj", mimeType="application/octet-stream)] var MyShaderClass:Class;

	// ...

	// create a new shader and set the embedded shader as its bytecode var
	shaderShader = new Shader();
	shader.byteCode = new MyShaderClass();

	// You can also pass the bytecode to the Shader() constructor like this:
	// var shader:Shader = new Shader(new MyShaderClass());

	// do something with the shader
	```

	In either case, you link the raw shader (the `URLLoader.data` property or
	an instance of the `[Embed]` data class) to the Shader instance. As the
	previous examples demonstrate, you can do this in two ways. You can pass
	the shader bytecode as an argument to the `Shader()` constructor.
	Alternatively, you can set it as the Shader instance's `byteCode`
	property.

	Once a Shader instance is created, it can be used in one of several ways:

	* A shader fill: The output of the shader is used as a fill for content
	drawn with the drawing API. Pass the Shader instance as an argument to the
	`Graphics.beginShaderFill()` method.
	* A shader filter: The output of the shader is used as a graphic filter
	applied to a display object. Assign the Shader instance to the `shader`
	property of a ShaderFilter instance.
	* A blend mode: The output of the shader is rendered as the blending
	between two overlapping display objects. Assign the Shader instance to the
	`blendShader` property of the upper of the two display objects.
	* Background shader processing: The shader executes in the background,
	avoiding the possibility of freezing the display, and dispatches an event
	when processing is complete. Assign the Shader instance to the `shader`
	property of a ShaderJob instance.

	Shader fills, filters, and blends are not supported under GPU rendering.

	**Mobile Browser Support:** This feature is not supported in mobile
	browsers.

	_Adobe AIR profile support:_ This feature is supported on all desktop operating
	systems, but it is not supported on all mobile devices. It is not
	supported on AIR for TV devices. See
	[AIR Profile Support](https://help.adobe.com/en_US/air/build/WS144092a96ffef7cc16ddeea2126bb46b82f-8000.html)
	for more information regarding API support across multiple profiles.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.Program3D)
@:access(openfl.display.ShaderInput)
@:access(openfl.display.ShaderParameter)
// #if (!display && !macro)
#if !macro
@:autoBuild(openfl.utils._internal.ShaderMacro.build())
#end
class Shader
{
	private static inline function getDefaultGLVersion():String
	{
		// Specify the default glVersion.
		// We can use compile defines to guess the value that prevents crashes in the majority of cases.
		//return #if lime_opengles "100" #elseif "120" #end;
		return "300 es";
	}

	/**
	 * Attempt to migrate GLSL code from the current (old) GLSL shader format to the specified (newer) one.
	 * @param source The source to convert.
	 * @param version The version to convert to.
	 * @param isFragment Whether the source is a fragment shader. False if it is a vertex shader.
	 * @return The converted source.
	 */
	private static function processGLSLText(source:String, glVersion:String, isFragment:Bool, ?header:String, ?body:String)
	{
		if (header != null) source = StringTools.replace(source, "#pragma header", buildGLSLHeaders(glVersion) + header);
		if (body != null) source = StringTools.replace(source, "#pragma body", body);
		if (glVersion == "" || glVersion == null) return processGLSLText(source, getDefaultGLVersion(), isFragment);

		// No processing needed on "compatibility" profile
		if (StringTools.endsWith(glVersion, " compatibility")) return source;
		if (StringTools.endsWith(glVersion, " core")) return processGLSLText(source, StringTools.replace(glVersion, " core", ""), isFragment);

		// Recall: Attribute values are per-vertex, varying values are per-fragment
		// Thus, an `out` value in the vertex shader is an `in` value in the fragment shader
		var attributeKeyword:EReg = ~/attribute ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/g; // g to match all
		var varyingKeyword:EReg = ~/varying ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/g; // g to match all

		var texture2DKeyword:EReg = ~/texture2D/g;
		var glFragColorKeyword:EReg = ~/gl_FragColor/g;

		switch (glVersion)
		{
			default:
				// Don't make any changes to undefined versions.
				return source;

			case "100", "110", "120", "130", "140", "150":
				return source;

			case "300 es":
				var result = source;
				// Migrate, replacing "attribute" with "in" and "varying" with "out".
				if (isFragment)
				{
					result = varyingKeyword.replace(result, "in $1 $2");
				}
				else
				{
					result = attributeKeyword.replace(result, "in $1 $2");
					result = varyingKeyword.replace(result, "out $1 $2");
				}
				result = texture2DKeyword.replace(result, "texture");
				result = glFragColorKeyword.replace(result, "fragColor");
				return result;

			case "310 es", "320 es":
				var result = processGLSLText(source, "300 es", isFragment);
				return result;

			case "330":
				#if desktop
				var result = processGLSLText(source, "300 es", isFragment);
				#else
				var result = source;
				#end
				return result;

			case "400", "410", "420", "430", "440", "450", "460":
				var result = processGLSLText(source, "330", isFragment);
				return result;
		}
	}

	private static function buildGLSLHeaders(glVersion:String):String
	{
		if (glVersion == "" || glVersion == null || StringTools.endsWith(glVersion, " compatibility")) return "";
		if (StringTools.endsWith(glVersion, " core")) return buildGLSLHeaders(StringTools.replace(glVersion, " core", ""));

		return switch (glVersion)
		{
			#if desktop
			case "300 es": "layout (location = 0) out vec4 fragColor;\n";
			#else
			case "300 es": "out vec4 fragColor;\n";
			#end

			case "310 es", "320 es", "330", "400", "410", "420", "430", "440", "450", "460":
				buildGLSLHeaders("300 es");

			// Don't add any default headers to undefined versions
			default: "";
		};
	}

	private static function buildGLSLExtensions(glExtensions:Array<{name:String, behavior:String}>, glVersion:String,
			isFragment:Bool):Array<{name:String, behavior:String}>
	{
		if (glVersion == "" || glVersion == null || StringTools.endsWith(glVersion, " compatibility")) return glExtensions;
		if (StringTools.endsWith(glVersion, " core")) return buildGLSLExtensions(glExtensions, StringTools.replace(glVersion, " core", ""), isFragment);

		switch (glVersion)
		{
			// Don't add any extensions to undefined versions
			default:
				return glExtensions;

			#if desktop
			case "300 es", "310 es", "320 es", "330":
				var hasSeparateShaderObjects = false;
				for (extension in glExtensions)
				{
					if (extension.name == "GL_ARB_separate_shader_objects") hasSeparateShaderObjects = true;
					if (extension.name == "GL_EXT_separate_shader_objects") hasSeparateShaderObjects = true;
				}

				if (!hasSeparateShaderObjects)
				{
					#if linux
					return glExtensions.concat([{name: "GL_EXT_separate_shader_objects", behavior: "require"}]);
					#else
					return glExtensions.concat([{name: "GL_ARB_separate_shader_objects", behavior: "require"}]);
					#end
				}
				return glExtensions;
			#end
		}
	}

	/**
		The raw shader bytecode for this Shader instance.
	**/
	public var byteCode(null, default):ByteArray;

	/**
		Provides access to parameters, input images, and metadata for the
		Shader instance. ShaderParameter objects representing parameters for
		the shader, ShaderInput objects representing the input images for the
		shader, and other values representing the shader's metadata are
		dynamically added as properties of the `data` property object when the
		Shader instance is created. Those properties can be used to introspect
		the shader and to set parameter and input values.
		For information about accessing and manipulating the dynamic
		properties of the `data` object, see the ShaderData class description.
	**/
	public var data(get, set):ShaderData;

	/**
		Get or set the GLSL version used in the header when compiling with GLSL.

		- `120` is required for initialization (i.e. providing a default value for) `uniform` variables
		@default The default value is determined at compile time.
	**/
	public var glVersion(get, set):String;

	/**
		The raw of this GLSL Version used before being applied to compile with GLSL.
	**/
	public var glVersionRaw(get, never):Null<String>;


	/**
		Provides additional `#extension` directives to insert in the vertex and fragment shaders.

		Example:
		```
		@:glExtensions([{name: "OES_standard_derivatives", behavior: "require"}])
		@:glVertexExtensions([{name: "OES_standard_derivatives", behavior: "require"}])
		@:glFragmentExtensions([{name: "OES_standard_derivatives", behavior: "require"}])
		```
	**/
	public var glVertexExtensions(get, set):Array<{name:String, behavior:String}>;

	public var glFragmentExtensions(get, set):Array<{name:String, behavior:String}>;

	/**
		The default GLSL vertex header, before being applied to the vertex source.
	**/
	public var glFragmentHeaderRaw(get, never):String;

	/**
		The default GLSL vertex body, before being applied to the vertex source.
	**/
	public var glFragmentBodyRaw(get, never):String;

	/**
		The default GLSL fragment source, before `#pragma` values are replaced.
	**/
	public var glFragmentSourceRaw(get, never):String;

	/**
		Get or set the fragment source used when compiling with GLSL.

		This property is not available on the Flash target.
	**/
	public var glFragmentSource(get, set):String;

	/**
		The compiled GLProgram if available.

		This property is not available on the Flash target.
	**/
	@SuppressWarnings("checkstyle:Dynamic") public var glProgram(default, null):GLProgram;

	/**
		The default GLSL vertex header, before being applied to the vertex source.
	**/
	public var glVertexHeaderRaw(get, never):String;

	/**
		The default GLSL vertex body, before being applied to the vertex source.
	**/
	public var glVertexBodyRaw(get, never):String;

	/**
		The default GLSL vertex source, before `#pragma` values are replaced.
	**/
	public var glVertexSourceRaw(get, never):String;

	/**
		Get or set the vertex source used when compiling with GLSL.

		This property is not available on the Flash target.
	**/
	public var glVertexSource(get, set):String;

	/**
		The precision of math operations performed by the shader.
		The set of possible values for the `precisionHint` property is defined
		by the constants in the ShaderPrecision class.

		The default value is `ShaderPrecision.FULL`. Setting the precision to
		`ShaderPrecision.FAST` can speed up math operations at the expense of
		precision.

		Full precision mode (`ShaderPrecision.FULL`) computes all math
		operations to the full width of the IEEE 32-bit floating standard and
		provides consistent behavior on all platforms. In this mode, some math
		operations such as trigonometric and exponential functions can be
		slow.

		Fast precision mode (`ShaderPrecision.FAST`) is designed for maximum
		performance but does not work consistently on different platforms and
		individual CPU configurations. In many cases, this level of precision
		is sufficient to create graphic effects without visible artifacts.

		The precision mode selection affects the following shader operations.
		These operations are faster on an Intel processor with the SSE
		instruction set:

		* `sin(x)`
		* `cos(x)`
		* `tan(x)`
		* `asin(x)`
		* `acos(x)`
		* `atan(x)`
		* `atan(x, y)`
		* `exp(x)`
		* `exp2(x)`
		* `log(x)`
		* `log2(x)`
		* `pow(x, y)`
		* `reciprocal(x)`
		* `sqrt(x)`
	**/
	public var precisionHint:ShaderPrecision;

	/**
		The compiled Program3D if available.

		This property is not available on the Flash target.
	**/
	public var program:Program3D;

	@:noCompletion private var __alpha:ShaderParameter<Float>;
	@:noCompletion private var __bitmap:ShaderInput<BitmapData>;
	@:noCompletion private var __colorMultiplier:ShaderParameter<Float>;
	@:noCompletion private var __colorOffset:ShaderParameter<Float>;
	@:noCompletion private var __context:Context3D;
	@:noCompletion private var __data:ShaderData;
	@:noCompletion private var __glVertexExtensions:Array<{name:String, behavior:String}>;
	@:noCompletion private var __glFragmentExtensions:Array<{name:String, behavior:String}>;
	@:noCompletion private var __glVersionRaw:String;
	@:noCompletion private var __glVersion:String;
	@:noCompletion private var __glFragmentHeaderRaw:String;
	@:noCompletion private var __glFragmentBodyRaw:String;
	@:noCompletion private var __glFragmentSourceRaw:String;
	@:noCompletion private var __glFragmentSource:String;
	@:noCompletion private var __glSourceDirty:Bool;
	@:noCompletion private var __glVertexHeaderRaw:String;
	@:noCompletion private var __glVertexBodyRaw:String;
	@:noCompletion private var __glVertexSourceRaw:String;
	@:noCompletion private var __glVertexSource:String;
	@:noCompletion private var __hasColorTransform:ShaderParameter<Bool>;
	@:noCompletion private var __inputBitmapData:Array<ShaderInput<BitmapData>>;
	@:noCompletion private var __isGenerated:Bool;
	@:noCompletion private var __matrix:ShaderParameter<Float>;
	@:noCompletion private var __numPasses:Int;
	@:noCompletion private var __paramBool:Array<ShaderParameter<Bool>>;
	@:noCompletion private var __paramFloat:Array<ShaderParameter<Float>>;
	@:noCompletion private var __paramInt:Array<ShaderParameter<Int>>;
	@:noCompletion private var __position:ShaderParameter<Float>;
	@:noCompletion private var __textureCoord:ShaderParameter<Float>;
	@:noCompletion private var __texture:ShaderInput<BitmapData>;
	@:noCompletion private var __textureSize:ShaderParameter<Float>;

	#if openfljs
	@:noCompletion private static function __init__()
	{
		untyped Object.defineProperties(Shader.prototype, {
			"data": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_data (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_data (v); }")
			},
			"glVertexExtensions": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVertexExtensions (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_glVertexExtensions (v); }")
			},
			"glFragmentExtensions": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glFragmentExtensions (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_glFragmentExtensions (v); }")
			},
			"glVersion": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVersion (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_glVersion (v); }")
			},
			"glFragmentHeaderRaw": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glFragmentHeaderRaw (); }"),
			},
			"glFragmentBodyRaw": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glFragmentBodyRaw (); }"),
			},
			"glFragmentSourceRaw": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glFragmentSourceRaw (); }"),
			},
			"glFragmentSource": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glFragmentSource (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_glFragmentSource (v); }")
			},
			"glVertexHeaderRaw": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVertexHeaderRaw (); }"),
			},
			"glVertexBodyRaw": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVertexBodyRaw (); }"),
			},
			"glVertexSourceRaw": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVertexSourceRaw (); }"),
			},
			"glVertexSource": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_glVertexSource (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_glVertexSource (v); }")
			},
		});
	}
	#end

	/**
		Creates a new Shader instance.

		@param code The raw shader bytecode to link to the Shader.
	**/
	public function new(code:ByteArray = null)
	{
		byteCode = code;
		precisionHint = FULL;

		__glSourceDirty = true;
		__numPasses = 1;
		__data = new ShaderData(code);
	}

	@:noCompletion private function __clearUseArray():Void
	{
		for (parameter in __paramBool)
		{
			parameter.__useArray = false;
		}

		for (parameter in __paramFloat)
		{
			parameter.__useArray = false;
		}

		for (parameter in __paramInt)
		{
			parameter.__useArray = false;
		}
	}

	// private function __clone ():Shader {
	// var classType = Type.getClass (this);
	// var shader = Type.createInstance (classType, []);
	// for (input in __inputBitmapData) {
	// 	if (input.input != null) {
	// 		var field = Reflect.field (shader.data, input.name);
	// 		field.channels = input.channels;
	// 		field.height = input.height;
	// 		field.input = input.input;
	// 		field.smoothing = input.smoothing;
	// 		field.width = input.width;
	// 	}
	// }
	// for (param in __paramBool) {
	// 	if (param.value != null) {
	// 		Reflect.field (shader.data, param.name).value = param.value.copy ();
	// 	}
	// }
	// for (param in __paramFloat) {
	// 	if (param.value != null) {
	// 		Reflect.field (shader.data, param.name).value = param.value.copy ();
	// 	}
	// }
	// for (param in __paramInt) {
	// 	if (param.value != null) {
	// 		Reflect.field (shader.data, param.name).value = param.value.copy ();
	// 	}
	// }
	// return shader;
	// }
	@:noCompletion private function __createGLShader(source:String, type:Int):GLShader
	{
		var gl = __context.gl;

		var shader = gl.createShader(type);
		gl.shaderSource(shader, source);
		gl.compileShader(shader);
		var shaderInfoLog = gl.getShaderInfoLog(shader);
		var hasInfoLog = shaderInfoLog != null && StringTools.trim(shaderInfoLog) != "";
		var isError = gl.getShaderParameter(shader, gl.COMPILE_STATUS) == 0;

		if (hasInfoLog || isError)
		{
			__logGLShaderInfo(isError, type, shaderInfoLog, source);
		}

		return shader;
	}

	/**
	 * Retrieves the line number from a shader log line.
	 */
	@:noCompletion private var __lineExtractor = ~/^\w+?: \d+:(\d+):(.+$)/;
	/**
	 * Searches for strings that have only whitespace.
	 * 
	 * **Note:** Searching for all whitespace via `~/^\s*$/` caused false-negatives,
	 * notably: `String.fromCharCode(0)` is `false` but `\W` is `true`.
	 */
	@:noCompletion private var __isEmptyLine = ~/^\W*$/;
	@:noCompletion private function __logGLShaderInfo(isError:Bool, type:Int, infoLog:String, source:String):Void
	{
		var message = "";
		var lines = source.split("\n");
		var failingLine:String = null;
		for (log in infoLog.split("\n"))
		{
			// ignore empty lines
			if (__isEmptyLine.match(log))
				continue;

			// look for a line number
			if (!__lineExtractor.match(log))
			{
				// Could not find expected info, abort pretty formatting
				failingLine = log;
				break;
			}

			var lineNumberStr = __lineExtractor.matched(1);
			var lineNumber = Std.parseInt(lineNumberStr);
			var info = __lineExtractor.matched(2);
			if (lineNumber >= lines.length)
			{
				// EOF errors will not have a valid line
				message += '\n\n $lineNumber | $info';
			}
			else
			{
				// Add the relevant line to each log
				var line = lines[lineNumber - 1];
				var indent = StringTools.lpad("|", " ", lineNumberStr.length + 3);
				message += '\n\n $lineNumber | $line\n$indent ${info}';
			}
		}

		// If we couldn't parse the logs, output the old, verbose format
		if (failingLine != null)
			message = '\nFailed to simplify log:"$failingLine"\n$infoLog\n$source';

		var typeName = (type == __context.gl.VERTEX_SHADER) ? "vertex" : "fragment";
		if (isError) Log.error('Error compiling $typeName shader $message');
		else Log.debug('Info compiling $typeName shader $message');
	}

	@:noCompletion private function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		var gl = __context.gl;

		var vertexShader = __createGLShader(vertexSource, gl.VERTEX_SHADER);
		var fragmentShader = __createGLShader(fragmentSource, gl.FRAGMENT_SHADER);

		var program = gl.createProgram();

		// Fix support for drivers that don't draw if attribute 0 is disabled
		for (param in __paramFloat)
		{
			if (param.name.indexOf("Position") > -1 && StringTools.startsWith(param.name, "openfl_"))
			{
				gl.bindAttribLocation(program, 0, param.name);
				break;
			}
		}

		gl.attachShader(program, vertexShader);
		gl.attachShader(program, fragmentShader);
		gl.linkProgram(program);

		if (gl.getProgramParameter(program, gl.LINK_STATUS) == 0)
		{
			var message = "Unable to initialize the shader program";
			message += "\n" + gl.getProgramInfoLog(program);
			Log.error(message);
		}

		return program;
	}

	@:noCompletion private function __disable():Void
	{
		if (program != null)
		{
			__disableGL();
		}
	}

	@:noCompletion private function __disableGL():Void
	{
		var gl = __context.gl;

		var textureCount = 0;

		for (input in __inputBitmapData)
		{
			input.__disableGL(__context, textureCount);
			textureCount++;
			if (textureCount == gl.MAX_TEXTURE_IMAGE_UNITS) break;
		}

		for (parameter in __paramBool)
		{
			parameter.__disableGL(__context);
		}

		for (parameter in __paramFloat)
		{
			parameter.__disableGL(__context);
		}

		for (parameter in __paramInt)
		{
			parameter.__disableGL(__context);
		}

		__context.__bindGLArrayBuffer(null);

		#if lime
		if (__context.__context.type == OPENGL)
		{
			gl.disable(gl.TEXTURE_2D);
		}
		#end
	}

	@:noCompletion private function __enable():Void
	{
		__init();

		if (program != null)
		{
			__enableGL();
		}
	}

	@:noCompletion private function __enableGL():Void
	{
		var textureCount = 0;

		var gl = __context.gl;

		for (input in __inputBitmapData)
		{
			gl.uniform1i(input.index, textureCount);
			textureCount++;
		}

		#if lime
		if (__context.__context.type == OPENGL && textureCount > 0)
		{
			gl.enable(gl.TEXTURE_2D);
		}
		#end
	}

	@:noCompletion private function __init():Void
	{
		if (__data == null)
		{
			__data = cast new ShaderData(null);
		}

		if (__glFragmentSource != null && __glVertexSource != null && (program == null || __glSourceDirty))
		{
			__initGL();
		}
	}

	@:noCompletion private function __buildSourcePrefix(isFragment:Bool):String
	{
		var result = "";

		var ver = StringTools.replace(StringTools.replace(__glVersion, " core", ""), " compatibility", "");
		var canInjectBlendAdvancedExt = OpenGLRenderer.hasKHRBlendAdvancedExt && isFragment && 
			ver != "100" && ver != "110" && ver != "120" && ver != "130" && ver != "140" && ver != "150";

		if (canInjectBlendAdvancedExt) result += "#extension GL_KHR_blend_equation_advanced : enable\n";

		var extList = buildGLSLExtensions(isFragment ? __glFragmentExtensions : __glVertexExtensions, __glVersion, isFragment);
		for (ext in extList)
		{
			result += "#extension " + ext.name + " : " + ext.behavior + "\n";
		}

		// #version must be the first directive and cannot be repeated,
		// while #extension directives must be before any non-preprocessor tokens.

		result += "\n#ifdef GL_ES\n" + (
			precisionHint == FULL ?
			"#ifdef GL_FRAGMENT_PRECISION_HIGH\nprecision highp float;\n#else\nprecision mediump float;\n#endif\n" :
			"precision lowp float;\n"
		) + "#endif\n";
		if (__glVersion != null && __glVersion != "") result = "#version " + __glVersion + "\n" + result;

		if (canInjectBlendAdvancedExt) result += "#ifdef GL_KHR_blend_equation_advanced\nlayout(blend_support_all_equations) out;\n#endif\n";

		return result;
	}

	@:noCompletion private function __initGL():Void
	{
		if (__glSourceDirty || __paramBool == null)
		{
			__glSourceDirty = false;
			program = null;

			__inputBitmapData = new Array();
			__paramBool = new Array();
			__paramFloat = new Array();
			__paramInt = new Array();

			__processGLData(glVertexSource, "attribute");
			__processGLData(glVertexSource, "in");
			__processGLData(glVertexSource, "uniform");
			__processGLData(glFragmentSource, "uniform");
		}

		if (__context != null && program == null)
		{
			var gl = __context.gl;

			var vertex = __buildSourcePrefix(false) + glVertexSource;
			var fragment = __buildSourcePrefix(true) + glFragmentSource;

			var id = vertex + fragment;

			if (__context.__programs.exists(id))
			{
				program = __context.__programs.get(id);
			}
			else
			{
				program = __context.createProgram(GLSL);

				// TODO
				// program.uploadSources (vertex, fragment);
				program.__glProgram = __createGLProgram(vertex, fragment);

				__context.__programs.set(id, program);
			}

			if (program != null)
			{
				glProgram = program.__glProgram;

				for (input in __inputBitmapData)
				{
					if (input.__isUniform)
					{
						input.index = gl.getUniformLocation(glProgram, input.name);
					}
					else
					{
						input.index = gl.getAttribLocation(glProgram, input.name);
					}
				}

				for (parameter in __paramBool)
				{
					if (parameter.__isUniform)
					{
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					}
					else
					{
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}

				for (parameter in __paramFloat)
				{
					if (parameter.__isUniform)
					{
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					}
					else
					{
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}

				for (parameter in __paramInt)
				{
					if (parameter.__isUniform)
					{
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					}
					else
					{
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}
			}
		}
	}

	@:noCompletion private function __processGLData(source:String, storageType:String):Void
	{
		var position, name, type, regex;

		if (storageType == "uniform")
		{
			regex = ~/uniform ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/;
		}
		else if (storageType == "in")
		{
			regex = ~/in ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/;
		}
		else
		{
			regex = ~/attribute ([A-Za-z0-9]+) ([A-Za-z0-9_]+)/;
		}

		var lastMatch = 0;

		while (regex.matchSub(source, lastMatch))
		{
			type = regex.matched(1);
			name = regex.matched(2);

			if (StringTools.startsWith(name, "gl_"))
			{
				continue;
			}

			var isUniform = (storageType == "uniform");

			if (StringTools.startsWith(type, "sampler"))
			{
				var input = new ShaderInput<BitmapData>();
				input.name = name;
				input.__isUniform = isUniform;
				__inputBitmapData.push(input);

				switch (name)
				{
					case "openfl_Texture":
						__texture = input;
					case "bitmap":
						__bitmap = input;
					default:
				}

				Reflect.setField(__data, name, input);
				if (__isGenerated && thisHasField(name)) Reflect.setProperty(this, name, input);
			}
			else if (!Reflect.hasField(__data, name) || Reflect.field(__data, name) == null)
			{
				var parameterType:ShaderParameterType = switch (type)
				{
					case "bool": BOOL;
					case "double", "float": FLOAT;
					case "int", "uint": INT;
					case "bvec2": BOOL2;
					case "bvec3": BOOL3;
					case "bvec4": BOOL4;
					case "ivec2", "uvec2": INT2;
					case "ivec3", "uvec3": INT3;
					case "ivec4", "uvec4": INT4;
					case "vec2", "dvec2": FLOAT2;
					case "vec3", "dvec3": FLOAT3;
					case "vec4", "dvec4": FLOAT4;
					case "mat2", "mat2x2": MATRIX2X2;
					case "mat2x3": MATRIX2X3;
					case "mat2x4": MATRIX2X4;
					case "mat3x2": MATRIX3X2;
					case "mat3", "mat3x3": MATRIX3X3;
					case "mat3x4": MATRIX3X4;
					case "mat4x2": MATRIX4X2;
					case "mat4x3": MATRIX4X3;
					case "mat4", "mat4x4": MATRIX4X4;
					default: null;
				}

				var length = switch (parameterType)
				{
					case BOOL2, INT2, FLOAT2: 2;
					case BOOL3, INT3, FLOAT3: 3;
					case BOOL4, INT4, FLOAT4, MATRIX2X2: 4;
					case MATRIX3X3: 9;
					case MATRIX4X4: 16;
					default: 1;
				}

				var arrayLength = switch (parameterType)
				{
					case MATRIX2X2: 2;
					case MATRIX3X3: 3;
					case MATRIX4X4: 4;
					default: 1;
				}

				switch (parameterType)
				{
					case BOOL, BOOL2, BOOL3, BOOL4:
						var parameter = new ShaderParameter<Bool>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						parameter.__isBool = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramBool.push(parameter);

						if (name == "openfl_HasColorTransform")
						{
							__hasColorTransform = parameter;
						}

						Reflect.setField(__data, name, parameter);
						if (__isGenerated && thisHasField(name)) Reflect.setProperty(this, name, parameter);

					case INT, INT2, INT3, INT4:
						var parameter = new ShaderParameter<Int>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						parameter.__isInt = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramInt.push(parameter);
						Reflect.setField(__data, name, parameter);
						if (__isGenerated && thisHasField(name)) Reflect.setProperty(this, name, parameter);

					default:
						var parameter = new ShaderParameter<Float>();
						parameter.name = name;
						parameter.type = parameterType;
						parameter.__arrayLength = arrayLength;
						#if lime
						if (arrayLength > 0) parameter.__uniformMatrix = new Float32Array(arrayLength * arrayLength);
						#end
						parameter.__isFloat = true;
						parameter.__isUniform = isUniform;
						parameter.__length = length;
						__paramFloat.push(parameter);

						if (StringTools.startsWith(name, "openfl_"))
						{
							switch (name)
							{
								case "openfl_Alpha": __alpha = parameter;
								case "openfl_ColorMultiplier": __colorMultiplier = parameter;
								case "openfl_ColorOffset": __colorOffset = parameter;
								case "openfl_Matrix": __matrix = parameter;
								case "openfl_Position": __position = parameter;
								case "openfl_TextureCoord": __textureCoord = parameter;
								case "openfl_TextureSize": __textureSize = parameter;
								default:
							}
						}

						Reflect.setField(__data, name, parameter);
						if (__isGenerated && thisHasField(name)) Reflect.setProperty(this, name, parameter);
				}
			}

			position = regex.matchedPos();
			lastMatch = position.pos + position.len;
		}
	}

	@:noCompletion private function __update():Void
	{
		if (program != null)
		{
			__updateGL();
		}
	}

	@:noCompletion private function __updateFromBuffer(shaderBuffer:ShaderBuffer, bufferOffset:Int):Void
	{
		if (program != null)
		{
			__updateGLFromBuffer(shaderBuffer, bufferOffset);
		}
	}

	@:noCompletion private function __updateGL():Void
	{
		var textureCount = 0;

		for (input in __inputBitmapData)
		{
			input.__updateGL(__context, textureCount);
			textureCount++;
		}

		for (parameter in __paramBool)
		{
			parameter.__updateGL(__context);
		}

		for (parameter in __paramFloat)
		{
			parameter.__updateGL(__context);
		}

		for (parameter in __paramInt)
		{
			parameter.__updateGL(__context);
		}
	}

	@:noCompletion private function __updateGLFromBuffer(shaderBuffer:ShaderBuffer, bufferOffset:Int):Void
	{
		var textureCount = 0;
		var input, inputData, inputFilter, inputMipFilter, inputWrap;

		for (i in 0...shaderBuffer.inputCount)
		{
			input = shaderBuffer.inputRefs[i];
			inputData = shaderBuffer.inputs[i];
			inputFilter = shaderBuffer.inputFilter[i];
			inputMipFilter = shaderBuffer.inputMipFilter[i];
			inputWrap = shaderBuffer.inputWrap[i];

			if (inputData != null)
			{
				input.__updateGL(__context, textureCount, inputData, inputFilter, inputMipFilter, inputWrap);
				textureCount++;
			}
		}

		var gl = __context.gl;

		if (shaderBuffer.paramDataLength > 0)
		{
			if (shaderBuffer.paramDataBuffer == null)
			{
				shaderBuffer.paramDataBuffer = gl.createBuffer();
			}

			// Log.verbose ("bind param data buffer (length: " + shaderBuffer.paramData.length + ") (" + shaderBuffer.paramCount + ")");

			__context.__bindGLArrayBuffer(shaderBuffer.paramDataBuffer);
			gl.bufferData(gl.ARRAY_BUFFER, shaderBuffer.paramData, gl.DYNAMIC_DRAW);
		}
		else
		{
			// Log.verbose ("bind buffer null");

			__context.__bindGLArrayBuffer(null);
		}

		var boolIndex = 0;
		var floatIndex = 0;
		var intIndex = 0;

		var boolCount = shaderBuffer.paramBoolCount;
		var floatCount = shaderBuffer.paramFloatCount;
		var paramData = shaderBuffer.paramData;

		var boolRef, floatRef, intRef, hasOverride;
		var overrideBoolValue:Array<Bool> = null,
			overrideFloatValue:Array<Float> = null,
			overrideIntValue:Array<Int> = null;

		for (i in 0...shaderBuffer.paramCount)
		{
			hasOverride = false;

			if (i < boolCount)
			{
				boolRef = shaderBuffer.paramRefs_Bool[boolIndex];

				for (j in 0...shaderBuffer.overrideBoolCount)
				{
					if (boolRef.name == shaderBuffer.overrideBoolNames[j])
					{
						overrideBoolValue = shaderBuffer.overrideBoolValues[j];
						hasOverride = true;
						break;
					}
				}

				if (hasOverride)
				{
					boolRef.__updateGL(__context, overrideBoolValue);
				}
				else
				{
					boolRef.__updateGLFromBuffer(__context, paramData, shaderBuffer.paramPositions[i], shaderBuffer.paramLengths[i], bufferOffset);
				}

				boolIndex++;
			}
			else if (i < boolCount + floatCount)
			{
				floatRef = shaderBuffer.paramRefs_Float[floatIndex];

				for (j in 0...shaderBuffer.overrideFloatCount)
				{
					if (floatRef.name == shaderBuffer.overrideFloatNames[j])
					{
						overrideFloatValue = shaderBuffer.overrideFloatValues[j];
						hasOverride = true;
						break;
					}
				}

				if (hasOverride)
				{
					floatRef.__updateGL(__context, overrideFloatValue);
				}
				else
				{
					floatRef.__updateGLFromBuffer(__context, paramData, shaderBuffer.paramPositions[i], shaderBuffer.paramLengths[i], bufferOffset);
				}

				floatIndex++;
			}
			else
			{
				intRef = shaderBuffer.paramRefs_Int[intIndex];

				for (j in 0...shaderBuffer.overrideIntCount)
				{
					if (intRef.name == shaderBuffer.overrideIntNames[j])
					{
						overrideIntValue = cast shaderBuffer.overrideIntValues[j];
						hasOverride = true;
						break;
					}
				}

				if (hasOverride)
				{
					intRef.__updateGL(__context, overrideIntValue);
				}
				else
				{
					intRef.__updateGLFromBuffer(__context, paramData, shaderBuffer.paramPositions[i], shaderBuffer.paramLengths[i], bufferOffset);
				}

				intIndex++;
			}
		}
	}

	// Get & Set Methods
	@:noCompletion private function get_data():ShaderData
	{
		if (__glSourceDirty || __data == null)
		{
			__init();
		}

		return __data;
	}

	@:noCompletion private function set_data(value:ShaderData):ShaderData
	{
		return __data = cast value;
	}

	@:noCompletion private function get_glVersionRaw():Null<String>
	{
		return __glVersionRaw;
	}

	@:noCompletion private function get_glVersion():String
	{
		return __glVersion;
	}

	@:noCompletion private function set_glVersion(value:Null<String>):String
	{
		__glVersionRaw = value;
		if (value == null || value == "") value = getDefaultGLVersion();
		if (value != __glVersion)
		{
			__glSourceDirty = true;
			if (__glVertexSourceRaw != null)
			{
				__glVertexSource = processGLSLText(__glVertexSourceRaw, value, false, __glVertexHeaderRaw, __glVertexBodyRaw);
			}
			if (__glFragmentSourceRaw != null)
			{
				__glFragmentSource = processGLSLText(__glFragmentSourceRaw, value, true, __glFragmentHeaderRaw, __glFragmentBodyRaw);
			}
		}

		return __glVersion = value;
	}

	@:noCompletion private function get_glVertexExtensions():Array<{name:String, behavior:String}>
	{
		return __glVertexExtensions;
	}

	@:noCompletion private function get_glFragmentExtensions():Array<{name:String, behavior:String}>
	{
		return __glFragmentExtensions;
	}

	@:noCompletion private function set_glVertexExtensions(value:Array<{name:String, behavior:String}>):Array<{name:String, behavior:String}>
	{
		if (value != __glVertexExtensions)
		{
			__glSourceDirty = true;
		}

		return __glVertexExtensions = value;
	}

	@:noCompletion private function set_glFragmentExtensions(value:Array<{name:String, behavior:String}>):Array<{name:String, behavior:String}>
	{
		if (value != __glFragmentExtensions)
		{
			__glSourceDirty = true;
		}

		return __glFragmentExtensions = value;
	}

	@:noCompletion private function get_glFragmentHeaderRaw():String
	{
		return __glFragmentHeaderRaw;
	}

	@:noCompletion private function get_glFragmentBodyRaw():String
	{
		return __glFragmentBodyRaw;
	}

	@:noCompletion private function get_glFragmentSourceRaw():String
	{
		return __glFragmentSourceRaw;
	}

	@:noCompletion private function get_glFragmentSource():String
	{
		return __glFragmentSource;
	}

	@:noCompletion private function set_glFragmentSource(value:String):String
	{
		__glFragmentSourceRaw = value;
		if (value != null) value = processGLSLText(value, __glVersion, true, __glFragmentHeaderRaw, __glFragmentBodyRaw);
		if (value != __glFragmentSource)
		{
			__glSourceDirty = true;
		}

		return __glFragmentSource = value;
	}

	@:noCompletion private function get_glVertexHeaderRaw():String
	{
		return __glVertexHeaderRaw;
	}

	@:noCompletion private function get_glVertexBodyRaw():String
	{
		return __glVertexBodyRaw;
	}

	@:noCompletion private function get_glVertexSourceRaw():String
	{
		return __glVertexSourceRaw;
	}

	@:noCompletion private function get_glVertexSource():String
	{
		return __glVertexSource;
	}

	@:noCompletion private function set_glVertexSource(value:String):String
	{
		__glVertexSourceRaw = value;
		if (value != null) value = processGLSLText(value, __glVersion, false, __glVertexHeaderRaw, __glVertexBodyRaw);
		if (value != __glVertexSource)
		{
			__glSourceDirty = true;
		}

		return __glVertexSource = value;
	}

	private var __fieldList:Array<String> = null;

	private function thisHasField(name:String)
	{
		// Reflect.hasField(this, name) is REALLY expensive so we cache the result.
		if (__fieldList == null)
		{
			__fieldList = Reflect.fields(this).concat(Type.getInstanceFields(Type.getClass(this)));
		}
		return __fieldList.indexOf(name) != -1;
	}
}
#else
typedef Shader = flash.display.Shader;
#end
