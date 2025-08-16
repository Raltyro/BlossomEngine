package blossom.backend.macro;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import haxe.macro.ExprTools;

final class BuildMacro {
	public static macro function buildFunkinControlList():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		var controlType = Context.getType('blossom.input.Controls.Control');
		var values = [];

		switch (haxe.macro.TypeTools.follow(controlType)) {
			case TAbstract(_.get() => ab, _):
				for (f in ab.impl.get().statics.get()) {
					if (f.name.toUpperCase() != f.name) continue;

					switch (f.kind) {
						case FVar(AccInline, _):
							switch (f.expr().expr) {
								case TCast(Context.getTypedExpr(_) => expr, _):
									var value = ExprTools.getValue(expr);
									var getter:Function = {
										args: [], ret: macro :Bool,
										expr: macro return $i{"manager"}.controls.get($v{value})?.checkFiltered($i{"status"})
									};
									values.push({idx: f.name, value: value});
									fields.push({name: "get_" + f.name, access: [APrivate, AInline], pos: pos, kind: FFun(getter)});
									fields.push({name: f.name, access: [APublic], pos: pos, kind: FProp("get", "null", getter.ret)});
								default:
							}
						default:
					}
				}
			default:
		}

		fields.push({
			name: "enums", access: [APublic, AStatic], pos: pos,
			kind: FVar(null, macro $a{values.map(function(v) return macro $v{v.idx} => $v{v.value})})
		});
		return fields;
	}
}