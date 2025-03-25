package bl.util.macro;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import haxe.macro.ExprTools;

typedef ModuleEventVar = {
	name:String,
	type:ComplexType,
	expr:Expr
}

class BuildMacro {
	/*public static function init() {
		final buildMacro = 'bl.util.macro.BuildMacro';
	}*/

	// thanks thanks to Ne_Eo for helping me making me this macro
	public static macro function buildFunkinControlList():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		var controlType = Context.getType('bl.input.Controls.Control');
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

	// thanks to YoshiCrafter29 for this, modified
	public static macro function buildModuleEvents():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), localClass = Context.getLocalClass(), pos:Position = Context.currentPos();
		if (localClass == null || localClass.get() == null || localClass.get().name == "ModuleEvent") return fields;

		var funcExprs:Array<Expr>, publics:Array<ModuleEventVar> = [], privates:Array<ModuleEventVar> = [], callbackName:Expr = null;
		for (f in fields) if (f.access.contains(AStatic) && f.name == "classCallbackName") switch (f.kind) {
			case FVar(t, e): callbackName = e;
			default:
		}
		else {
			if (f.name == "recycle") return fields;
			else switch (f.kind) {
				case FFun(func): switch (func.expr.expr) {
					case EBlock(exprs): if (f.name == 'new') funcExprs = exprs;
					default:
				}
				case FVar(t, e):
					var hidden = !f.access.contains(APublic);
					if (!hidden && f.meta != null) for (m in f.meta) if (m.name == ":dox") {
						hidden = true;
						break;
					}

					(hidden ? privates : publics).push({name: f.name, type: t, expr: e});
				default:
			}
		}

		if (callbackName != null) {
			if (funcExprs == null) fields.push({name: 'new', access: [AOverride], pos: pos, kind: FFun({
				args: [], expr: {pos: pos, expr: EBlock(funcExprs = [macro super(), macro $i{"callbackName"} = $e{callbackName}])}})});
			else
				funcExprs.insert(0, macro $i{"callbackName"} = $e{callbackName});
		}

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

		fields.push({name: 'recycle', access: [APublic], pos: pos, kind: FFun({
			args: [for (v in publics) {name: v.name, type: v.type, value: v.expr, opt: false}],
			expr: {pos: pos, expr: EBlock(exprs)}
		})});

		return fields;
	}

	public static macro function buildCharacters():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), localClass = Context.getLocalClass(), pos:Position = Context.currentPos();
		if (localClass == null || localClass.get() == null || localClass.get().name == "Character") return fields;

		var initExprs:Array<Expr>, funcExprs:Array<Expr>, ID:String = null, name:Expr, iconData:Expr;
		for (f in fields) switch (f.kind) {
			case FVar(t, e): switch (f.name) {
				case 'classCharacterID': ID = cast ExprTools.getValue(e);
				case 'classCharacterName': name = e;
				case 'classCharacterIconData': iconData = e;
				default:
			}
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					if (f.name == '__init__') initExprs = exprs;
					else if (f.name == 'resetCharacter') funcExprs = exprs;
				default:
			}
			default:
		}

		if (ID == null) return fields;
		if (initExprs == null) fields.push({name: '__init__', access: [AStatic], pos: pos, kind: FFun({
			args: [], expr: {pos: pos, expr: EBlock(initExprs = [])}})});

		initExprs.insert(0, macro if (bl.play.component.Character.characterClasses == null) bl.play.component.Character.characterClasses = []);
		initExprs.insert(1, macro bl.play.component.Character.characterClasses.set($v{ID}, $p{localClass.toString().split('.')}));

		if (funcExprs == null) fields.push({name: 'resetCharacter', access: [AOverride], pos: pos, kind: FFun({
			args: [], expr: {pos: pos, expr: EBlock(funcExprs = [macro super.resetCharacter()])}})});

		funcExprs.insert(0, macro $i{"characterID"} = $v{ID});
		funcExprs.insert(0, if (name == null) macro $i{"characterName"} = $v{ID} else macro $i{"characterName"} = $e{name});
		if (iconData != null) funcExprs.insert(0, macro $i{"characterIconData"} = $e{iconData});
		return fields;
	}

	public static macro function buildStages():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), localClass = Context.getLocalClass(), pos:Position = Context.currentPos();
		if (localClass == null || localClass.get() == null || localClass.get().name == "Stage") return fields;

		var initExprs:Array<Expr>, funcExprs:Array<Expr>, ID:String = null, name:Expr;
		for (f in fields) switch (f.kind) {
			case FVar(t, e): switch (f.name) {
				case 'classStageID': ID = cast ExprTools.getValue(e);
				case 'classStageName': name = e;
				default:
			}
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					if (f.name == '__init__') initExprs = exprs;
					else if (f.name == 'resetStage') funcExprs = exprs;
				default:
			}
			default:
		}

		if (ID == null) return fields;
		if (initExprs == null) fields.push({name: '__init__', access: [AStatic], pos: pos, kind: FFun({
			args: [], expr: {pos: pos, expr: EBlock(initExprs = [])}})});

		initExprs.insert(0, macro if (bl.play.component.Stage.stageClasses == null) bl.play.component.Stage.stageClasses = []);
		initExprs.insert(1, macro bl.play.component.Stage.stageClasses.set($v{ID}, $p{localClass.toString().split('.')}));

		if (funcExprs == null) fields.push({name: 'resetStage', access: [AOverride], pos: pos, kind: FFun({
			args: [], expr: {pos: pos, expr: EBlock(funcExprs = [macro super.resetStage()])}})});

		funcExprs.insert(0, macro $i{"stageID"} = $v{ID});
		funcExprs.insert(0, if (name == null) macro $i{"stageName"} = $v{ID} else macro $i{"stageName"} = $e{name});
		return fields;
	}

	public static macro function buildPlayEvents():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), localClass = Context.getLocalClass(), pos:Position = Context.currentPos();
		if (localClass == null || localClass.get() == null || localClass.get().name == "PlayEvent") return fields;

		var initExprs:Array<Expr>, funcExprs:Array<Expr>, ID:String = null, name:Expr, icon:Expr;
		for (f in fields) switch (f.kind) {
			case FVar(t, e): switch (f.name) {
				case 'classEventID': ID = cast ExprTools.getValue(e);
				case 'classEventName': name = e;
				case 'classEventIcon': icon = e;
				default:
			}
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					if (f.name == '__init__') initExprs = exprs;
					else if (f.name == '_init') funcExprs = exprs;
				default:
			}
			default:
		}

		if (ID == null) return fields;
		if (initExprs == null) fields.push({name: '__init__', access: [AStatic], pos: pos, kind: FFun({
			args: [], expr: {pos: pos, expr: EBlock(initExprs = [])}})});

		initExprs.insert(0, macro if (bl.play.PlayEvent.eventClasses == null) bl.play.PlayEvent.eventClasses = []);
		initExprs.insert(1, macro bl.play.PlayEvent.eventClasses.set($v{ID}, $p{localClass.toString().split('.')}));

		if (funcExprs == null) fields.push({name: '_init', access: [AOverride], pos: pos, kind: FFun({
			args: [], expr: {pos: pos, expr: EBlock(funcExprs = [])}})});

		funcExprs.insert(1, macro $i{"eventID"} = $v{ID});
		funcExprs.insert(1, if (name == null) macro $i{"eventName"} = $v{ID} else macro $i{"eventName"} = $e{name});
		if (icon != null) funcExprs.insert(1, macro $i{"eventIcon"} = $e{icon});
		return fields;
	}

	public static macro function buildScripts():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), localClass = Context.getLocalClass(), pos:Position = Context.currentPos();
		if (localClass == null || localClass.get() == null || localClass.get().name == "PlayScript") return fields;

		var initExprs:Array<Expr>, funcExprs:Array<Expr>, ID:String = null, songID:String = null;
		for (f in fields) switch (f.kind) {
			case FVar(t, e): switch (f.name) {
				case 'classScriptID': ID = cast ExprTools.getValue(e);
				case 'classSongID': songID = cast ExprTools.getValue(e);
				default:
			}
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					if (f.name == '__init__') initExprs = exprs;
					else if (f.name == '_init') funcExprs = exprs;
				default:
			}
			default:
		}

		if (ID == null && songID == null) return fields;
		ID = ID ?? 'song-$songID';

		if (initExprs == null) fields.push({name: '__init__', access: [AStatic], pos: pos, kind: FFun({
			args: [], expr: {pos: pos, expr: EBlock(initExprs = [])}})});

		initExprs.insert(0, macro if (bl.play.PlayScript.scriptClasses == null) bl.play.PlayScript.scriptClasses = []);
		initExprs.insert(1, macro bl.play.PlayScript.scriptClasses.set($v{ID}, $p{localClass.toString().split('.')}));
		if (songID != null) {
			initExprs.push(macro if (bl.play.PlayScript.songScriptClasses == null) bl.play.PlayScript.songScriptClasses = []);
			initExprs.push(macro bl.play.PlayScript.songScriptClasses.set($v{songID}, $p{localClass.toString().split('.')}));
		}

		if (funcExprs == null)
			fields.push({name: '_init', access: [AOverride], pos: pos, kind: FFun({
				args: [], expr: {pos: pos, expr: EBlock(funcExprs = [macro $i{"scriptID"} = $v{ID}])}})});
		else
			funcExprs.insert(0, macro $i{"scriptID"} = $v{ID});
		return fields;
	}

	public static macro function buildPlayScript():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();

		return fields;
	}
}
#end
