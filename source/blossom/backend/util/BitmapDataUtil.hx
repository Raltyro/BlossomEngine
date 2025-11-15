package blossom.backend.util;

#if openfl
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.ImageType;
import lime.graphics.PixelFormat;
import lime.utils.ArrayBufferView;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Graphics;
import openfl.display.IBitmapDrawable;
import openfl.display.OpenGLRenderer;
import openfl.display.Sprite;
import openfl.display.Shader;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.filters.BitmapFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.geom.Matrix;
import flixel.math.FlxRect;

final class BitmapDataUtil {
	public static var context3D(get, never):Context3D; inline static function get_context3D():Context3D return FlxG.stage.context3D;

	public static var gfxBitmap:Bitmap;
	public static var gfxSprite:Sprite;
	public static var gfxRenderer:OpenGLRenderer;

	public static function prepareGfxSprite() @:privateAccess {
		if (gfxSprite == null) {
			(gfxSprite = new Sprite()).addChild(gfxBitmap = new Bitmap());
			gfxSprite.__cacheBitmapMatrix = new Matrix();
			gfxSprite.__cacheBitmapColorTransform = new ColorTransform();
		}
		else {
			gfxSprite.__cacheBitmapMatrix.identity();
			gfxSprite.__cacheBitmapColorTransform.__identity();
		}
	}

	public static function prepareGfxRenderer() @:privateAccess {
		prepareGfxSprite();

		if (gfxRenderer == null) {
			if ((gfxRenderer = cast gfxSprite.__cacheBitmapRenderer) == null || gfxRenderer.__type != OPENGL) {
				gfxSprite.__cacheBitmapRenderer = cast gfxRenderer = new OpenGLRenderer(context3D);
			}
			gfxRenderer.__worldTransform = new Matrix();
			gfxRenderer.__worldColorTransform = new ColorTransform();
			gfxRenderer.__allowSmoothing = (gfxRenderer.__stage = FlxG.stage).__renderer.__allowSmoothing;
		}
		else {
			gfxRenderer.__worldTransform.identity();
			gfxRenderer.__worldColorTransform.__identity();
			gfxRenderer.__worldAlpha = 1;
			gfxRenderer.__overrideBlendMode = gfxRenderer.__blendMode = null;

			gfxRenderer.__clearShader();
			//gfxRenderer.__copyShader(cast FlxG.stage.__gfxRenderer);
		}
	}

	public static function copyFrom(dst:BitmapData, src:BitmapData, ?alpha:Float, ?matrix:Matrix, smoothing = false) @:privateAccess {
		if (dst.image != null && src.image != null && alpha == null && matrix == null) {
			dst.copyPixels(src, dst.rect, gfxSprite.__tempPoint = gfxSprite.__tempPoint ?? new Point());
		}
		else {
			prepareGfxRenderer();

			final context = gfxRenderer.__context3D;
			final cacheRTT = context.__state.renderToTexture,
				cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil,
				cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias,
				cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;

			gfxRenderer.__setRenderTarget(dst);
			if (alpha != null) gfxRenderer.__worldAlpha = alpha;
			if (matrix != null) gfxRenderer.__worldTransform.concat(matrix);
			gfxRenderer.__renderFilterPass(src, gfxRenderer.__defaultDisplayShader, smoothing, false);

			if (cacheRTT != null) context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
			else context.setRenderToBackBuffer();
		}
	}

	public inline static function prepareCacheBitmapData(bitmap:BitmapData, width:Int, height:Int):BitmapData {
		if (bitmap == null) return create(width, height);
		resize(bitmap, width, height);
		return bitmap;
	}

	public static function applyShaders(bitmap:BitmapData, shaders:Array<Shader>) @:privateAccess {
		prepareGfxRenderer();

		final context = gfxRenderer.__context3D;
		final cacheRTT = context.__state.renderToTexture,
			cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil,
			cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias,
			cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;

		bitmap.getTexture(context);

		var bitmap2 = gfxSprite.__cacheBitmapData2 = prepareCacheBitmapData(gfxSprite.__cacheBitmapData2, bitmap.width, bitmap.height);
		var cacheBitmap:BitmapData;
		for (shader in shaders) {
			gfxRenderer.__setRenderTarget(bitmap2);

			clear(bitmap2);
			gfxRenderer.__renderFilterPass(cacheBitmap = bitmap, shader, false, false);

			bitmap = bitmap2;
			bitmap2 = cacheBitmap;
		}

		if (bitmap == gfxSprite.__cacheBitmapData2) {
			gfxRenderer.__setRenderTarget(bitmap2);
			gfxRenderer.__renderFilterPass(bitmap, gfxRenderer.__defaultDisplayShader, false, false);
		}

		if (cacheRTT != null) context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		else context.setRenderToBackBuffer();
	}

	public static function applyFilters(bitmap:BitmapData, filters:Array<BitmapFilter>, resizeBitmap = false, ?rect:FlxRect) @:privateAccess {
		if (filters == null || filters.length == 0) return;
		prepareGfxRenderer();

		var width = bitmap.width, height = bitmap.height;
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
		else if (rect != null)
			rect.set(0, 0, width, height);

		var bitmap2 = gfxSprite.__cacheBitmapData2 = prepareCacheBitmapData(gfxSprite.__cacheBitmapData2, width, height);
		var bitmap3 = gfxSprite.__cacheBitmapData3, cacheBitmap:BitmapData;

		if (bitmap.__texture != null && gfxRenderer != null) {
			final context = gfxRenderer.__context3D;
			final cacheRTT = context.__state.renderToTexture,
				cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil,
				cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias,
				cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;

			for (filter in filters) {
				if (filter.__preserveObject) {
					gfxRenderer.__setRenderTarget(bitmap3 = prepareCacheBitmapData(bitmap3, width, height));
					gfxRenderer.__renderFilterPass(bitmap, gfxRenderer.__defaultDisplayShader, false, false);
				}

				for (i in 0...filter.__numShaderPasses) {
					final shader = filter.__initShader(gfxRenderer, i, filter.__preserveObject ? bitmap3 : null);
					gfxRenderer.__setBlendMode(filter.__shaderBlendMode);
					gfxRenderer.__setRenderTarget(bitmap2);

					clear(bitmap2);
					gfxRenderer.__renderFilterPass(cacheBitmap = bitmap, shader, filter.__smooth, false);

					bitmap = bitmap2;
					bitmap2 = cacheBitmap;
				}

				gfxRenderer.__setBlendMode(NORMAL);
			}

			if (bitmap == gfxSprite.__cacheBitmapData2) {
				gfxRenderer.__setRenderTarget(bitmap2);
				gfxRenderer.__renderFilterPass(bitmap, gfxRenderer.__defaultDisplayShader, false, false);
			}

			if (cacheRTT != null) context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
			else context.setRenderToBackBuffer();
		}

		gfxSprite.__cacheBitmapData3 = bitmap3;
	}

	public static function draw(dst:BitmapData, src:IBitmapDrawable, ?matrix:Matrix, smoothing = false, onlyGraphics = false) @:privateAccess {
		prepareGfxRenderer();

		final context = gfxRenderer.__context3D;
		final cacheRTT = context.__state.renderToTexture,
			cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil,
			cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias,
			cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;

		inline function _preDraw() {
			dst.__textureContext = context.__context;
			context.setRenderToTexture(dst.getTexture(context), true);
			context.setColorMask(true, true, true, true);
			context.setCulling(NONE);
			context.setStencilActions();
			context.setStencilReferenceValue(0, 0, 0);
			context.setScissorRectangle(null);

			gfxRenderer.__blendMode = null;
			gfxRenderer.__setBlendMode(NORMAL);
			gfxRenderer.__setRenderTarget(dst);
			gfxRenderer.__allowSmoothing = smoothing;
			gfxRenderer.__pixelRatio = #if openfl_disable_hdpi 1 #else FlxG.stage.window.scale #end;

			gfxRenderer.__worldTransform.copyFrom(src.__renderTransform);
			gfxRenderer.__worldTransform.invert();
			if (matrix != null) gfxRenderer.__worldTransform.concat(matrix);

			gfxSprite.__cacheBitmapColorTransform.__copyFrom(src.__worldColorTransform);
			gfxSprite.__mask = src.__mask; gfxSprite.__scrollRect = src.__scrollRect;

			src.__worldColorTransform.__identity();
			src.__worldAlpha = 1; src.__mask = null; src.__scrollRect = null;
		}

		inline function _postDraw() {
			context.present();
			src.__worldColorTransform.__copyFrom(gfxSprite.__cacheBitmapColorTransform);
			src.__mask = gfxSprite.__mask; src.__scrollRect = gfxSprite.__scrollRect;
			gfxSprite.__mask = null; gfxSprite.__scrollRect = null;
		}

		if (src is DisplayObject) {
			final displayObject:DisplayObject = cast src;
			gfxSprite.__visible = displayObject.__visible;
			displayObject.__visible = true;

			src.__update(false, true);
			if (src.__renderable) {
				_preDraw();
				if (onlyGraphics && displayObject.__graphics != null) {
					#if (openfl >= "9.5.0")
					displayObject.__graphics.__bitmapScaleX = displayObject.__graphics.__bitmapScaleY = 1;
					#else
					displayObject.__graphics.__bitmapScale = 1;
					#end
					openfl.display._internal.Context3DShape.render(displayObject, gfxRenderer);
				}
				else gfxRenderer.__renderDrawable(src);
				_postDraw();
			}

			displayObject.__visible = gfxSprite.__visible;
			gfxSprite.__visible = true;
		}
		else if (!onlyGraphics) {
			src.__update(false, true);
			if (src.__renderable) {
				_preDraw();
				gfxRenderer.__renderDrawable(src);
				_postDraw();
			}
		}

		if (cacheRTT != null) context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		else context.setRenderToBackBuffer();
	}

	public static function create(width:Int, height:Int, color:FlxColor = 0):BitmapData @:privateAccess {
		width = MathUtil.minInt(width, FlxG.bitmap.maxTextureSize);
		height = MathUtil.minInt(height, FlxG.bitmap.maxTextureSize);

		if (context3D == null) return new BitmapData(width, height, true, color);
		else {
			final bitmap = new BitmapData(0, 0, true, 0);
			bitmap.__texture = context3D.createTexture(width, height, BGRA, true);

			if (color != 0) {
				final gl = context3D.gl;

				context3D.__flushGLFramebuffer();
				gl.bindFramebuffer(gl.FRAMEBUFFER, bitmap.__texture.__glFramebuffer);
				gl.colorMask(
					context3D.__contextState.colorMaskRed = true,
					context3D.__contextState.colorMaskGreen = true,
					context3D.__contextState.colorMaskBlue = true,
					context3D.__contextState.colorMaskAlpha = true
				);
				gl.clearColor(color.redFloat, color.greenFloat, color.blueFloat, color.alphaFloat);

				gl.disable(gl.SCISSOR_TEST);
				gl.clear(gl.COLOR_BUFFER_BIT);

				gl.bindFramebuffer(gl.FRAMEBUFFER, context3D.__contextState.__currentGLFramebuffer);
				if (context3D.__contextState.__enableGLScissorTest) gl.enable(gl.SCISSOR_TEST);
			}

			bitmap.__texture.__getGLFramebuffer(true, 0, 0);
			bitmap.__textureContext = context3D.__context;
			bitmap.__resize(width, height);
			bitmap.__isValid = true;
			return bitmap;
		}
	}

	inline public static function hardwareCheck(bitmap:BitmapData):Bool @:privateAccess 
		return bitmap?.__texture != null;

	public static function toHardware(bitmap:BitmapData) @:privateAccess {
		if (context3D == null || bitmap.image == null) return;

		#if openfl_power_of_two bitmap.image.powerOfTwo = true; #end
		bitmap.image.premultiplied = true;
		bitmap.image.format = BGRA32;

		if (bitmap.__texture == null) bitmap.__texture = context3D.createTexture(bitmap.width, bitmap.height, BGRA, true);
		bitmap.__textureContext = context3D.__context;
		bitmap.getTexture(context3D);
		bitmap.readable = false;
		bitmap.image = null;
	}

	public static function toReadable(bitmap:BitmapData) @:privateAccess {
		final texture = bitmap.__texture;
		if (texture == null || texture.__glFramebuffer == null) return;

		final context = texture.__context;
		final gl = context?.gl;
		if (gl == null) return;

		var buffer:ImageBuffer = bitmap.image?.buffer;
		if (buffer == null) {
			buffer = new ImageBuffer(new ArrayBufferView(bitmap.width * bitmap.height * 4, TypedArrayType.Uint8), bitmap.width, bitmap.height, 4);
			buffer.format = BGRA32;
			buffer.premultiplied = true;

			if (bitmap.image == null) bitmap.image = new Image(buffer, 0, 0, bitmap.width, bitmap.height);
			else {
				bitmap.image.offsetX = bitmap.image.offsetY = 0;
				bitmap.image.width = bitmap.width;
				bitmap.image.height = bitmap.height;
				bitmap.image.type = DATA;
				bitmap.image.buffer = buffer;
			}
		}

		context.__flushGLFramebuffer();
		gl.bindFramebuffer(gl.FRAMEBUFFER, texture.__glFramebuffer);
		gl.readPixels(0, 0, bitmap.width, bitmap.height, texture.__format, gl.UNSIGNED_BYTE, buffer.data);

		bitmap.readable = true;
		bitmap.image.version = 0;
		bitmap.__textureVersion = -1;

		gl.bindFramebuffer(gl.FRAMEBUFFER, context.__contextState.__currentGLFramebuffer);
	}

	public static function clear(bitmap:BitmapData, color = 0, depth = false, stencil = false) @:privateAccess {
		if (bitmap.__texture != null) clearTexture(bitmap.__texture, color, depth, stencil);
		else bitmap.__fillRect(bitmap.rect, color, false);
	}

	public static function clearTexture(texture:TextureBase, color:FlxColor, depth:Bool, stencil:Bool) @:privateAccess {
		if (texture.__glFramebuffer == null) return;

		final context = texture.__context;
		final gl = context?.gl;
		if (gl == null) return;

		context.__flushGLFramebuffer();

		gl.bindFramebuffer(gl.FRAMEBUFFER, texture.__glFramebuffer);

		gl.colorMask(
			context.__contextState.colorMaskRed = true,
			context.__contextState.colorMaskGreen = true,
			context.__contextState.colorMaskBlue = true,
			context.__contextState.colorMaskAlpha = true
		);
		gl.clearColor(color.redFloat, color.greenFloat, color.blueFloat, color.alphaFloat);

		var flag = gl.COLOR_BUFFER_BIT;
		if (depth) {
			gl.depthMask(context.__contextState.depthMask = true);
			gl.clearDepth(1);
			flag |= gl.DEPTH_BUFFER_BIT;
		}
		if (stencil) {
			gl.stencilMask(context.__contextState.stencilWriteMask = 0xFF);
			gl.clearStencil(0);
			flag |= gl.STENCIL_BUFFER_BIT;
		}
		gl.disable(gl.SCISSOR_TEST);
		gl.clear(flag);

		gl.bindFramebuffer(gl.FRAMEBUFFER, context3D.__contextState.__currentGLFramebuffer);
		if (context3D.__contextState.__enableGLScissorTest) gl.enable(gl.SCISSOR_TEST);
	}

	public static function updateFramebuffer(texture:TextureBase) @:privateAccess {
		final context = texture.__context;
		final gl = context?.gl;
		if (gl == null) return;

		if (texture.__glFramebuffer == null) texture.__getGLFramebuffer(false, 0, 0);
		else {
			gl.bindFramebuffer(gl.FRAMEBUFFER, texture.__glFramebuffer);
			gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture.__textureID, 0);

			final seperate = texture.__glDepthRenderbuffer != texture.__glStencilRenderbuffer;
			gl.bindRenderbuffer(gl.RENDERBUFFER, texture.__glDepthRenderbuffer);
			gl.renderbufferStorage(gl.RENDERBUFFER, seperate ? gl.DEPTH_COMPONENT16 : Context3D.__glDepthStencil, texture.__width, texture.__height);
			if (seperate) {
				gl.bindRenderbuffer(gl.RENDERBUFFER, texture.__glStencilRenderbuffer);
				gl.renderbufferStorage(gl.RENDERBUFFER, gl.STENCIL_INDEX8, texture.__width, texture.__height);
			}

			gl.bindRenderbuffer(gl.RENDERBUFFER, null);
		}

		gl.bindFramebuffer(gl.FRAMEBUFFER, context.__contextState.__currentGLFramebuffer);
	}

	public static function resize(bitmap:BitmapData, width:Int, height:Int) @:privateAccess {
		if (bitmap.width == width && bitmap.height == height) return;
		if (bitmap.rect == null) bitmap.rect = new Rectangle(0, 0, width, height);
		bitmap.__resize(width, height);

		if (bitmap.image != null) bitmap.image.resize(width, height);

		if (bitmap.__texture != null) resizeTexture(bitmap.__texture, width, height);
		else bitmap.getTexture(context3D);

		bitmap.__indexBufferContext = bitmap.__framebufferContext = bitmap.__textureContext;
		bitmap.__framebuffer = bitmap.__texture.__glFramebuffer;
		bitmap.__stencilBuffer = bitmap.__texture.__glStencilRenderbuffer;
		bitmap.__vertexBuffer = null;
		bitmap.getVertexBuffer(context3D);

		if (bitmap.__surface != null) bitmap.__surface.flush();
	}

	public static function resizeTexture(texture:TextureBase, width:Int, height:Int) @:privateAccess {
		if (texture.__alphaTexture != null) resizeTexture(texture.__alphaTexture, width, height);
		if (width < 1 || height < 1 || (texture.__width == width && texture.__height == height)) return;

		final context = texture.__context;
		final gl = context == null ? null : context.gl;
		if (gl == null) return;

		texture.__width = width = MathUtil.minInt(width, FlxG.bitmap.maxTextureSize);
		texture.__height = height = MathUtil.minInt(height, FlxG.bitmap.maxTextureSize);

		gl.bindTexture(gl.TEXTURE_2D, texture.__getTexture());
		gl.texImage2D(texture.__textureTarget, 0, texture.__internalFormat, width, height, 0, texture.__format, gl.UNSIGNED_BYTE, null);
		updateFramebuffer(texture);
		gl.bindTexture(gl.TEXTURE_2D, context.__contextState.__currentGLTexture2D);
	}
}
#end