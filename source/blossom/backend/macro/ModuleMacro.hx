package blossom.backend.macro;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;

typedef ModuleEventVar = {
	name:String,
	type:ComplexType,
	expr:Expr
}

final class ModuleMacro {
	public static function buildModule():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();

		fields.push({name: "_array", access: [], pos: pos, kind: FVar(macro :Array<Dynamic>, macro [])});
		for (i in 1...5) {
			final args = [{name: "func", type: macro :String}], exprs = [macro _array.resize($v{i})];
			for (j in 0...i) {
				args.push({name: "v" + j, type: macro :Dynamic});
				exprs.push(macro _array[$v{j}] = $i{"v" + j});
			}
			exprs.push(macro return call(func, _array));

			fields.push({name: "call" + i, access: [APublic, AInline], pos: pos, kind: FFun({
				args: args, ret: macro :Dynamic, expr: {pos: pos, expr: EBlock(exprs)}})});
		}

		return fields;
	}

	public static function buildModuleGroup():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();

		for (i in 1...5) {
			final args = [{name: "func", type: macro :String, opt: false}], params:Array<Expr> = [macro $i{"func"}], name = "call" + i;
			final modulecall = ["module", name];

			for (j in 0...i) {
				args.push({name: "v" + j, type: macro :Dynamic, opt: false});
				params.push(macro $i{"v" + j});
			}
			args.push({name: "results", type: macro :Array<Dynamic>, opt: true});

			fields.push({name: name, access: [APublic], pos: pos, kind: FFun({
				args: args, ret: macro :Array<Dynamic>, expr: macro {
					if (global != cast this) results = $p{["global", name]}($a{params.concat([macro $i{"results"}])});

					if (results == null) {
						for (module in members) if (module.active) $p{modulecall}($a{params});
					}
					else {
						var r:Dynamic;
						for (module in members) if (module.active) {
							if ((r = $p{modulecall}($a{params})) != null)
								results.push(r);
						}
					}
					return results;
				}
			})});
		}

		return fields;
	}

	public static function autoBuildModuleEVent():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), localClass = Context.getLocalClass(), pos:Position = Context.currentPos();

		var newExprs:Array<Expr>, publics:Array<ModuleEventVar> = [], privates:Array<ModuleEventVar> = [], callbackName:Expr = null, hasRecycle = false;
		for (f in fields) if (f.name == "recycle") hasRecycle = true;
		else switch (f.kind) {
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs): if (f.name == "new") newExprs = exprs;
				default:
			}
			case FVar(t, e): if (f.access.contains(AStatic)) {
				if (f.name == "classCallbackName") callbackName = e;
			}
			else {
				final isPublic = f.access.contains(APublic);
				(isPublic ? publics : privates).push({name: f.name, type: t, expr: e});
			}
			default:
		}

		if (callbackName != null) {
			if (newExprs == null)
				fields.push({name: "new", access: [AOverride], pos: pos, kind: FFun({args: [], expr: {pos: pos, expr: EBlock(newExprs = [macro super()])}})});

			newExprs.insert(0, macro if (callbackName == null) callbackName = $e{callbackName});
		}

		if (hasRecycle) return fields;

		final exprs:Array<Expr> = [macro recycleBase()];
		for (v in publics) exprs.push({
			pos: pos, expr: EBinop(OpAssign,
				{pos: pos, expr: EField({pos: pos, expr: EConst(CIdent("this"))}, v.name)},
				{pos: pos, expr: EConst(CIdent(v.name))}
			)
		});

		for (v in privates) exprs.push({
			pos: pos, expr: EBinop(OpAssign,
				{pos: pos, expr: EField({pos: pos, expr: EConst(CIdent("this"))}, v.name)},
				v.expr
			)
		});

		exprs.push(macro return this);

		fields.push({name: "recycle", access: [APublic], pos: pos, kind: FFun({
			args: [for (v in publics) {name: v.name, type: v.type, value: v.expr}],
			expr: {pos: pos, expr: EBlock(exprs)},
		})});

		return fields;
	}
}