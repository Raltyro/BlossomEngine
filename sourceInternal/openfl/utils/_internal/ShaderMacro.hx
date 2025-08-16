package openfl.utils._internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;
using haxe.macro.Tools;
using haxe.macro.TypeTools;

@SuppressWarnings("checkstyle:FieldDocComment")
class ShaderMacro
{
	#if 0
	private static var __suppressWarning:Array<Class<Dynamic>> = [Expr];
	#end

	public static function build():Array<Field>
	{
		var fields = Context.getBuildFields();

		var glFragmentDontOverride = false;
		var glVertexDontOverride = false;
		var glFragmentHeader = "";
		var glFragmentBody = "";
		var glVertexHeader = "";
		var glVertexBody = "";

		var glVersion:String = null;

		var glFragmentExtensions = [];
		var glVertexExtensions = [];

		var glFragmentSource = null;
		var glVertexSource = null;

		for (field in fields)
		{
			for (meta in field.meta)
			{
				switch (meta.name)
				{
					case "glVersion", ":glVersion":
						glVersion = meta.params[0].getValue();

					case "glExtensions", ":glExtensions":
						glFragmentExtensions = glFragmentExtensions.concat(meta.params[0].getValue());
						glVertexExtensions = glVertexExtensions.concat(meta.params[0].getValue());

					case "glFragmentExtensions", ":glFragmentExtensions":
						glFragmentExtensions = glFragmentExtensions.concat(meta.params[0].getValue());

					case "glVertexExtensions", ":glVertexExtensions":
						glVertexExtensions = glVertexExtensions.concat(meta.params[0].getValue());

					case "glFragmentDontOverride", ":glFragmentDontOverride":
						glFragmentDontOverride = true;

					case "glVertexDontOverride", ":glVertexDontOverride":
						glVertexDontOverride = true;

					default:
				}
			}

			for (meta in field.meta)
			{
				switch (meta.name)
				{
					case "glFragmentSource", ":glFragmentSource":
						glFragmentSource = meta.params[0].getValue();

					case "glVertexSource", ":glVertexSource":
						glVertexSource = meta.params[0].getValue();

					case "glFragmentHeader", ":glFragmentHeader":
						glFragmentHeader += meta.params[0].getValue();

					case "glFragmentBody", ":glFragmentBody":
						glFragmentBody += meta.params[0].getValue();

					case "glVertexHeader", ":glVertexHeader":
						glVertexHeader += meta.params[0].getValue();

					case "glVertexBody", ":glVertexBody":
						glVertexBody += meta.params[0].getValue();

					default:
				}
			}
		}

		var pos = Context.currentPos();
		var localClass = Context.getLocalClass().get();
		var superClass = localClass.superClass != null ? localClass.superClass.t.get() : null;
		var parent = superClass;
		var parentFields;

		while (parent != null)
		{
			parentFields = [parent.constructor.get()].concat(parent.fields.get());

			for (field in parentFields)
			{
				var thisFragmentDontOverride = glFragmentDontOverride;
				var thisVertexDontOverride = glVertexDontOverride;

				for (meta in field.meta.get())
				{
					switch (meta.name)
					{
						case "glVersion", ":glVersion":
							if (glVersion == null) glVersion = meta.params[0].getValue();

						case "glExtensions", ":glExtensions":
							if (!glFragmentDontOverride) glFragmentExtensions = glFragmentExtensions.concat(meta.params[0].getValue());
							if (!glVertexDontOverride) glVertexExtensions = glVertexExtensions.concat(meta.params[0].getValue());

						case "glFragmentExtensions", ":glFragmentExtensions":
							if (!glFragmentDontOverride) glFragmentExtensions = glFragmentExtensions.concat(meta.params[0].getValue());

						case "glVertexExtensions", ":glVertexExtensions":
							if (!glVertexDontOverride) glVertexExtensions = glVertexExtensions.concat(meta.params[0].getValue());

						case "glFragmentDontOverride", ":glFragmentDontOverride":
							thisFragmentDontOverride = true;

						case "glVertexDontOverride", ":glVertexDontOverride":
							thisVertexDontOverride = true;

						default:
					}
				}

				for (meta in field.meta.get())
				{
					switch (meta.name)
					{
						case "glFragmentSource", ":glFragmentSource":
							if (glFragmentSource == null)
							{
								glFragmentSource = meta.params[0].getValue();
							}

						case "glVertexSource", ":glVertexSource":
							if (glVertexSource == null)
							{
								glVertexSource = meta.params[0].getValue();
							}

						case "glFragmentHeader", ":glFragmentHeader":
							if (!glFragmentDontOverride) {
								glFragmentHeader = meta.params[0].getValue() + "\n" + glFragmentHeader;
							}

						case "glFragmentBody", ":glFragmentBody":
							if (!glFragmentDontOverride) {
								glFragmentBody = meta.params[0].getValue() + "\n" + glFragmentBody;
							}

						case "glVertexHeader", ":glVertexHeader":
							if (!glVertexDontOverride) {
								glVertexHeader = meta.params[0].getValue() + "\n" + glVertexHeader;
							}

						case "glVertexBody", ":glVertexBody":
							if (!glVertexDontOverride) {
								glVertexBody = meta.params[0].getValue() + "\n" + glVertexBody;
							}

						default:
					}
				}

				glFragmentDontOverride = thisFragmentDontOverride;
				glVertexDontOverride = thisVertexDontOverride;
			}

			parent = parent.superClass != null ? parent.superClass.t.get() : null;
		}

		if (glVertexSource != null || glFragmentSource != null)
		{
			var shaderDataFields = new Array<Field>();
			var uniqueFields = [];

			processFields(glVertexSource, "attribute", shaderDataFields, pos);
			processFields(glVertexSource, "in", shaderDataFields, pos); // For higher GLSL versions
			processFields(glVertexSource, "uniform", shaderDataFields, pos);
			processFields(glFragmentSource, "uniform", shaderDataFields, pos);

			if (glVertexSource.indexOf('#pragma header') != -1) {
				processFields(glVertexHeader, "attribute", shaderDataFields, pos);
				processFields(glVertexHeader, "in", shaderDataFields, pos); // For higher GLSL versions
				processFields(glVertexHeader, "uniform", shaderDataFields, pos);
			}

			if (glVertexSource.indexOf('#pragma body') != -1) {
				processFields(glVertexBody, "attribute", shaderDataFields, pos);
				processFields(glVertexBody, "in", shaderDataFields, pos); // For higher GLSL versions
				processFields(glVertexBody, "uniform", shaderDataFields, pos);
			}

			if (glFragmentSource.indexOf('#pragma header') != -1) processFields(glFragmentHeader, "uniform", shaderDataFields, pos);
			if (glFragmentSource.indexOf('#pragma body') != -1) processFields(glFragmentBody, "uniform", shaderDataFields, pos);

			if (shaderDataFields.length > 0)
			{
				var fieldNames = new Map<String, Bool>();

				for (field in shaderDataFields)
				{
					parent = superClass;

					while (parent != null)
					{
						for (parentField in parent.fields.get())
						{
							if (parentField.name == field.name)
							{
								fieldNames.set(field.name, true);
							}
						}

						parent = parent.superClass != null ? parent.superClass.t.get() : null;
					}

					if (!fieldNames.exists(field.name))
					{
						uniqueFields.push(field);
					}

					fieldNames[field.name] = true;
				}
			}

			// #if !display
			for (field in fields)
			{
				switch (field.name)
				{
					case "new":
						var block = switch (field.kind)
						{
							case FFun(f):
								if (f.expr == null) null;

								switch (f.expr.expr)
								{
									case EBlock(e): e;
									default: null;
								}

							default: null;
						}

						block.unshift(Context.parse("__isGenerated = true", pos));

						if (glVertexSource != null)
						{
							block.unshift(macro if (__glVertexSource == null)
							{
								glVertexSource = $v{glVertexSource};
							});
						}

						if (glFragmentSource != null)
						{
							block.unshift(macro if (__glFragmentSource == null)
							{
								glFragmentSource = $v{glFragmentSource};
							});
						}

						if (glVertexHeader != null)
						{
							block.unshift(macro if (__glVertexHeaderRaw == null)
							{
								__glVertexHeaderRaw = $v{glVertexHeader};
							});
						}

						if (glFragmentHeader != null)
						{
							block.unshift(macro if (__glFragmentHeaderRaw == null)
							{
								__glFragmentHeaderRaw = $v{glFragmentHeader};
							});
						}

						if (glVertexBody != null)
						{
							block.unshift(macro if (__glVertexBodyRaw == null)
							{
								__glVertexBodyRaw = $v{glVertexBody};
							});
						}

						if (glFragmentBody != null)
						{
							block.unshift(macro if (__glFragmentBodyRaw == null)
							{
								__glFragmentBodyRaw = $v{glFragmentBody};
							});
						}

						if (glVertexExtensions != null)
						{
							block.unshift(macro if (__glVertexExtensions == null)
							{
								glVertexExtensions = $v{glVertexExtensions};
							});
						}

						if (glFragmentExtensions != null)
						{
							block.unshift(macro if (__glFragmentExtensions == null)
							{
								glFragmentExtensions = $v{glFragmentExtensions};
							});
						}

						block.unshift(macro if (__glVersion == null)
						{
							glVersion = $v{glVersion};
						});

						block.push(Context.parse("__initGL ()", pos));

					default:
				}
			}
			// #end

			fields = fields.concat(uniqueFields);
		}

		return fields;
	}

	private static function processFields(source:String, storageType:String, fields:Array<Field>, pos:Position):Void
	{
		if (source == null) return;

		var lastMatch = 0, position, regex, field:Field, name, type;

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

		var fieldAccess;

		while (regex.matchSub(source, lastMatch))
		{
			type = regex.matched(1);
			name = regex.matched(2);

			if (StringTools.startsWith(name, "gl_"))
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

				switch (parameterType)
				{
					case BOOL, BOOL2, BOOL3, BOOL4:
						field = {
							name: name,
							meta: [{name: ":keep", pos: pos}],
							access: [fieldAccess],
							kind: FVar(macro :openfl.display.ShaderParameter<Bool>),
							pos: pos
						};

					case INT, INT2, INT3, INT4:
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
}
#end