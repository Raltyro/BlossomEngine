package openfl.display;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;
using haxe.macro.Tools;
using haxe.macro.TypeTools;

@SuppressWarnings("checkstyle:FieldDocComment")
class Shader {
	//#if 0
	//private static var __suppressWarning:Array<Class<Dynamic>> = [Expr];
	//#end

	#if macro
	static final _vertexPragmasList:Map<String, String> = []; // ex: FlxGraphicShader_header
	static final _fragmentPragmasList:Map<String, String> = [];

	public static function build():Array<Field> {
		var fields = Context.getBuildFields();

		var nextFragmentDontOverride = false, nextVertexDontOverride = false;
		var glFragmentPragmas:Map<String, String> = [], glVertexPragmas:Map<String, String> = [];
		function addPragma(pragmas:Map<String, String>, key:String, value:String) {
			if (pragmas.exists(key)) pragmas.set(key, value + '\n' + pragmas.get(key));
			else pragmas.set(key, value);
		}

		var glFragmentExtensions = [], glVertexExtensions = [];
		var glFragmentSource:String = null, glVertexSource:String = null, glVersion:String = null;
		var prefixFragment = "glFragment", prefixVertex = "glVertex", name:String;

		for (field in fields) {
			for (meta in field.meta) {
				switch (name = meta.name.charAt(0) == ":" ? meta.name.substr(1) : meta.name) {
					case "glFragmentDontOverride": nextFragmentDontOverride = true;
					case "glVertexDontOverride": nextVertexDontOverride = true;
					case "glVersion":
						glVersion = meta.params[0].getValue();

					case "glFragmentExtensions":
						glFragmentExtensions = glFragmentExtensions.concat(meta.params[0].getValue());

					case "glVertexExtensions":
						glVertexExtensions = glVertexExtensions.concat(meta.params[0].getValue());

					case "glFragmentSource":
						glFragmentSource = meta.params[0].getValue();

					case "glVertexSource":
						glVertexSource = meta.params[0].getValue();

					case "glExtensions":
						glFragmentExtensions = glFragmentExtensions.concat(meta.params[0].getValue());
						glVertexExtensions = glVertexExtensions.concat(meta.params[0].getValue());

					case "glFragmentPragma":
						addPragma(glFragmentPragmas, meta.params[0].getValue(), meta.params[1].getValue());

					case "glVertexPragma":
						addPragma(glVertexPragmas, meta.params[0].getValue(), meta.params[1].getValue());

					default:
						if (name.substr(0, prefixFragment.length) == prefixFragment)
							addPragma(glFragmentPragmas, name.substr(prefixFragment.length).toLowerCase(), meta.params[0].getValue());

						if (name.substr(0, prefixVertex.length) == prefixVertex)
							addPragma(glVertexPragmas, name.substr(prefixVertex.length).toLowerCase(), meta.params[0].getValue());
				}
			}
		}

		var fragmentDontOverride = nextFragmentDontOverride, vertexDontOverride = nextVertexDontOverride;

		var pos = Context.currentPos(), localClass = Context.getLocalClass().get();
		var superClass = localClass.superClass != null ? localClass.superClass.t.get() : null;
		var parent = superClass, parentFields;

		while (parent != null) {
			parentFields = [parent.constructor.get()].concat(parent.fields.get());
			for (field in parentFields) {
				for (meta in field.meta.get()) {
					switch (name = meta.name.charAt(0) == ":" ? meta.name.substr(1) : meta.name) {
						case "glFragmentDontOverride": nextFragmentDontOverride = true;
						case "glVertexDontOverride": nextVertexDontOverride = true;
						case "glVersion":
							if (glVersion == null) glVersion = meta.params[0].getValue();

						case "glFragmentExtensions":
							if (!fragmentDontOverride) glFragmentExtensions = glFragmentExtensions.concat(meta.params[0].getValue());

						case "glVertexExtensions":
							if (!vertexDontOverride) glVertexExtensions = glVertexExtensions.concat(meta.params[0].getValue());

						case "glFragmentSource":
							if (glFragmentSource == null) glFragmentSource = meta.params[0].getValue();

						case "glVertexSource":
							if (glVertexSource == null) glVertexSource = meta.params[0].getValue();

						case "glExtensions":
							if (!fragmentDontOverride) glFragmentExtensions = glFragmentExtensions.concat(meta.params[0].getValue());
							if (!vertexDontOverride) glVertexExtensions = glVertexExtensions.concat(meta.params[0].getValue());

						case "glFragmentPragma":
							if (!fragmentDontOverride) addPragma(glFragmentPragmas, meta.params[0].getValue(), meta.params[1].getValue());

						case "glVertexPragma":
							if (!vertexDontOverride) addPragma(glVertexPragmas, meta.params[0].getValue(), meta.params[1].getValue());

						default:
							if (!fragmentDontOverride && name.substr(0, prefixFragment.length) == prefixFragment)
								addPragma(glFragmentPragmas, name.substr(prefixFragment.length).toLowerCase(), meta.params[0].getValue());

							if (!vertexDontOverride && name.substr(0, prefixVertex.length) == prefixVertex)
								addPragma(glVertexPragmas, name.substr(prefixVertex.length).toLowerCase(), meta.params[0].getValue());
					}
				}
			}

			fragmentDontOverride = nextFragmentDontOverride;
			vertexDontOverride = nextVertexDontOverride;

			parent = parent.superClass != null ? parent.superClass.t.get() : null;
		}

		if (glVertexSource != null || glFragmentSource != null) {
			var shaderDataFields = new Array<Field>();
			var uniqueFields = [];

			processFields(glVertexSource, "attribute", shaderDataFields, pos);
			processFields(glVertexSource, "in", shaderDataFields, pos); // For higher GLSL versions
			processFields(glVertexSource, "uniform", shaderDataFields, pos);
			processFields(glFragmentSource, "uniform", shaderDataFields, pos);

			var position, pragmaSource, regex = ~/#pragma (\w+)/, lastMatch = 0;
			while (regex.matchSub(glVertexSource, lastMatch)) {
				if ((pragmaSource = glVertexPragmas.get(regex.matched(1))) != null) {
					processFields(pragmaSource, "attribute", shaderDataFields, pos);
					processFields(pragmaSource, "in", shaderDataFields, pos); // For higher GLSL versions
					processFields(pragmaSource, "uniform", shaderDataFields, pos);
				}

				position = regex.matchedPos();
				lastMatch = position.pos + position.len;
			}

			lastMatch = 0;
			while (regex.matchSub(glFragmentSource, lastMatch)) {
				if ((pragmaSource = glFragmentPragmas.get(regex.matched(1))) != null) {
					processFields(pragmaSource, "uniform", shaderDataFields, pos);
				}

				position = regex.matchedPos();
				lastMatch = position.pos + position.len;
			}

			if (shaderDataFields.length > 0) {
				var fieldNames = new Map<String, Bool>();

				for (field in shaderDataFields) {
					parent = superClass;

					while (parent != null) {
						for (parentField in parent.fields.get()) {
							if (parentField.name == field.name)
								fieldNames.set(field.name, true);
						}

						parent = parent.superClass != null ? parent.superClass.t.get() : null;
					}

					if (!fieldNames.exists(field.name)) uniqueFields.push(field);
					fieldNames[field.name] = true;
				}
			}

			// #if !display
			for (field in fields) {
				switch (field.name) {
					case "new":
						var block = switch (field.kind) {
							case FFun(f):
								if (f.expr == null) null;

								switch (f.expr.expr) {
									case EBlock(e): e;
									default: null;
								}

							default: null;
						}

						block.unshift(Context.parse("__isGenerated = true", pos));

						if (glFragmentSource != null)
							block.unshift(macro if (__glFragmentSource == null) glFragmentSource = $v{glFragmentSource});

						if (glVertexSource != null)
							block.unshift(macro if (__glVertexSource == null) glVertexSource = $v{glVertexSource});

						if (glFragmentExtensions != null)
							block.unshift(macro if (__glFragmentExtensions == null) glFragmentExtensions = $v{glFragmentExtensions});

						if (glVertexExtensions != null)
							block.unshift(macro if (__glVertexExtensions == null) glVertexExtensions = $v{glVertexExtensions});

						block.unshift(macro if (__glVersion == null) glVersion = $v{glVersion});
						block.unshift(macro if (__glVertexPragmas == null) __glVertexPragmas = $v{glVertexPragmas});
						block.unshift(macro if (__glFragmentPragmas == null) __glFragmentPragmas = $v{glFragmentPragmas});

						block.push(Context.parse("__initGL()", pos));

					default:
				}
			}
			// #end

			fields = fields.concat(uniqueFields);
		}

		return fields;
	}

	private static function processFields(source:String, storageType:String, fields:Array<Field>, pos:Position) {
		if (source == null) return;

		var position, name, type, regex, arrLength:Int, field:Field;

		if (storageType == "uniform")
		{
			regex = ~/uniform ([A-Za-z0-9]+) ([A-Za-z0-9_]+)(?:\[(\d+)\])?/;
		}
		else if (storageType == "in")
		{
			regex = ~/in ([A-Za-z0-9]+) ([A-Za-z0-9_]+)(?:\[(\d+)\])?/;
		}
		else
		{
			regex = ~/attribute ([A-Za-z0-9]+) ([A-Za-z0-9_]+)(?:\[(\d+)\])?/;
		}

		var lastMatch = 0, fieldAccess;

		while (regex.matchSub(source, lastMatch))
		{
			type = regex.matched(1);
			name = regex.matched(2);
			arrLength = regex.matched(3) != null ? Std.parseInt(regex.matched(3)) : 0;

			if (StringTools.startsWith(name, "gl_") || StringTools.startsWith(name, "ofl_"))
			{
				continue;
			}

			if (StringTools.startsWith(name, "openfl_"))
			{
				fieldAccess = APrivate;
			}
			else
			{
				fieldAccess = APublic;
			}

			if (StringTools.startsWith(type, "sampler"))
			{
				field = {
					name: name,
					meta: [],
					access: [fieldAccess],
					kind: FVar(macro :openfl.display.ShaderInput<openfl.display.BitmapData>),
					pos: pos
				};
			}
			else
			{
				var parameterType:openfl.display.ShaderParameterType = switch (type)
				{
					case "bool": arrLength > 0 ? BOOLV : BOOL;
					case "double", "float": arrLength > 0 ? FLOATV : FLOAT;
					case "int", "uint": arrLength > 0 ? INTV : INT;
					case "bvec2": arrLength > 0 ? BOOL2V : BOOL2;
					case "bvec3": arrLength > 0 ? BOOL3V : BOOL3;
					case "bvec4": arrLength > 0 ? BOOL4V : BOOL4;
					case "ivec2", "uvec2": arrLength > 0 ? INT2V : INT2;
					case "ivec3", "uvec3": arrLength > 0 ? INT3V : INT3;
					case "ivec4", "uvec4": arrLength > 0 ? INT4V : INT4;
					case "vec2", "dvec2": arrLength > 0 ? FLOAT2V : FLOAT2;
					case "vec3", "dvec3": arrLength > 0 ? FLOAT3V : FLOAT3;
					case "vec4", "dvec4": arrLength > 0 ? FLOAT4V : FLOAT4;
					case "mat2", "mat2x2": arrLength > 0 ? MATRIX2X2V : MATRIX2X2;
					case "mat2x3": arrLength > 0 ? MATRIX2X3V : MATRIX2X3;
					case "mat2x4": arrLength > 0 ? MATRIX2X4V : MATRIX2X4;
					case "mat3x2": arrLength > 0 ? MATRIX3X2V : MATRIX3X2;
					case "mat3", "mat3x3": arrLength > 0 ? MATRIX3X3V : MATRIX3X3;
					case "mat3x4": arrLength > 0 ? MATRIX3X4V : MATRIX3X4;
					case "mat4x2": arrLength > 0 ? MATRIX4X2V : MATRIX4X2;
					case "mat4x3": arrLength > 0 ? MATRIX4X3V : MATRIX4X3;
					case "mat4", "mat4x4": arrLength > 0 ? MATRIX4X4V : MATRIX4X4;
					default: null;
				}

				switch (parameterType)
				{
					case BOOL, BOOL2, BOOL3, BOOL4, BOOLV, BOOL2V, BOOL3V, BOOL4V:
						field = {
							name: name,
							meta: [{name: ":keep", pos: pos}],
							access: [fieldAccess],
							kind: FVar(macro :openfl.display.ShaderParameter<Bool>),
							pos: pos
						};

					case INT, INT2, INT3, INT4, INTV, INT2V, INT3V, INT4V:
						field = {
							name: name,
							meta: [{name: ":keep", pos: pos}],
							access: [fieldAccess],
							kind: FVar(macro :openfl.display.ShaderParameter<Int>),
							pos: pos
						};

					default:
						field = {
							name: name,
							meta: [{name: ":keep", pos: pos}],
							access: [fieldAccess],
							kind: FVar(macro :openfl.display.ShaderParameter<Float>),
							pos: pos
						};
				}
			}

			if (StringTools.startsWith(name, "openfl_"))
			{
				field.meta = [
					{name: ":keep", pos: pos},
					{name: ":dox", params: [macro hide], pos: pos},
					{name: ":noCompletion", pos: pos},
					{name: ":allow", params: [macro openfl.display._internal], pos: pos}
				];
			}
			else
			{
				field.meta = [{name: ":keep", pos: pos}];
			}

			fields.push(field);

			position = regex.matchedPos();
			lastMatch = position.pos + position.len;
		}
	}
	#end
}