package bl.object;

import openfl.display.BlendMode;
import openfl.display3D.Context3DCompareMode;
import openfl.geom.Matrix3D;

import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;

import bl.graphic.shader.Graphics3DShader;

// if you are looking for Sprite3D... just use this and proxy your 2d sprite.
// it doesnt do depth test though...
@:access(flixel.FlxSprite)
class ProxySprite3D extends Object3D {
	public var proxiedSprite:FlxSprite;
	public var shader:FlxShader = new Graphics3DShader();

	var _matrix3D:Matrix3D;
	var _camera:Array<FlxCamera> = [];

	public function new(x = 0.0, y = 0.0, ?sprite:FlxSprite) {
		super(x, y);
		proxiedSprite = sprite;
	}

	override function initVars() {
		super.initVars();
		_matrix3D = new Matrix3D();
	}

	override function destroy() {
		super.destroy();
		_matrix3D = null;
		_camera = null;
	}

	public function updateHitbox() {
		width = proxiedSprite.width * Math.abs(scale.x);
		height = proxiedSprite.height * Math.abs(scale.y);
	}

	override function draw() {
		if (alpha == 0 || proxiedSprite == null) return;

		proxiedSprite.checkEmptyFrame();
		//if (proxiedSprite._frame.type == FlxFrameType.EMPTY) return;
		//if (proxiedSprite.dirty) proxiedSprite.calcFrame(proxiedSprite.useFramePixels);

		final px = proxiedSprite.x, py = proxiedSprite.y, pscx = proxiedSprite.scrollFactor.x, pscy = proxiedSprite.scrollFactor.y, pa = proxiedSprite.angle;
		final pb = proxiedSprite.blend, pc = proxiedSprite.colorTransform, ps = proxiedSprite.shader, pca = proxiedSprite._cameras;

		proxiedSprite.setPosition(0, 0);
		proxiedSprite.scrollFactor.set(0, 0);
		proxiedSprite.angle += angle;
		proxiedSprite.blend = blend;
		proxiedSprite.colorTransform = colorTransform;
		proxiedSprite.shader = shader;

		final screenPos = proxiedSprite.getScreenPosition(FlxPoint.weak());
		Object3D.composeMatrix3D(getPosition3D(true).subtractVector3(offset), rotation, getScale3D(true), rotationOrder,
			Vector3.weak(origin.x + proxiedSprite.origin.x + screenPos.x, origin.y + proxiedSprite.origin.y + screenPos.y, origin.z), _matrix3D, false);
		Object3D.setModelMatrix(shader, _matrix3D);
		screenPos.putWeak();

		proxiedSprite._cameras = _camera;
		for (camera in getCamerasLegacy()) {
			if (!camera.visible || !camera.exists) continue;

			getPerspective(camera).applyShaderParameters(shader);

			_camera[0] = camera;
			//camera.canvas?.graphics.overrideDepthTest(true, LESS_EQUAL);
			proxiedSprite.draw();

			#if FLX_DEBUG FlxBasic.visibleCount++; #end
		}
		proxiedSprite._cameras = pca;

		proxiedSprite.setPosition(px, py);
		proxiedSprite.scrollFactor.set(pscx, pscy);
		proxiedSprite.angle = pa;
		proxiedSprite.blend = pb;
		proxiedSprite.colorTransform = pc;
		proxiedSprite.shader = ps;
	}
}