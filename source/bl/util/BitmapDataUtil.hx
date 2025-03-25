package bl.util;

import lime.graphics.RenderContextType;
import openfl.display._internal.Context3DShape;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Graphics;
import openfl.display.IBitmapDrawable;
import openfl.display.OpenGLRenderer;
import openfl.display.Sprite;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.filters.BitmapFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.geom.Matrix;
import flixel.math.FlxRect;

@:access(openfl.display.BitmapData)
@:access(openfl.display.IBitmapDrawable)
@:access(openfl.display.DisplayObjectRenderer)
@:access(openfl.display.DisplayObject)
@:access(openfl.display.Graphics)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.display.Sprite)
@:access(openfl.display.Stage)
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display3D.Context3D)
@:access(openfl.filters.BitmapFilter)
@:access(openfl.geom.ColorTransform)
@:access(openfl.geom.Rectangle)
class BitmapDataUtil {
	static var gfxBitmap:Bitmap = new Bitmap();
	static var gfxSprite(get, null):Sprite;
	static function get_gfxSprite():Sprite {
		if (gfxSprite == null) {
			(gfxSprite = new Sprite()).addChild(gfxBitmap);
			gfxSprite.__cacheBitmapMatrix = new Matrix();
			gfxSprite.__cacheBitmapColorTransform = new ColorTransform();
		}
		return gfxSprite;
	}

	public static function getGfxRenderer():OpenGLRenderer {
		if (FlxG.stage.__renderer == null || FlxG.stage.__renderer.__type != OPENGL) return null;
		var renderer:OpenGLRenderer = cast gfxSprite.__cacheBitmapRenderer;
		if (renderer == null || renderer.__type != OPENGL) {
			gfxSprite.__cacheBitmapRenderer = cast renderer = new OpenGLRenderer(FlxG.stage.context3D);
			renderer.__worldTransform = new Matrix();
			renderer.__worldColorTransform = new ColorTransform();
		}
		else {
			renderer.__worldTransform.identity();
			@:privateAccess renderer.__worldColorTransform.__identity();
			renderer.__worldAlpha = 1;
			renderer.__overrideBlendMode = null;
			renderer.__blendMode = null;
		}

		renderer.__allowSmoothing = (renderer.__stage = FlxG.stage).__renderer.__allowSmoothing;
		renderer.__clearShader();
		//renderer.__copyShader(cast FlxG.stage.__renderer);
		return renderer;
	}

	inline static function prepareCacheBitmapData(bitmap:BitmapData, width:Int, height:Int):BitmapData {
		if (bitmap == null) return create(width, height);
		resize(bitmap, width, height);
		return bitmap;
	}
	public static function applyFilters(bitmap:BitmapData, filters:Array<BitmapFilter>, resizeBitmap = false, ?rect:FlxRect) {
		if (filters == null || filters.length == 0) return;

		var width:Int = bitmap.width, height:Int = bitmap.height;
		if (resizeBitmap) {
			final flashRect = Rectangle.__pool.get(), cacheFilters = gfxSprite.__filters;
			gfxSprite.__filters = filters;
			gfxBitmap.bitmapData = bitmap;
			gfxSprite.__getFilterBounds(flashRect, gfxSprite.__cacheBitmapMatrix);
			gfxSprite.__filters = cacheFilters;

			if (rect != null) rect.copyFromFlash(flashRect);
			resize(bitmap, width = Math.floor(flashRect.width), height = Math.floor(flashRect.height));
			Rectangle.__pool.release(flashRect);
		}
		else if (rect != null) rect.set(0, 0, width, height);

		var bitmap2 = gfxSprite.__cacheBitmapData2 = prepareCacheBitmapData(gfxSprite.__cacheBitmapData2, width, height);
		var bitmap3 = gfxSprite.__cacheBitmapData3, cacheBitmap:BitmapData;

		final renderer = getGfxRenderer();
		if (hardwareCheck(bitmap) && renderer != null) {
			for (filter in filters) {
				if (filter.__preserveObject) {
					renderer.__setRenderTarget(bitmap3 = prepareCacheBitmapData(bitmap3, width, height));
					renderer.__renderFilterPass(bitmap, renderer.__defaultDisplayShader, false, false);
				}

				for (i in 0...filter.__numShaderPasses) {
					final shader = filter.__initShader(renderer, i, filter.__preserveObject ? bitmap3 : null);
					renderer.__setBlendMode(filter.__shaderBlendMode);
					renderer.__setRenderTarget(bitmap2);

					clear(bitmap2);
					renderer.__renderFilterPass(cacheBitmap = bitmap, shader, filter.__smooth, false);

					bitmap = bitmap2;
					bitmap2 = cacheBitmap;
				}

				renderer.__setBlendMode(NORMAL);
			}

			if (bitmap == gfxSprite.__cacheBitmapData2) {
				renderer.__setRenderTarget(bitmap2);
				renderer.__renderFilterPass(bitmap, renderer.__defaultDisplayShader, false, false);
				//bitmap = bitmap2;
			}
			renderer.__context3D.setRenderToBackBuffer();
		}
		else {
			final destPoint = gfxSprite.__tempPoint = gfxSprite.__tempPoint ?? new Point();
			for (filter in filters) {
				if (filter.__preserveObject)
					(bitmap3 = prepareCacheBitmapData(bitmap3, width, height)).copyPixels(bitmap, bitmap.rect, destPoint);

				cacheBitmap = filter.__applyFilter(bitmap2, bitmap, bitmap.rect, destPoint);

				if (filter.__preserveObject) cacheBitmap.draw(bitmap3);
				if (cacheBitmap == bitmap2) copyFrom(bitmap, bitmap2, false);
			}
		}

		gfxSprite.__cacheBitmapData3 = bitmap3;
	}

	public static function applyFilter(bitmap:BitmapData, filter:BitmapFilter) {
		if (((gfxSprite.__filters = gfxSprite.__filters ?? [])[0] = filter) == null) return;
		gfxSprite.__filters.resize(1);
		applyFilters(bitmap, gfxSprite.__filters);
		gfxSprite.__filters[0] = null;
	}

	public static function copyFrom(dst:BitmapData, src:BitmapData, ?alpha:Float, resizeBitmap = true) {
		if (resizeBitmap) resize(dst, src.width, src.height);

		if (dst.image != null && src.image != null && alpha == null)
			dst.copyPixels(src, dst.rect, gfxSprite.__tempPoint = gfxSprite.__tempPoint ?? new Point());
		else {
			final renderer = getGfxRenderer();
			if (renderer == null) {
				gfxBitmap.bitmapData = src;
				if (alpha != null) { // TODO: this doesnt work, need fix
					final colorTransform = new ColorTransform(1, 1, 1, alpha);
					dst.draw(gfxSprite, colorTransform);
				}
				else {
					clear(dst);
					dst.draw(gfxSprite);
				}
			}
			else {
				final context = renderer.__context3D;
				final cacheRTT = context.__state.renderToTexture,
					cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil,
					cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias,
					cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;

				renderer.__setBlendMode(NORMAL);
				renderer.__setRenderTarget(dst);
				if (alpha != null) renderer.__worldAlpha = alpha;
				renderer.__renderFilterPass(src, renderer.__defaultDisplayShader, false, false);

				if (cacheRTT != null)
					context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
				else
					context.setRenderToBackBuffer();
			}
		}
	}

	public static function draw(dst:BitmapData, src:IBitmapDrawable, ?matrix:Matrix, smoothing = false, onlyGraphics = false) {
		if (!hardwareCheck(dst)) return dst.draw(src, matrix, smoothing);

		final renderer = getGfxRenderer();
		if (renderer == null) return;

		var srcAsDisplayObject:DisplayObject = null;
		if (src is DisplayObject) {
			if ((srcAsDisplayObject = cast src).__graphics == null && onlyGraphics) return;
			gfxSprite.__visible = srcAsDisplayObject.__visible;
			srcAsDisplayObject.__visible = true;
		}
		else if (onlyGraphics) return;

		src.__update(false, true);
		if (src.__renderable) {
			final context = renderer.__context3D;
			final cacheRTT = context.__state.renderToTexture,
				cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil,
				cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias,
				cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;

			dst.__textureContext = context.__context;
			renderer.__setBlendMode(NORMAL);
			renderer.__setRenderTarget(dst);

			context.setRenderToTexture(dst.__texture, true);
			context.setColorMask(true, true, true, true);
			context.setCulling(NONE);
			//context.setDepthTest(false, ALWAYS);
			context.setStencilActions();
			context.setStencilReferenceValue(0, 0, 0);
			context.setScissorRectangle(null);

			renderer.__allowSmoothing = smoothing;
			renderer.__pixelRatio = #if openfl_disable_hdpi 1 #else FlxG.stage.window.scale #end;

			gfxSprite.__cacheBitmapColorTransform.__copyFrom(src.__worldColorTransform);
			gfxSprite.__mask = src.__mask; gfxSprite.__scrollRect = src.__scrollRect;

			src.__worldColorTransform.__identity();
			src.__worldAlpha = 1; src.__mask = null; src.__scrollRect = null;

			renderer.__worldTransform.copyFrom(src.__renderTransform);
			renderer.__worldTransform.invert();
			if (matrix != null) renderer.__worldTransform.concat(matrix);

			if (onlyGraphics) {
				srcAsDisplayObject.__graphics.__bitmapScale = 1;
				Context3DShape.render(srcAsDisplayObject, renderer);
			}
			else
				renderer.__renderDrawable(src);

			src.__worldColorTransform.__copyFrom(gfxSprite.__cacheBitmapColorTransform);
			src.__mask = gfxSprite.__mask; src.__scrollRect = gfxSprite.__scrollRect;
			gfxSprite.__mask = null; gfxSprite.__scrollRect = null;

			if (cacheRTT != null)
				context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
			else
				context.setRenderToBackBuffer();
		}

		if (srcAsDisplayObject != null && !(srcAsDisplayObject.__visible = gfxSprite.__visible))
			gfxSprite.__visible = true;
	}

	public static function create(width:Int, height:Int, format:Context3DTextureFormat = BGRA):BitmapData {
		width = Math.ceil(Math.min(width, FlxG.bitmap.maxTextureSize));
		height = Math.ceil(Math.min(height, FlxG.bitmap.maxTextureSize));

		if (FlxG.stage.context3D != null) {
			final texture = FlxG.stage.context3D.createTexture(width, height, format, true);
			final bitmap = new BitmapData(0, 0, true, 0);
			bitmap.__textureContext = (bitmap.__texture = texture).__textureContext;
			bitmap.__resize(width, height);
			bitmap.__isValid = true;
			texture.__getGLFramebuffer(true, 0, 0);
			return bitmap;
		}
		else
			return new BitmapData(width, height, true, 0);
	}

	public static function toHardware(bitmap:BitmapData) {
		final context = FlxG.stage.context3D;
		if (context == null || bitmap.image == null) return;

		if (!hardwareCheck(bitmap)) {
			#if openfl_power_of_two bitmap.image.powerOfTwo = true; #end
			bitmap.image.premultiplied = true;

			bitmap.__textureContext = context.__context;
			bitmap.__texture = context.createTexture(bitmap.width, bitmap.height, BGRA, true);
			bitmap.getTexture(context);
		}
		bitmap.readable = false;
		bitmap.image.data = null;
		bitmap.image = null;
	}

	inline public static function flush() {
		FlxG.stage.context3D.__flushGLFramebuffer();
		FlxG.stage.context3D.__flushGLViewport();
	}

	public static function clear(bitmap:BitmapData, color:Int = 0, depth = false, stencil = false) {
		if (bitmap.__texture != null) clearTexture(bitmap.__texture, color, depth, stencil);
		else bitmap.__fillRect(bitmap.rect, color, false);
	}

	public static function clearTexture(texture:TextureBase, color:FlxColor, depth = false, stencil = false) {
		flush();

		final context = texture.__context;
		final gl = context.gl;

		gl.bindFramebuffer(gl.FRAMEBUFFER, texture.__glFramebuffer ?? texture.__getGLFramebuffer(true, 0, 0));

		gl.disable(gl.SCISSOR_TEST);
		gl.colorMask(true, true, true, true);
		gl.clearColor(color.redFloat, color.greenFloat, color.blueFloat, color.alphaFloat);

		context.__contextState.colorMaskRed = true;
		context.__contextState.colorMaskGreen = true;
		context.__contextState.colorMaskBlue = true;
		context.__contextState.colorMaskAlpha = true;

		var flag = gl.COLOR_BUFFER_BIT;
		if (depth) {
			context.__contextState.depthMask = true;
			gl.depthMask(true);
			gl.clearDepth(1);
			flag |= gl.DEPTH_BUFFER_BIT;
		}
		if (stencil) {
			context.__contextState.stencilWriteMask = 0xFF;
			gl.stencilMask(0xFF);
			gl.clearStencil(0);
			flag |= gl.STENCIL_BUFFER_BIT;
		}
		gl.clear(flag);

		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
	}

	public static function resize(bitmap:BitmapData, width:Int, height:Int, regen = false) {
		if (bitmap.width == width && bitmap.height == height) return;
		if (bitmap.rect == null) bitmap.rect = new Rectangle(0, 0, width, height);
		bitmap.__resize(width, height);

		if (regen) {
			final texture = FlxG.stage.context3D.createTexture(width, height, BGRA, true);
			if (bitmap.__texture == null) bitmap.__texture.dispose();
			bitmap.__textureContext = (bitmap.__texture = texture).__textureContext;
			if (bitmap.image != null) {
				bitmap.image.fillRect(bitmap.image.rect, 0);
				bitmap.image.resize(width, height);
			}
			bitmap.getTexture(FlxG.stage.context3D);
		}
		else {
			if (bitmap.image != null) bitmap.image.resize(width, height);
			if (hardwareCheck(bitmap, true)) resizeTexture(bitmap.__texture, width, height);
			else bitmap.getTexture(FlxG.stage.context3D);
		}

		bitmap.__indexBufferContext = bitmap.__framebufferContext = bitmap.__textureContext;
		bitmap.__framebuffer = bitmap.__texture.__glFramebuffer;
		bitmap.__stencilBuffer = bitmap.__texture.__glStencilRenderbuffer;
		bitmap.__vertexBuffer = null;
		bitmap.getVertexBuffer(FlxG.stage.context3D);

		if (bitmap.__surface != null) bitmap.__surface.flush();
	}

	public static function resizeTexture(texture:TextureBase, width:Int, height:Int) {
		if (texture.__alphaTexture != null) resizeTexture(texture.__alphaTexture, width, height);
		if (texture.__width == width && texture.__height == height) return;

		final context = texture.__context;
		final gl = context?.gl;
		if (gl == null) return;

		texture.__width = width = Math.floor(Math.min(width, FlxG.bitmap.maxTextureSize));
		texture.__height = height = Math.floor(Math.min(height, FlxG.bitmap.maxTextureSize));

		final cacheRTT = context.__state.renderToTexture,
			cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil,
			cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias,
			cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;

		context.__bindGLTexture2D(texture.__textureID);
		gl.texImage2D(texture.__textureTarget, 0, texture.__internalFormat, width, height, 0, texture.__format, gl.UNSIGNED_BYTE, null);

		if (texture.__glFramebuffer != null || texture.__glDepthRenderbuffer != null) {
			if (texture.__glDepthRenderbuffer != null) gl.deleteRenderbuffer(texture.__glDepthRenderbuffer);
			texture.__glDepthRenderbuffer = null;

			if (texture.__glStencilRenderbuffer != null) gl.deleteRenderbuffer(texture.__glStencilRenderbuffer);
			texture.__glStencilRenderbuffer = null;

			if (texture.__glFramebuffer != null) gl.deleteFramebuffer(texture.__glFramebuffer);
			texture.__glFramebuffer = null;

			texture.__getGLFramebuffer(true, 0, 0);
		}

		if (cacheRTT != null)
			context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		else
			context.setRenderToBackBuffer();
	}

	#if !hscript inline #end public static function hardwareCheck(bitmap:BitmapData, strict = false):Bool
		return bitmap?.__texture != null && (!strict || (bitmap.image == null || bitmap.__textureVersion >= bitmap.image.version));
}