package blossom.util;

import openfl.display.IBitmapDrawable;
import openfl.display.OpenGLRenderer;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.geom.Rectangle;

import blossom.util.MathUtil;

final class BitmapDataUtil {
	public static var context3D(get, never):Context3D; inline static function get_context3D():Context3D return FlxG.stage.context3D;

	inline static function __flush() @:privateAccess {
		context3D.__flushGLFramebuffer();
		context3D.__flushGLViewport();
	}

	public static function create(width:Int, height:Int, format:Context3DTextureFormat = BGRA):BitmapData @:privateAccess {
		width = MathUtil.minInt(width, FlxG.bitmap.maxTextureSize);
		height = MathUtil.minInt(height, FlxG.bitmap.maxTextureSize);

		if (context3D == null) return new BitmapData(width, height, true, 0);
		else {
			final bitmap = new BitmapData(0, 0, true, 0);
			(bitmap.__texture = context3D.createTexture(width, height, format, true)).__getGLFramebuffer(true, 0, 0);
			bitmap.__textureContext = context3D.__context;
			bitmap.__resize(width, height);
			bitmap.__isValid = true;
			return bitmap;
		}
	}

	public static function toHardware(bitmap:BitmapData) @:privateAccess {
		if (context3D == null || bitmap.image == null) return;

		#if openfl_power_of_two bitmap.image.powerOfTwo = true; #end
		bitmap.image.premultiplied = true;

		if (bitmap.__texture == null) bitmap.__texture = context3D.createTexture(bitmap.width, bitmap.height, BGRA, true);
		bitmap.__textureContext = context3D.__context;
		bitmap.getTexture(context3D);
		bitmap.readable = false;
		bitmap.image.data = null;
		bitmap.image = null;
	}

	public static function hardwareCheck(bitmap:BitmapData, strict = false):Bool @:privateAccess 
		return bitmap?.__texture != null && (!strict || (bitmap.image == null || bitmap.__textureVersion >= bitmap.image.version));

	public static function clear(bitmap:BitmapData, color = 0, depth = false, stencil = false) @:privateAccess {
		if (bitmap.__texture != null) clearTexture(bitmap.__texture, color, depth, stencil);
		else bitmap.__fillRect(bitmap.rect, color, false);
	}

	public static function clearTexture(texture:TextureBase, color:FlxColor, depth:Bool, stencil:Bool) @:privateAccess {
		if (texture.__glFramebuffer == null) return;
		__flush();

		final context = texture.__context;
		final gl = context.gl;

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

		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
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
		if (texture.__glFramebuffer == null || texture.__width == width && texture.__height == height) return;

		final context = texture.__context;
		final gl = context.gl;

		texture.__width = width = MathUtil.minInt(width, FlxG.bitmap.maxTextureSize);
		texture.__height = height = MathUtil.minInt(height, FlxG.bitmap.maxTextureSize);

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

			texture.__getGLFramebuffer(false, 0, 0);
		}

		if (cacheRTT != null) context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		else context.setRenderToBackBuffer();
	}
}