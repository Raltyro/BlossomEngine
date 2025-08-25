package macro;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import haxe.macro.ExprTools;

using StringTools;

final class InternalCompileMacro {
	public static function init() {
		#if (!display)
		final compileMacro = "macro.InternalCompileMacro";
		Compiler.addMetadata('@:build($compileMacro.buildNativeCFFI())', 'lime._internal.backend.native.NativeCFFI');
		Compiler.addMetadata('@:build($compileMacro.buildNativeHTTPRequest())', 'lime._internal.backend.native.NativeHTTPRequest');
		if (Context.defined('lime_cffi') && Context.defined('lime_openal')) Compiler.addMetadata('@:build($compileMacro.buildAL())', 'lime.media.openal.AL');
		if (Context.defined('lime_cairo')) Compiler.addMetadata('@:build($compileMacro.buildCairoGraphics())', 'openfl.display._internal.CairoGraphics');
		Compiler.addMetadata('@:build($compileMacro.buildBitmapData())', 'openfl.display.BitmapData');
		if (Context.defined('js') && Context.defined('html5')) Compiler.addMetadata('@:build($compileMacro.buildCanvasRenderer())', 'openfl.display.CanvasRenderer');
		if (Context.defined('lime_cairo')) Compiler.addMetadata('@:build($compileMacro.buildCairoRenderer())', 'openfl.display.CairoRenderer');
		Compiler.addMetadata('@:build($compileMacro.buildOpenGLRenderer())', 'openfl.display.OpenGLRenderer');
		Compiler.addMetadata('@:build($compileMacro.buildDisplayObject())', 'openfl.display.DisplayObject');
		Compiler.addMetadata('@:build($compileMacro.buildFlxAnimation())', 'flixel.animation.FlxAnimation');
		Compiler.addMetadata('@:build($compileMacro.buildFlxTypedGroup())', 'flixel.group.FlxGroup.FlxTypedGroup');
		Compiler.addMetadata('@:build($compileMacro.buildFlxSprite())', 'flixel.FlxSprite');
		if (Context.defined('flixel_animate')) Compiler.addMetadata('@:build($compileMacro.buildFlxAnimate())', 'animate.FlxAnimate');
		Compiler.addMetadata('@:build($compileMacro.buildFlxState())', 'flixel.FlxState');
		Compiler.addMetadata('@:build($compileMacro.buildFlxCamera())', 'flixel.FlxCamera');
		Compiler.addMetadata('@:build($compileMacro.buildFlxGame())', 'flixel.FlxGame');
		Compiler.addMetadata('@:build($compileMacro.buildVideo())', 'hxvlc.openfl.Video');
		#end
	}

	// audio
	public static macro function buildNativeCFFI():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		if (!Context.defined("lime_cffi") || !Context.defined("lime_openal")) return fields;

		final fieldNames:Array<String> = [], pos:Position = Context.currentPos();
		for (f in fields) fieldNames.push(f.name);

		function addField(name:String, args:Array<String>, signature:String) {
			var meta:Metadata = [], kind = null;

			if (Context.defined("cpp") && !Context.defined("cppia")) {
				if (Context.defined("disable_cffi") || Context.definedValue("haxe_ver") < "3.4.0") {
					kind = FFun({ret: macro :Void, args: [for (arg in args) {name: arg, type: macro :lime.system.CFFIPointer}], expr: macro {}});
					meta.push({name: ":cffi", pos: pos});
				}
				else {
					kind = FVar(macro :cpp.Callable<cpp.Object->cpp.Void>, macro new cpp.Callable<cpp.Object->cpp.Void>(cpp.Prime._loadPrime("lime", $v{name}, $v{signature}, false)));
				}
			}
			else if (Context.defined("neko") || Context.defined("cppia")) {
				kind = FVar(macro :Dynamic, macro lime.system.CFFI.load("lime", $v{name}, $v{args.length}));
			}
			else if (Context.defined("hl")) {
				kind = FFun({ret: macro :Void, args: [for (arg in args) {name: arg, type: macro :lime.system.CFFIPointer}], expr: macro {}});
				meta.push({pos: pos, name: ":hlNative", params: [macro "lime", macro $v{"hl" + name.substr(4)}]});
			}

			if (kind != null) fields.push({name: name, access: [APrivate, AStatic], pos: pos, kind: kind, meta: meta});
		}

		if (!fieldNames.contains("lime_al_delete_effect")) addField("lime_al_delete_effect", ["effect"], "ov");
		if (!fieldNames.contains("lime_al_delete_filter")) addField("lime_al_delete_filter", ["filter"], "ov");
		if (!fieldNames.contains("lime_al_delete_auxiliary_effect_slot")) addField("lime_al_delete_auxiliary_effect_slot", ["slot"], "ov");
		return fields;
	}

	public static macro function buildAL():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();

		final fieldNames:Array<String> = [], pos:Position = Context.currentPos();
		for (f in fields) fieldNames.push(f.name);

		if (!fieldNames.contains("deleteEffect"))
			fields.push({name: "deleteEffect", access: [APublic, AStatic], pos: pos, kind: FFun({
				ret: macro :Void, args: [{name: "effect", type: macro :lime.media.openal.ALEffect}],
				expr: macro lime._internal.backend.native.NativeCFFI.lime_al_delete_effect(effect)
			})});

		if (!fieldNames.contains("deleteFilter"))
			fields.push({name: "deleteFilter", access: [APublic, AStatic], pos: pos, kind: FFun({
				ret: macro :Void, args: [{name: "filter", type: macro :lime.media.openal.ALFilter}],
				expr: macro lime._internal.backend.native.NativeCFFI.lime_al_delete_filter(filter)
			})});

		if (!fieldNames.contains("deleteAux"))
			fields.push({name: "deleteAux", access: [APublic, AStatic], pos: pos, kind: FFun({
				ret: macro :Void, args: [{name: "aux", type: macro :lime.media.openal.ALAuxiliaryEffectSlot}],
				expr: macro lime._internal.backend.native.NativeCFFI.lime_al_delete_auxiliary_effect_slot(aux)
			})});

		return fields;
	}

	// fix maxThreads locked to 1
	public static macro function buildNativeHTTPRequest():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) if (f.name == "loadData") switch (f.kind) {
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					exprs.insert(0, macro if (localThreadPool != null) localThreadPool.maxThreads = 2);
				default:
			}
			default:
		}
		return fields;
	}

	// fix hardware cairo
	public static macro function buildCairoGraphics():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) if (f.name == "createImagePattern") switch (f.kind) {
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					exprs.insert(0, macro if (bitmapFill.__surface == null) return null);
				default:
			}
			default:
		}
		return fields;
	}

	// fix cairo surface
	public static macro function buildBitmapData():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) switch (f.kind) {
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					if (f.name == "getSurface") exprs.insert(0, macro if (__surface != null) return __surface);
					else if (f.name == "dispose") exprs.insert(0, macro if (__texture != null) __texture.dispose());
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
			case FFun(func): if (f.name == "__setBlendModeContext") {
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
			case FFun(func): if (f.name == "__setBlendModeCairo") {
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
		fields.push({name: "hasKHRBlendAdvancedExt", access: [AStatic, APublic], pos: pos, kind: FVar(macro :Null<Bool>, macro null)});
		for (f in fields) switch (f.kind) {
			case FFun(func): switch (f.name) {
				case "__getMatrix":
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
				case "__setBlendMode":
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
				case "new":
					switch (func.expr.expr) {
						case EBlock(exprs):
							exprs.push(macro
								if (hasKHRBlendAdvancedExt == null) {
									hasKHRBlendAdvancedExt = gl.getSupportedExtensions().contains("KHR_blend_equation_advanced");
								}
							);
						default:
					}
				case "__render":
					switch (func.expr.expr) {
						case EBlock(exprs):
							for (i => code in exprs) switch (code.expr) {
								case ECall(expr, _): switch (expr.expr) {
									case EField(expr, field, _):
										if (field == "setDepthTest") {
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

	// i hate set_filters
	public static macro function buildDisplayObject():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) if (f.name == "set_filters") switch (f.kind) {
			case FFun(func):
				func.args = [{name: "value", type: macro :Array<openfl.filters.BitmapFilter>}];
				func.expr = macro {
					if (__filters != value) {
						__filters = value;
						for (filter in __filters) filter.__renderDirty = true;
						__setRenderDirty();
					}
					return value;
				}
			default:
		}
		return fields;
	}

	// replace splice with swapAndPop instead in remove
	public static macro function buildFlxTypedGroup():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();

		var zIndicesName = null; // GOD DAMN IT SWORDCUBE
		for (f in fields) if (f.name == "zIndexesAllowed" || f.name == "zIndicesAllowed") {
			zIndicesName = f.name;
			break;
		}
		for (f in fields) switch (f.kind) {
			case FFun(func): switch (f.name) {
				case "remove":
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
				case "draw":
					if (zIndicesName == null) continue;
					func.expr = macro {
						final oldDefaultCameras = FlxCamera._defaultCameras;
						if (_cameras != null) FlxCamera._defaultCameras = _cameras;
						if (zIndexesAllowed) {
							_drawQueue.resize(members.length);
							var basic:FlxBasic = null, len:Int = 0;
							for (i in 0...members.length) {
								if ((basic = members[i]) != null && basic.exists && basic.visible) {
									_drawQueue[len] = i;
									len++;
								}
							}

							_drawQueue.sort(_drawQueueSort);

							for (i in 0...len) {
								if ((basic = members[_drawQueue[i]]) != null && basic.exists && basic.visible) basic.draw();
							}
						}
						else {
							for (basic in members) {
								if (basic != null && basic.exists && basic.visible) basic.draw();
							}
						}
						FlxCamera._defaultCameras = oldDefaultCameras;
					}
			}
			default:
		}

		return fields;
	}

	// add offset
	public static macro function buildFlxAnimation():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		
		var destroyFunc:Function = null;
		for (f in fields) {
			if (f.name == "offset") return fields;
			else if (f.name == "destroy") switch (f.kind) {
				case FFun(func): destroyFunc = func;
				default: fields.remove(f);
			}
		}

		fields.push({name: "offset", access: [APublic], pos: pos, kind: FVar(macro: flixel.math.FlxPoint, macro flixel.math.FlxPoint.get())});
		if (destroyFunc == null) {
			fields.push({name: "destroy", access: [APublic], pos: pos, kind: FFun({args: [], expr: macro {
				super.destroy();
				offset = flixel.util.FlxDestroyUtil.put(offset);
			}})});
		}
		else switch (destroyFunc.expr.expr) {
			case EBlock(exprs): exprs.insert(0, macro offset = flixel.util.FlxDestroyUtil.put(offset));
			default:
		}
		return fields;
	}

	// add frameOffsetAngle, frameOffset
	public static macro function buildFlxSprite():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		
		var initVarsExprs:Array<Expr> = null, destroyExprs:Array<Expr> = null, drawFrameComplexFunction:Function = null, updateTrigFunction:Function = null;
		var f:Field, i:Int = fields.length;
		while (i-- > 0) {
			f = fields[i];
			if (f.name == "frameOffsetAngle" || f.name == "frameOffset") fields.remove(f);
			else switch (f.kind) {
				case FFun(func):
					if (f.name == "drawFrameComplex") drawFrameComplexFunction = func;
					else if (f.name == "updateTrig") updateTrigFunction = func;
					else switch (func.expr.expr) {
						case EBlock(exprs):
							if (f.name == "initVars") initVarsExprs = exprs;
							else if (f.name == "destroy") destroyExprs = exprs;
						default:
					}
				default:
			}
		}

		fields.push({name: "frameOffset", access: [APublic], pos: pos, kind: FProp("default", "null", macro :flixel.math.FlxPoint)});
		fields.push({name: "frameOffsetAngle", access: [APublic], pos: pos, kind: FProp("get", "set", macro :Null<Float>), meta: [{pos: pos, name: ":isVar"}]});
		fields.push({name: "_frameOffsetAngleChanged", access: [], pos: pos, kind: FVar(macro :Bool, macro true)});
		fields.push({name: "_sinFrameOffsetAngle", access: [], pos: pos, kind: FVar(macro :Float)});
		fields.push({name: "_cosFrameOffsetAngle", access: [], pos: pos, kind: FVar(macro :Float)});
		fields.push({name: "updateFrameOffsetTrig", access: [AInline], pos: pos, kind: FFun({args: [], expr: macro {
			if (_frameOffsetAngleChanged) {
				final radians = (frameOffsetAngle - angle) * 0.017453292519943295/*FlxAngle.TO_RAD*/;
				_sinFrameOffsetAngle = Math.sin(radians);
				_cosFrameOffsetAngle = Math.cos(radians);
				_frameOffsetAngleChanged = false;
			}
		}})});
		fields.push({name: "get_frameOffsetAngle", access: [APublic], pos: pos, kind: FFun({ret: macro :Float, args: [], expr: macro return frameOffsetAngle})});
		fields.push({name: "set_frameOffsetAngle", access: [APublic], pos: pos, kind: FFun({ret: macro :Float, args: [{name: "value", type: macro :Float}], expr: macro {
			if (frameOffsetAngle != value) {
				frameOffsetAngle = value;
				_frameOffsetAngleChanged = true;
			}
			return value;
		}})});

		if (initVarsExprs != null) initVarsExprs.push(macro frameOffset = flixel.math.FlxPoint.get());
		if (destroyExprs != null) destroyExprs.push(macro frameOffset = flixel.util.FlxDestroyUtil.put(frameOffset));
		if (updateTrigFunction != null) {
			updateTrigFunction.expr = macro {
				if (_angleChanged) {
					final radians = angle * 0.017453292519943295/*FlxAngle.TO_RAD*/;
					_sinAngle = Math.sin(radians);
					_cosAngle = Math.cos(radians);
					_angleChanged = false;

					_frameOffsetAngleChanged = true;
					updateFrameOffsetTrig();
				}
			};
		}
		if (drawFrameComplexFunction != null) {
			drawFrameComplexFunction.args = [{name: "frame", type: macro :flixel.graphics.frames.FlxFrame}, {name: "camera", type: macro :flixel.FlxCamera}];
			drawFrameComplexFunction.expr = macro {
				frame.prepareMatrix(_matrix, flixel.graphics.frames.FlxFrame.FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
				_matrix.translate(-origin.x, -origin.y);

				updateTrig();
				_matrix.rotateWithTrig(_cosFrameOffsetAngle, _sinFrameOffsetAngle);
				_matrix.translate(-frameOffset.x, -frameOffset.y);
				if (animation.curAnim != null) {
					if (animation.curAnim.offset != null) _matrix.translate(-animation.curAnim.offset.x, -animation.curAnim.offset.y);
				}
				_matrix.rotateWithTrig(_cosFrameOffsetAngle, -_sinFrameOffsetAngle);

				_matrix.scale(scale.x, scale.y);
				if (bakedRotationAngle <= 0) {
					if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
				}
				
				getScreenPosition(_point, camera).subtract(offset).add(origin.x, origin.y);
				_matrix.translate(_point.x, _point.y);
				
				if (isPixelPerfectRender(camera)) {
					_matrix.tx = Math.floor(_matrix.tx);
					_matrix.ty = Math.floor(_matrix.ty);
				}

				camera.drawPixels(frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
			};
		}
		return fields;
	}

	// aAGAGHGHG
	public static macro function buildFlxAnimate():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) switch (f.kind) {
			case FFun(func): if (f.name == "drawFrameComplex") {
				func.args = [{name: "frame", type: macro :flixel.graphics.frames.FlxFrame}, {name: "camera", type: macro :flixel.FlxCamera}];
				func.expr = macro {
					frame.prepareMatrix(_matrix, flixel.graphics.frames.FlxFrame.FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
					_matrix.translate(-origin.x, -origin.y);

					updateTrig();
					_matrix.rotateWithTrig(_cosFrameOffsetAngle, _sinFrameOffsetAngle);
					_matrix.translate(-frameOffset.x, -frameOffset.y);
					if (animation.curAnim != null) {
						if (animation.curAnim.offset != null) _matrix.translate(-animation.curAnim.offset.x, -animation.curAnim.offset.y);
					}
					_matrix.rotateWithTrig(_cosFrameOffsetAngle, -_sinFrameOffsetAngle);

					_matrix.scale(scale.x, scale.y);
					if (bakedRotationAngle <= 0) {
						if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
					}

					if (skew.x != 0 || skew.y != 0) {
						//FlxAngle.TO_RAD
						_skewMatrix.setTo(1, Math.tan(skew.y * 0.017453292519943295), Math.tan(skew.x * 0.017453292519943295), 1, 0, 0);
						_matrix.concat(_skewMatrix);
					}
					
					getScreenPosition(_point, camera).subtract(offset).add(origin.x, origin.y);
					_matrix.translate(_point.x, _point.y);
					
					if (isPixelPerfectRender(camera)) {
						_matrix.tx = Math.floor(_matrix.tx);
						_matrix.ty = Math.floor(_matrix.ty);
					}

					camera.drawPixels(frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
				};
			}
			else if (f.name == "drawAnimate") {
				func.args = [{name: "camera", type: macro :flixel.FlxCamera}];
				func.expr = macro {
					@:privateAccess _matrix.setTo(1, 0, 0, 1, -timeline._bounds.x, -timeline._bounds.y);

					if (checkFlipX()) {
						_matrix.scale(-1, 1);
						_matrix.translate(frame.sourceSize.x, 0);
					}

					if (checkFlipY()) {
						_matrix.scale(1, -1);
						_matrix.translate(0, frame.sourceSize.y);
					}

					if (applyStageMatrix) _matrix.concat(library.matrix);

					_matrix.translate(-origin.x, -origin.y);

					updateTrig();
					_matrix.rotateWithTrig(_cosFrameOffsetAngle, _sinFrameOffsetAngle);
					_matrix.translate(-frameOffset.x, -frameOffset.y);
					if (animation.curAnim != null) {
						if (animation.curAnim.offset != null) _matrix.translate(-animation.curAnim.offset.x, -animation.curAnim.offset.y);
					}
					_matrix.rotateWithTrig(_cosFrameOffsetAngle, -_sinFrameOffsetAngle);

					_matrix.scale(scale.x, scale.y);
					if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);

					if (skew.x != 0 || skew.y != 0) {
						//FlxAngle.TO_RAD
						_skewMatrix.setTo(1, Math.tan(skew.y * 0.017453292519943295), Math.tan(skew.x * 0.017453292519943295), 1, 0, 0);
						_matrix.concat(_skewMatrix);
					}

					getScreenPosition(_point, camera).subtract(offset).add(origin.x, origin.y);
					_matrix.translate(_point.x, _point.y);

					if (isPixelPerfectRender(camera)) {
						_matrix.tx = Math.floor(_matrix.tx);
						_matrix.ty = Math.floor(_matrix.ty);
					}

					if (renderStage) drawStage(camera);

					timeline.currentFrame = animation.frameIndex;
					timeline.draw(camera, _matrix, colorTransform, blend, antialiasing, shader);
				}
			}
			default:
		}
		return fields;
	}

	// adds createPost
	public static macro function buildFlxState():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) if (f.name == "createPost") return fields;

		fields.push({name: "createPost", access: [APublic], pos: Context.currentPos(), kind: FFun({args: [], expr: macro {}})});
		return fields;
	}

	// fix resolution
	/*
	inline static function attachBitmapCacheFix(idx:Int, exprs:Array<Expr>, ?prefix:Array<String>) {
		if (prefix == null) prefix = [];
		exprs.insert(idx, macro @:privateAccess $p{prefix.concat(["__cacheBitmapData"])} =
			$p{prefix.concat(["__cacheBitmapData2"])} =
			$p{prefix.concat(["__cacheBitmapData3"])} = null);
		exprs.insert(idx, macro @:privateAccess if ($p{prefix.concat(["__cacheBitmapData"])} != null) $p{prefix.concat(["__cacheBitmapData"])}.dispose());
		exprs.insert(idx, macro @:privateAccess if ($p{prefix.concat(["__cacheBitmapData2"])} != null) $p{prefix.concat(["__cacheBitmapData2"])}.dispose());
		exprs.insert(idx, macro @:privateAccess if ($p{prefix.concat(["__cacheBitmapData3"])} != null) $p{prefix.concat(["__cacheBitmapData3"])}.dispose());
	}
	*/

	// fix resolution, add createPost
	public static macro function buildFlxGame():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		final f:Function = {
			args: [{name: "r", type: macro :openfl.geom.Rectangle}, {name: "m", type: macro :openfl.geom.Matrix}],
			expr: macro r.setTo(0, 0, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y)
		};

		for (f in fields) switch (f.kind) {
			case FFun(func): switch (f.name) {
				/*case "resizeGame": switch (func.expr.expr) {
					case EBlock(exprs): //attachBitmapCacheFix(0, exprs);
						exprs.push(macro graphics.clear());
						exprs.push(macro graphics.beginFill(0, 1));
						exprs.push(macro graphics.drawRect(0, 0, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y));
						exprs.push(macro graphics.endFill());
					default:
				}*/
				case "switchState": switch (func.expr.expr) {
					case EBlock(exprs):
						exprs.insert(exprs.length - 1, macro if (_state != null) _state.createPost());
					default:
				}
			}
			default:
		}

		for (name in ["__getBounds", "__getFilterBounds", "__getRenderBounds"])
			fields.push({name: name, access: [AOverride], pos: pos, kind: FFun(f)});

		return fields;
	}

	// bring or patch shit stuff from potential fork flixel that likes to fuck shit up
	public static macro function buildFlxCamera():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos(), fieldNames:Array<String> = [];
		var f:Field, i:Int = fields.length;
		while (i-- > 0) switch ((f = fields[i]).kind) {
			case FFun(func): switch (f.name) {
				case "set_followLerp" | "set_filters" | "get_filters" | "addShader" | "removeShader": fields.remove(f);
				/*case "onResize": switch (func.expr.expr) {
					case EBlock(exprs): attachBitmapCacheFix(0, exprs, ["flashSprite"]);
					default:
				}*/
				case "set_zoom":
					func.args = [{name: "value", type: macro :Float}];
					func.expr = macro {
						zoom = (value == 0) ? defaultZoom : value;
						setScale(getActualZoom(), getActualZoom());
						return value;
					};
				case "startQuadBatch":
					func.args.push({name: "depthCompareMode", type: macro :openfl.display3D.Context3DCompareMode, opt: true});
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
				case "startTrianglesBatch":
					func.args.push({name: "depthCompareMode", type: macro :openfl.display3D.Context3DCompareMode, opt: true});
					func.args.push({name: "culling", type: macro :openfl.display.TriangleCulling, opt: true});
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
				case "getNewDrawTrianglesItem":
					func.args.push({name: "depthCompareMode", type: macro :openfl.display3D.Context3DCompareMode, opt: true});
					func.args.push({name: "culling", type: macro :openfl.display.TriangleCulling, opt: true});
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
			default: switch (f.name) {
				case "_filters": fields.remove(f);
				case "filters": f.kind = FVar(macro :Null<Array<openfl.filters.BitmapFilter>>, macro null);
				case "followLerp": f.kind = FVar(macro :Float, macro 1);
				default:
					fieldNames.push(f.name);
			}
		}

		// just add stuff idc, these flixel forks pmo
		if (!fieldNames.contains("followEnabled")) fields.push({name: "followEnabled", access: [APublic], pos: pos, kind: FVar(macro :Bool, macro true)});
		if (!fieldNames.contains("paused")) fields.push({name: "paused", access: [APublic], pos: pos, kind: FVar(macro :Bool, macro false)});
		if (!fieldNames.contains("zoomMultiplier")) {
			fields.push({name: "zoomMultiplier", access: [APublic], pos: pos, kind: FProp("default", "set", macro :Float, macro 1.0)});
			fields.push({name: "set_zoomMultiplier", access: [APublic], pos: pos, kind: FFun({
				args: [{name: "value", type: macro :Float}], ret: macro :Float, expr: macro {
					zoomMultiplier = value;
					setScale(getActualZoom(), getActualZoom());
					return value;
				}
			})});
			fields.push({name: "getActualZoom", access: [APublic, AInline], pos: pos, kind: FFun({
				args: [], ret: macro :Float, expr: macro return zoom * zoomMultiplier
			})});
		}

		return fields;
	}

	// fix compilation error for custom openfl
	public static macro function buildVideo():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		for (f in fields) switch (f.name) {
			case "__enterFrame": fields.remove(f); break;
			default:
		}

		return fields;
	}
}
#end