package blossom.backend.macro;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import haxe.macro.ExprTools;

final class CompileMacro {
	public static function registerClasses(parent:String) {
		Compiler.include('$parent.characters');
		Compiler.include('$parent.events');
		Compiler.include('$parent.stages');
		Compiler.include('$parent.songs');
	}

	public static function init() {
		#if (!display)
		final compileMacro = 'blossom.backend.macro.CompileMacro';
		#end
	}
}