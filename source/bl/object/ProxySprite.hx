package bl.object;

import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.math.FlxRect;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;

@:access(flixel.FlxSprite)
class ProxySprite extends FlxSprite {
	public var proxiedSprite:FlxSprite;

	public function new(x = 0.0, y = 0.0, ?sprite:FlxSprite) {
		super(x, y);
		proxiedSprite = sprite;
	}

	override public function updateHitbox() {
		width = proxiedSprite.width * Math.abs(scale.x);
		height = proxiedSprite.height * Math.abs(scale.y);
	}

	override function checkEmptyFrame() {}

	override function draw() {
		if (alpha == 0 || proxiedSprite == null) return;

		proxiedSprite.checkEmptyFrame();
		//if (proxiedSprite._frame.type == FlxFrameType.EMPTY) return;
		//if (proxiedSprite.dirty) proxiedSprite.calcFrame(proxiedSprite.useFramePixels);

		final px = proxiedSprite.x, py = proxiedSprite.y, pa = proxiedSprite.angle, pca = proxiedSprite._cameras;
		final pox = proxiedSprite.origin.x, poy = proxiedSprite.origin.y;
		final pfx = proxiedSprite.offset.x, pfy = proxiedSprite.offset.y;
		final psx = proxiedSprite.scale.x, psy = proxiedSprite.scale.y;
		final pb = proxiedSprite.blend, pc = proxiedSprite.colorTransform, ps = proxiedSprite.shader;

		proxiedSprite.setPosition(x, y);
		proxiedSprite.origin.add(origin.x, origin.y);
		proxiedSprite.offset.add(offset.x, offset.y);
		proxiedSprite.scale.scale(scale.x, scale.y);
		proxiedSprite.angle += angle;
		proxiedSprite.blend = blend;
		proxiedSprite.colorTransform = colorTransform;
		proxiedSprite.shader = shader;

		proxiedSprite._cameras = _cameras;
		proxiedSprite.draw();
		proxiedSprite._cameras = pca;
		/*for (camera in getCamerasLegacy()) {
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;

			if (isSimpleRender(camera)) proxiedSprite.drawSimple(camera);
			else proxiedSprite.drawComplex(camera);

			#if FLX_DEBUG FlxBasic.visibleCount++; #end
		}*/

		proxiedSprite.setPosition(px, py);
		proxiedSprite.origin.set(pox, poy);
		proxiedSprite.offset.set(pfx, pfy);
		proxiedSprite.scale.set(psx, psy);
		proxiedSprite.angle = pa;
		proxiedSprite.blend = pb;
		proxiedSprite.colorTransform = pc;
		proxiedSprite.shader = ps;

		#if FLX_DEBUG if (FlxG.debugger.drawDebug) drawDebug(); #end
	}

	override function drawSimple(camera:FlxCamera) {
		final px = proxiedSprite.x, py = proxiedSprite.y, pa = proxiedSprite.angle;
		final pox = proxiedSprite.origin.x, poy = proxiedSprite.origin.y;
		final pfx = proxiedSprite.offset.x, pfy = proxiedSprite.offset.y;
		final psx = proxiedSprite.scale.x, psy = proxiedSprite.scale.y;
		final pb = proxiedSprite.blend, pc = proxiedSprite.colorTransform, ps = proxiedSprite.shader;

		proxiedSprite.setPosition(x, y);
		proxiedSprite.origin.add(origin.x, origin.y);
		proxiedSprite.offset.add(offset.x, offset.y);
		proxiedSprite.scale.scale(scale.x, scale.y);
		proxiedSprite.angle += angle;
		proxiedSprite.blend = blend;
		proxiedSprite.colorTransform = colorTransform;
		proxiedSprite.shader = shader;

		proxiedSprite.drawSimple(camera);

		proxiedSprite.setPosition(px, py);
		proxiedSprite.origin.set(pox, poy);
		proxiedSprite.offset.set(pfx, pfy);
		proxiedSprite.scale.set(psx, psy);
		proxiedSprite.angle = pa;
		proxiedSprite.blend = pb;
		proxiedSprite.colorTransform = pc;
		proxiedSprite.shader = ps;
	}

	override function drawComplex(camera:FlxCamera) {
		final px = proxiedSprite.x, py = proxiedSprite.y, pa = proxiedSprite.angle;
		final pox = proxiedSprite.origin.x, poy = proxiedSprite.origin.y;
		final pfx = proxiedSprite.offset.x, pfy = proxiedSprite.offset.y;
		final psx = proxiedSprite.scale.x, psy = proxiedSprite.scale.y;
		final pb = proxiedSprite.blend, pc = proxiedSprite.colorTransform, ps = proxiedSprite.shader;

		proxiedSprite.setPosition(x, y);
		proxiedSprite.origin.add(origin.x, origin.y);
		proxiedSprite.offset.add(offset.x, offset.y);
		proxiedSprite.scale.scale(scale.x, scale.y);
		proxiedSprite.angle += angle;
		proxiedSprite.blend = blend;
		proxiedSprite.colorTransform = colorTransform;
		proxiedSprite.shader = shader;

		proxiedSprite.drawComplex(camera);

		proxiedSprite.setPosition(px, py);
		proxiedSprite.origin.set(pox, poy);
		proxiedSprite.offset.set(pfx, pfy);
		proxiedSprite.scale.set(psx, psy);
		proxiedSprite.angle = pa;
		proxiedSprite.blend = pb;
		proxiedSprite.colorTransform = pc;
		proxiedSprite.shader = ps;
	}

	override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint {
		if (proxiedSprite == null) return super.getScreenPosition(result, camera);
		else return proxiedSprite.getScreenPosition(result, camera).add(-proxiedSprite.x + x + offset.x, -proxiedSprite.y + y + offset.y);
	}

	override function getRotatedBounds(?newRect:FlxRect):FlxRect {
		if (proxiedSprite == null) return super.getRotatedBounds(newRect);
		else return proxiedSprite.getRotatedBounds(newRect).offset(-proxiedSprite.x + x + offset.x, -proxiedSprite.y + y + offset.y);
	}

	override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect {
		if (proxiedSprite == null) return super.getScreenBounds(newRect, camera);
		else return proxiedSprite.getScreenBounds(newRect, camera).offset(-proxiedSprite.x + x + offset.x, -proxiedSprite.y + y + offset.y);
	}
}