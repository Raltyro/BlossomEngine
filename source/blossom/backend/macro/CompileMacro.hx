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
		Compiler.addMetadata('@:build($compileMacro.buildCameraFrontEnd())', 'flixel.system.frontEnds.CameraFrontEnd');
		#end
	}

	// use BLCamera instead of FlxCamera for resetting
	public static macro function buildCameraFrontEnd():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) if (f.name == 'reset') switch (f.kind) {
			case FFun(func):
				func.args = [{name: 'newCamera', type: macro :flixel.FlxCamera, opt: true}];
				func.expr = macro {
					flixel.FlxG.camera = null;
					while (list.length > 0) remove(list[0]);

					(flixel.FlxG.camera = add(newCamera == null ? new blossom.BLCamera() : newCamera)).ID = 0;
					flixel.FlxCamera._defaultCameras = defaults;
				};
			default:
		}
		return fields;
	}
}