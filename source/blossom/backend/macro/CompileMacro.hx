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
		Compiler.addMetadata('@:build($compileMacro.buildFlxCamera())', 'flixel.FlxCamera');
		Compiler.addMetadata('@:build($compileMacro.buildFlxObject())', 'flixel.FlxObject');
		Compiler.addMetadata('@:build($compileMacro.buildFlxSprite())', 'flixel.FlxSprite');
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

	// for BLCamera
	public static macro function buildFlxCamera():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) switch (f.name) {
			case "calcMarginX" | "calcMarginY" | "updateBlitMatrix": f.access.remove(AInline);
		}
		return fields;
	}

	// for Object3D
	public static macro function buildFlxObject():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) switch (f.name) {
			case "initMotionVars": f.access.remove(AInline);
			case "screenCenter": f.access.remove(AInline);
			default:
		}
		return fields;
	}

	// for BLSprite & Character stageFlips
	public static macro function buildFlxSprite():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) switch (f.name) {
			case "centerOrigin": f.access.remove(AInline);
			case "checkFlipX": f.access.remove(AInline);
			case "checkFlipY": f.access.remove(AInline);
			default:
		}
		return fields;
	}
}