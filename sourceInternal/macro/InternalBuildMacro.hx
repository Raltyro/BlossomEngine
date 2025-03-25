package macro;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import haxe.macro.ExprTools;

using StringTools;

class InternalBuildMacro {
	public static function init() {
		#if (!display)
		final buildMacro = 'macro.InternalBuildMacro';
		Compiler.addMetadata('@:build($buildMacro.buildNativeCFFI())', 'lime._internal.backend.native.NativeCFFI');
		Compiler.addMetadata('@:build($buildMacro.buildNativeHTTPRequest())', 'lime._internal.backend.native.NativeHTTPRequest');
		if (Context.defined('lime_cffi') && Context.defined('lime_openal')) Compiler.addMetadata('@:build($buildMacro.buildAL())', 'lime.media.openal.AL');
		if (Context.defined('lime_cairo')) Compiler.addMetadata('@:build($buildMacro.buildCairoGraphics())', 'openfl.display._internal.CairoGraphics');
		Compiler.addMetadata('@:build($buildMacro.buildBitmapData())', 'openfl.display.BitmapData');
		if (Context.defined('js') && Context.defined('html5')) Compiler.addMetadata('@:build($buildMacro.buildCanvasRenderer())', 'openfl.display.CanvasRenderer');
		if (Context.defined('lime_cairo')) Compiler.addMetadata('@:build($buildMacro.buildCairoRenderer())', 'openfl.display.CairoRenderer');
		Compiler.addMetadata('@:build($buildMacro.buildOpenGLRenderer())', 'openfl.display.OpenGLRenderer');
		Compiler.addMetadata('@:build($buildMacro.buildContext3D())', 'openfl.display3D.Context3D');
		Compiler.addMetadata('@:build($buildMacro.buildFLEvent())', 'openfl.events.Event');
		Compiler.addMetadata('@:build($buildMacro.buildFlxTypedGroup())', 'flixel.group.FlxGroup.FlxTypedGroup');
		Compiler.addMetadata('@:build($buildMacro.buildFlxMatrix())', 'flixel.math.FlxMatrix');
		Compiler.addMetadata('@:build($buildMacro.buildFlxSprite())', 'flixel.FlxSprite');
		Compiler.addMetadata('@:build($buildMacro.buildFlxCamera())', 'flixel.FlxCamera');
		Compiler.addMetadata('@:build($buildMacro.buildFlxObject())', 'flixel.FlxObject');
		Compiler.addMetadata('@:build($buildMacro.buildFlxGame())', 'flixel.FlxGame');
		Compiler.addMetadata('@:build($buildMacro.buildFlxG())', 'flixel.FlxG');
		#end
	}

	// audio
	public static macro function buildNativeCFFI():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		if (!Context.defined('lime_cffi') || !Context.defined('lime_openal')) return fields;

		final fieldNames:Array<String> = [], pos:Position = Context.currentPos();
		for (f in fields) fieldNames.push(f.name);

		function addField(name:String, args:Array<String>, signature:String) {
			var meta:Metadata = [], kind = null;

			if (Context.defined('cpp') && !Context.defined('cppia')) {
				if (Context.defined('disable_cffi') || Context.definedValue('haxe_ver') < "3.4.0") {
					kind = FFun({ret: macro :Void, args: [for (arg in args) {name: arg, type: macro :lime.system.CFFIPointer}], expr: macro {}});
					meta.push({name: ':cffi', pos: pos});
				}
				else {
					kind = FVar(macro :cpp.Callable<cpp.Object->cpp.Void>, macro new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", $v{name}, $v{signature}, false)));
				}
			}
			else if (Context.defined('neko') || Context.defined('cppia')) {
				kind = FVar(macro :Dynamic, macro lime.system.CFFI.load("lime", $v{name}, $v{args.length}));
			}
			else if (Context.defined('hl')) {
				kind = FFun({ret: macro :Void, args: [for (arg in args) {name: arg, type: macro :lime.system.CFFIPointer}], expr: macro {}});
				meta.push({pos: pos, name: ':hlNative', params: [macro "lime", macro $v{'hl' + name.substr(4)}]});
			}

			if (kind != null) fields.push({name: name, access: [APrivate, AStatic], pos: pos, kind: kind, meta: meta});
		}

		if (!fieldNames.contains('lime_al_delete_effect')) addField('lime_al_delete_effect', ['effect'], 'ov');
		if (!fieldNames.contains('lime_al_delete_filter')) addField('lime_al_delete_filter', ['filter'], 'ov');
		if (!fieldNames.contains('lime_al_delete_auxiliary_effect_slot')) addField('lime_al_delete_auxiliary_effect_slot', ['slot'], 'ov');
		return fields;
	}

	public static macro function buildAL():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();

		final fieldNames:Array<String> = [], pos:Position = Context.currentPos();
		for (f in fields) fieldNames.push(f.name);

		if (!fieldNames.contains('deleteEffect'))
			fields.push({name: 'deleteEffect', access: [APublic, AStatic], pos: pos, kind: FFun({
				ret: macro :Void, args: [{name: 'effect', type: macro :lime.media.openal.ALEffect}],
				expr: macro lime._internal.backend.native.NativeCFFI.lime_al_delete_effect(effect)
			})});

		if (!fieldNames.contains('deleteFilter'))
			fields.push({name: 'deleteFilter', access: [APublic, AStatic], pos: pos, kind: FFun({
				ret: macro :Void, args: [{name: 'filter', type: macro :lime.media.openal.ALFilter}],
				expr: macro lime._internal.backend.native.NativeCFFI.lime_al_delete_filter(filter)
			})});

		if (!fieldNames.contains('deleteAux'))
			fields.push({name: 'deleteAux', access: [APublic, AStatic], pos: pos, kind: FFun({
				ret: macro :Void, args: [{name: 'aux', type: macro :lime.media.openal.ALAuxiliaryEffectSlot}],
				expr: macro lime._internal.backend.native.NativeCFFI.lime_al_delete_auxiliary_effect_slot(aux)
			})});

		return fields;
	}

	// fix maxThreads locked to 1
	public static macro function buildNativeHTTPRequest():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) if (f.name == 'loadData') switch (f.kind) {
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					exprs.insert(0, macro if ($i{"localThreadPool"} != null) $i{"localThreadPool"}.maxThreads = 2);
				default:
			}
			default:
		}
		return fields;
	}

	// fix hardware cairo
	public static macro function buildCairoGraphics():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) if (f.name == 'createImagePattern') switch (f.kind) {
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					exprs.insert(0, macro if ($p{["bitmapFill", "__surface"]} == null) return null);
				default:
			}
			default:
		}
		return fields;
	}

	// fix cairo surface
	public static macro function buildBitmapData():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) if (f.name == 'getSurface') switch (f.kind) {
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					exprs.insert(0, macro if ($i{"__surface"} != null) return $i{"__surface"});
				default:
			}
			default:
		}
		return fields;
	}

	// add more blendmodes
	public static macro function buildCanvasRenderer():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		for (f in fields) switch (f.kind) {
			case FFun(func): if (f.name == '__setBlendModeContext') {
				func.expr = macro {
					switch (value) {
						case ADD: context.globalCompositeOperation = "lighter";
						case MULTIPLY: context.globalCompositeOperation = "multiply";
						case SCREEN: context.globalCompositeOperation = "screen";
						// case SUBTRACT:
						// case INVERT:
						case EXCLUDE: context.globalCompositeOperation = "exclusion";
						case DARKEN: context.globalCompositeOperation = "darken";
						case DIFFERENCE: context.globalCompositeOperation = "difference";
						case HARDLIGHT: context.globalCompositeOperation = "hard-light";
						case LIGHTEN: context.globalCompositeOperation = "lighten";
						case OVERLAY: context.globalCompositeOperation = "overlay";
						case SOFTLIGHT: context.globalCompositeOperation = "soft-light";
						case BURN: context.globalCompositeOperation = "color-burn";
						case DODGE: context.globalCompositeOperation = "color-dodge";
						default: context.globalCompositeOperation = "source-over";
					}
				}
			}
			default:
		}
		return fields;
	}

	// add more blendmodes
	public static macro function buildCairoRenderer():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		for (f in fields) switch (f.kind) {
			case FFun(func): if (f.name == '__setBlendModeCairo') {
				func.expr = macro {
					switch (value) {
						case ADD: cairo.setOperator(lime.graphics.cairo.CairoOperator.ADD);
						case MULTIPLY: cairo.setOperator(lime.graphics.cairo.CairoOperator.MULTIPLY);
						case SCREEN: cairo.setOperator(lime.graphics.cairo.CairoOperator.SCREEN);
						// case SUBTRACT:
						// case INVERT:
						case EXCLUDE: cairo.setOperator(lime.graphics.cairo.CairoOperator.EXCLUSION);
						case DARKEN: cairo.setOperator(lime.graphics.cairo.CairoOperator.DARKEN);
						case DIFFERENCE: cairo.setOperator(lime.graphics.cairo.CairoOperator.DIFFERENCE);
						case HARDLIGHT: cairo.setOperator(lime.graphics.cairo.CairoOperator.HARD_LIGHT);
						case LIGHTEN: cairo.setOperator(lime.graphics.cairo.CairoOperator.LIGHTEN);
						case OVERLAY: cairo.setOperator(lime.graphics.cairo.CairoOperator.OVERLAY);
						case SOFTLIGHT: cairo.setOperator(lime.graphics.cairo.CairoOperator.SOFT_LIGHT);
						case BURN: cairo.setOperator(lime.graphics.cairo.CairoOperator.COLOR_BURN);
						case DODGE: cairo.setOperator(lime.graphics.cairo.CairoOperator.COLOR_DODGE);
						default: cairo.setOperator(lime.graphics.cairo.CairoOperator.OVER);
					}
				}
			}
			default:
		}
		return fields;
	}

	// fix innacruate EPSILON on pixel snapping auto something idfk
	// might aswell just make it so it doesnt use Matrix _pool
	// also make it so it supports more blendmodes
	// and dont force sets depth test to false
	public static macro function buildOpenGLRenderer():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		fields.push({name: 'hasKHRBlendAdvancedExt', access: [AStatic, APublic], pos: pos, kind: FVar(macro :Null<Bool>, macro null)});
		for (f in fields) switch (f.kind) {
			case FFun(func): if (f.name == '__getMatrix') {
				func.expr = macro {
					__matrix[0] = transform.a * __worldTransform.a + transform.b * __worldTransform.c;
					__matrix[1] = transform.a * __worldTransform.b + transform.b * __worldTransform.d;
					__matrix[2] = 0;
					__matrix[3] = 0;
					__matrix[4] = transform.c * __worldTransform.a + transform.d * __worldTransform.c;
					__matrix[5] = transform.c * __worldTransform.b + transform.d * __worldTransform.d;
					__matrix[6] = 0;
					__matrix[7] = 0;
					__matrix[8] = 0;
					__matrix[9] = 0;
					__matrix[10] = 1;
					__matrix[11] = 0;
					__matrix[12] = transform.tx * __worldTransform.a + transform.ty * __worldTransform.c + __worldTransform.tx;
					__matrix[13] = transform.tx * __worldTransform.b + transform.ty * __worldTransform.d + __worldTransform.ty;
					__matrix[14] = 0;
					__matrix[15] = 1;

					if (pixelSnapping == openfl.display.PixelSnapping.ALWAYS ||
						(pixelSnapping == openfl.display.PixelSnapping.AUTO
							&& __matrix[1] == 0 && __matrix[4] == 0
							&& __matrix[0] < 1.0000001 && __matrix[0] > 0.9999999
						)	&& __matrix[5] < 1.0000001 && __matrix[5] > 0.9999999
					) {
						__matrix[12] = Math.round(__matrix[12]);
						__matrix[13] = Math.round(__matrix[13]);
					}

					__matrix.append(__flipped ? __projectionFlipped : __projection);

					for (i in 0...16) __values[i] = __matrix[i];
					return __values;
				}
			}
			else if (f.name == '__setBlendMode') {
				func.expr = macro {
					if (__overrideBlendMode != null) value = __overrideBlendMode;
					if (__blendMode == value) return;

					if (hasKHRBlendAdvancedExt) {
						switch (__blendMode = value) {
							case ADD: __context3D.setBlendFactors(ONE, ONE);
							case MULTIPLY: __context3D.setBlendFactors(DESTINATION_COLOR, ONE_MINUS_SOURCE_ALPHA);
							case SCREEN: __context3D.setBlendFactors(ONE, ONE_MINUS_SOURCE_COLOR);
							case SUBTRACT:
								__context3D.setBlendFactors(ONE, ONE);
								__context3D.__setGLBlendEquation(__gl.FUNC_REVERSE_SUBTRACT);
								gl.blendEquationSeparate(__gl.FUNC_REVERSE_SUBTRACT, __gl.FUNC_ADD);
							case INVERT: __context3D.setBlendFactorsSeparate(ONE_MINUS_DESTINATION_COLOR, ONE_MINUS_SOURCE_ALPHA, ZERO, ONE);
							case EXCLUDE: __context3D.setBlendFactorsSeparate(ONE_MINUS_DESTINATION_COLOR, ONE_MINUS_SOURCE_COLOR, ZERO, ONE);
							case DARKEN: __context3D.__setGLBlendEquation(0x9297); // DARKEN_KHR
							case DIFFERENCE: __context3D.__setGLBlendEquation(0x929E); // DIFFERENCE_KHR
							case HARDLIGHT: __context3D.__setGLBlendEquation(0x929B); // HARDLIGHT_KHR
							case LIGHTEN: __context3D.__setGLBlendEquation(0x9298); // LIGHTEN_KHR
							case OVERLAY: __context3D.__setGLBlendEquation(0x9296); // OVERLAY_KHR
							case SOFTLIGHT: __context3D.__setGLBlendEquation(0x929C); // SOFTLIGHT_KHR
							case BURN: __context3D.__setGLBlendEquation(0x9299); // COLORBURN_KHR
							case DODGE: __context3D.__setGLBlendEquation(0x929A); // COLORDODGE_KHR
							default: __context3D.setBlendFactors(ONE, ONE_MINUS_SOURCE_ALPHA);
						}
					}
					else {
						switch (__blendMode = value) {
							case ADD: __context3D.setBlendFactors(ONE, ONE);
							case MULTIPLY: __context3D.setBlendFactors(DESTINATION_COLOR, ONE_MINUS_SOURCE_ALPHA);
							case SCREEN: __context3D.setBlendFactors(ONE, ONE_MINUS_SOURCE_COLOR);
							case SUBTRACT:
								__context3D.setBlendFactors(ONE, ONE);
								__context3D.__setGLBlendEquation(__gl.FUNC_REVERSE_SUBTRACT);
								gl.blendEquationSeparate(__gl.FUNC_REVERSE_SUBTRACT, __gl.FUNC_ADD);
							case INVERT: __context3D.setBlendFactorsSeparate(ONE_MINUS_DESTINATION_COLOR, ONE_MINUS_SOURCE_ALPHA, ZERO, ONE);
							case EXCLUDE: __context3D.setBlendFactorsSeparate(ONE_MINUS_DESTINATION_COLOR, ONE_MINUS_SOURCE_COLOR, ZERO, ONE);
							case DARKEN: // TRANSPARENCY ISSUES
								__context3D.setBlendFactors(ONE, ONE_MINUS_SOURCE_ALPHA);
								__context3D.__setGLBlendEquation(lime.graphics.opengl.GL.MIN);
							case LIGHTEN:
								__context3D.setBlendFactors(ONE, ONE);
								__context3D.__setGLBlendEquation(lime.graphics.opengl.GL.MAX);
							default: __context3D.setBlendFactors(ONE, ONE_MINUS_SOURCE_ALPHA);
						}
					}
				}
			}
			else if (f.name == 'new') {
				switch (func.expr.expr) {
					case EBlock(exprs):
						exprs.push(macro
							if (hasKHRBlendAdvancedExt == null) {
								hasKHRBlendAdvancedExt = gl.getSupportedExtensions().contains("KHR_blend_equation_advanced_coherent");
								gl.enable(0x9285); // BLEND_ADVANCED_COHERENT_KHR
							}
						);
					default:
				}
			}
			else if (f.name == '__render') {
				switch (func.expr.expr) {
					case EBlock(exprs):
						for (i => code in exprs) switch (code.expr) {
							case ECall(expr, _): switch (expr.expr) {
								case EField(expr, field, _):
									if (field == 'setDepthTest') {
										exprs[i] = macro if (object.__drawableType == openfl.display._internal.IBitmapDrawableType.STAGE) ${code};
										break;
									}
								default:
							}
							default:
						}
					default:
				}
			}
			default:
		}
		return fields;
	}

	// additional helper functions
	public static macro function buildContext3D():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		
		return fields;
	}

	// for Ralty's FlxSound Modification
	public static macro function buildFLEvent():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		fields.push({
			name: 'SOUND_LOOP', access: [APublic, AStatic, AInline], pos: Context.currentPos(),
			kind: FVar(macro :openfl.events.EventType<openfl.events.Event>, macro $v{'soundLoop'})
		});
		return fields;
	}

	// replace splice with swapAndPop instead in remove
	public static macro function buildFlxTypedGroup():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		for (f in fields) switch (f.kind) {
			case FFun(func): if (f.name == 'remove') {
				func.expr = macro {
					if (members == null) return null;

					final index = members.indexOf(basic);
					if (index < 0) return null;

					if (splice) {
						flixel.util.FlxArrayUtil.swapAndPop(members, index);
						length--;
					}
					else
						members[index] = null;

					onMemberRemove(basic);
				}
			}
			default:
		}

		return fields;
	}

	// for to add new function skewing
	public static macro function buildFlxMatrix():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		return fields.concat([
			{name: 'skew', access: [APublic, AInline], pos: pos, kind: FFun({
				args: [{name: 'xtheta', type: macro :Float}, {name: 'ytheta', type: macro :Float}], ret: macro :flixel.math.FlxMatrix,
				expr: macro {
					final b1 = Math.tan(xtheta), c1 = Math.tan(ytheta);
					b = a * b1 + b;
					c = c + d * c1;

					final y1 = ty;
					ty = tx * b1 + y1;
					tx = tx + y1 * c1;

					return this;
				}
			})},
			{name: 'skewByTrigs', access: [APublic, AInline], pos: pos, kind: FFun({
				args: [{name: 'b1', type: macro :Float}, {name: 'c1', type: macro :Float}], ret: macro :flixel.math.FlxMatrix,
				expr: macro {
					b = a * b1 + b;
					c = c + d * c1;

					final y1 = ty;
					ty = tx * b1 + y1;
					tx = tx + y1 * c1;

					return this;
				}
			})}
		]);
	}

	// for BLSprite & Character stageFlips
	public static macro function buildFlxSprite():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) switch (f.name) {
			case 'centerOrigin': f.access.remove(AInline);
			case 'checkFlipX': f.access.remove(AInline);
			case 'checkFlipY': f.access.remove(AInline);
			default:
		}
		return fields;
	}

	// fix resolution
	/*
	inline static function attachBitmapCacheFix(idx:Int, exprs:Array<Expr>, ?prefix:Array<String>) {
		if (prefix == null) prefix = [];
		exprs.insert(idx, macro @:privateAccess $p{prefix.concat(['__cacheBitmapData'])} =
			$p{prefix.concat(['__cacheBitmapData2'])} =
			$p{prefix.concat(['__cacheBitmapData3'])} = null);
		exprs.insert(idx, macro @:privateAccess if ($p{prefix.concat(['__cacheBitmapData'])} != null) $p{prefix.concat(['__cacheBitmapData'])}.dispose());
		exprs.insert(idx, macro @:privateAccess if ($p{prefix.concat(['__cacheBitmapData2'])} != null) $p{prefix.concat(['__cacheBitmapData2'])}.dispose());
		exprs.insert(idx, macro @:privateAccess if ($p{prefix.concat(['__cacheBitmapData3'])} != null) $p{prefix.concat(['__cacheBitmapData3'])}.dispose());
	}
	*/

	public static macro function buildFlxGame():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		final f:Function = {
			args: [{name: 'r', type: macro :openfl.geom.Rectangle}, {name: 'm', type: macro :openfl.geom.Matrix}],
			expr: macro r.setTo(0, 0, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y)
		};

		/*for (f in fields) if (f.name == 'resizeGame') switch (f.kind) {
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs): //attachBitmapCacheFix(0, exprs);
					exprs.push(macro graphics.clear());
					exprs.push(macro graphics.beginFill(0, 1));
					//exprs.push(macro graphics.drawRect(-1, -1, FlxG.scaleMode.gameSize.x + 2, FlxG.scaleMode.gameSize.y + 2));
					exprs.push(macro graphics.drawRect(0, 0, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y));
					exprs.push(macro graphics.endFill());
				default:
			}
			default:
		}*/

		for (name in ['__getBounds', '__getFilterBounds', '__getRenderBounds'])
			fields.push({name: name, access: [AOverride], pos: pos, kind: FFun(f)});

		return fields;
	}

	// for PlayCamera
	public static macro function buildFlxCamera():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) switch (f.name) {
			case 'calcMarginX' | 'calcMarginY' | 'updateBlitMatrix': f.access.remove(AInline);
			case 'set_followLerp': fields.remove(f);
			case 'followLerp': f.kind = FVar(macro :Float, macro 1);
			/*case 'onResize': switch (f.kind) {
				case FFun(func): switch (func.expr.expr) {
					case EBlock(exprs): attachBitmapCacheFix(0, exprs, ['flashSprite']);
					default:
				}
				default:
			}*/
		}
		for (f in fields) switch (f.kind) {
			case FFun(func): switch (f.name) {
				case 'startQuadBatch':
					func.args.push({name: 'depthCompareMode', type: macro :openfl.display3D.Context3DCompareMode, opt: true});
					func.expr = macro {
						if (_currentDrawItem != null
							&& _currentDrawItem.type == flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType.TILES
							&& _headTiles.graphics == graphic
							&& _headTiles.colored == colored
							&& _headTiles.hasColorOffsets == hasColorOffsets
							&& _headTiles.blend == blend
							&& _headTiles.antialiasing == smooth
							&& _headTiles.shader == shader
							&& _headTiles.depthCompareMode == depthCompareMode
						)
							return _headTiles;

						final item = if (_storageTilesHead != null) {
							final head = _storageTilesHead;
							_storageTilesHead = _storageTilesHead.nextTyped;
							head.reset();
							head;
						}
						else
							new flixel.graphics.tile.FlxDrawQuadsItem();

						item.graphics = graphic;
						item.antialiasing = smooth;
						item.colored = colored;
						item.hasColorOffsets = hasColorOffsets;
						item.blend = blend;
						item.shader = shader;
						item.depthCompareMode = depthCompareMode;

						item.nextTyped = _headTiles;
						_headTiles = item;

						if (_headOfDrawStack == null) _headOfDrawStack = item;
						if (_currentDrawItem != null) _currentDrawItem.next = item;
						_currentDrawItem = item;

						return item;
					}
				case 'startTrianglesBatch':
					func.args.push({name: 'depthCompareMode', type: macro :openfl.display3D.Context3DCompareMode, opt: true});
					func.args.push({name: 'culling', type: macro :openfl.display.TriangleCulling, opt: true});
					func.expr = macro {
						if (_currentDrawItem != null
							&& _currentDrawItem.type == flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType.TRIANGLES
							&& _headTriangles.graphics == graphic
							&& _headTriangles.antialiasing == smoothing
							&& _headTriangles.colored == isColored
							&& _headTriangles.blend == blend
							&& _headTriangles.hasColorOffsets == hasColorOffsets
							&& _headTriangles.shader == shader
							&& _headTriangles.culling == culling
							&& _headTriangles.depthCompareMode == depthCompareMode
						)
							return _headTriangles;

						return getNewDrawTrianglesItem(graphic, smoothing, isColored, blend, hasColorOffsets, shader, depthCompareMode, culling);
					}
				case 'getNewDrawTrianglesItem':
					func.args.push({name: 'depthCompareMode', type: macro :openfl.display3D.Context3DCompareMode, opt: true});
					func.args.push({name: 'culling', type: macro :openfl.display.TriangleCulling, opt: true});
					func.expr = macro {
						final item = if (_storageTrianglesHead != null) {
							final head = _storageTrianglesHead;
							_storageTrianglesHead = _storageTrianglesHead.nextTyped;
							head.reset();
							head;
						}
						else
							new flixel.graphics.tile.FlxDrawTrianglesItem();

						item.graphics = graphic;
						item.antialiasing = smoothing;
						item.colored = isColored;
						item.hasColorOffsets = hasColorOffsets;
						item.blend = blend;
						item.shader = shader;
						item.culling = culling;
						item.depthCompareMode = depthCompareMode;

						item.nextTyped = _headTriangles;
						_headTriangles = item;

						if (_headOfDrawStack == null) _headOfDrawStack = item;
						if (_currentDrawItem != null) _currentDrawItem.next = item;
						_currentDrawItem = item;

						return item;
					}
			}
			default:
		}
		return fields;
	}

	// for Object3D
	public static macro function buildFlxObject():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) switch (f.name) {
			case 'initMotionVars': f.access.remove(AInline);
			case 'screenCenter': f.access.remove(AInline);
			default:
		}
		return fields;
	}

	// for forceSwitchState, forceResetState
	public static macro function buildFlxG():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		return fields.concat([
			{
				name: 'forceSwitchState', access: [APublic, AStatic, AInline], pos: pos,
				kind: FFun({
					args: [{name: 'immediate', type: macro :Bool, opt: true}, {name: 'nextState', type: macro :flixel.util.typeLimit.NextState}],
					expr: macro {
						$i{"game"}._nextState = $i{"nextState"};
						if ($i{"immediate"}) $i{"game"}.switchState();
					}
				})
			},
			{
				name: 'forceResetState', access: [APublic, AStatic, AInline], pos: pos,
				kind: FFun({
					args: [{name: 'immediate', type: macro :Bool, opt: true}],
					expr: macro {
						$i{"game"}._nextState = $i{"state"}._constructor;
						if ($i{"immediate"}) $i{"game"}.switchState();
					}
				})
			}
		]);
	}
}
#end