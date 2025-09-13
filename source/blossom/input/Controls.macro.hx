package blossom.input;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;

class FunkinControlList {
	#if macro
	public static function build():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();

		var enumsField:Field = null;
		for (field in fields)
			if (field.name == "enums") {
				enumsField = field;
				break;
			}

		if (enumsField == null)
			fields.push(enumsField = {name: "enums", access: [APublic, AStatic], pos: pos, kind: FVar(null)});

		var controlType = Context.getType('blossom.input.Controls.Control');
		var values = [];

		switch (controlType.follow()) {
			case TAbstract(_.get() => ab, _):
				for (f in ab.impl.get().statics.get()) if (f.name.toUpperCase() == f.name) switch (f.kind) {
					case FVar(AccInline, _):
						switch (f.expr().expr) {
							case TCast(Context.getTypedExpr(_) => expr, _):
								final value = expr.getValue();
								values.push({idx: f.name, value: value});
								fields.push({name: f.name, access: [APublic], pos: pos, kind: FProp("get", "never", macro :Bool)});
								fields.push({name: "get_" + f.name, access: [APrivate, AInline], pos: pos, kind: FFun({
									args: [], ret: macro :Bool,
									expr: macro return manager.controls.get($v{value})?.checkFiltered(status)
								})});
							default:
						}
					default:
				}
			default:
		}

		enumsField.kind = FVar(null, macro $a{values.map(function(v) return macro $v{v.idx} => $v{v.value})});
		return fields;
	}
	#end
}