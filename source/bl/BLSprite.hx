/*
	TODO: !!
	make flxanimate supportable

	chganged my mind, just rework flxanimate
*/

package bl;

import hxjson5.Json5;

import openfl.display.BlendMode;
import openfl.display.BitmapData;

import flixel.animation.FlxAnimationController;
import flixel.animation.FlxAnimation;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.math.FlxRect;
import flixel.util.typeLimit.*;
import flixel.util.FlxAxes;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;

import bl.util.ParseUtil;
import bl.object.BLAnimationController;

#if flixel_addons
import flixel.addons.effects.FlxSkewedSprite;
#end

#if flxanimate
import flxanimate.animate.FlxAnim;
import flxanimate.animate.FlxElement;
import flxanimate.frames.FlxAnimateFrames;
import flxanimate.FlxAnimate;
#end

using StringTools;

#if flxanimate
typedef BLGraphicAsset = OneOfFive<FlxAnimateFrames, FlxAtlasFrames, FlxGraphic, BitmapData, String>;
#else
typedef BLGraphicAsset = OneOfFour<FlxAtlasFrames, FlxGraphic, BitmapData, String>;
#end

typedef BLAnimData = {
	name:String,
	?id:String,
	?asset:BLGraphicAsset,
	?fps:Float, // it is optional but default is 30 from flixel animation codes
	?loop:Bool, // default is true
	?offset:Array<Float>,
	?indices:Array<Int>,
	?flipX:Bool,
	?flipY:Bool
}

typedef BLSpriteData = {
	image:String,
	?antialiasing:Bool,
	?animations:Array<BLAnimData>,
	?scrollFactor:OneOfTwo<Float, Array<Float>>,
	?zoomFactor:OneOfTwo<Float, Array<Float>>,
	?scale:OneOfTwo<Float, Array<Float>>,
	?offset:Array<Float>,
	?color:FlxColor,
	?blend:OneOfThree<String, Int, BlendMode>
}

@:access(flixel.animation.FlxAnimationController._animations)
class BLSprite extends #if flixel_addons FlxSkewedSprite #else FlxSprite #end {
	public static function getAnimData(asset:String, ?list:Array<String>, isWhitelist:Bool = false):Array<BLAnimData> {
		var data:Array<BLAnimData>;
		try {
			if (AssetUtil.textExists(asset)) data = cast Json5.parse(AssetUtil.getText(asset));
			else {
				if ((asset = asset.trim()).startsWith('[')) data = cast Json5.parse(asset);
				else throw 'No json file named "${asset}"';
			}
		}
		catch(e) {
			trace('Failed to parse JSON for Sprite Anims "${asset}" using empty array instead\nError: ${e.message}');
			return [];
		}

		if (list != null && list.length > 0)
			for (v in data) if (list.contains(v.name) != isWhitelist) data.remove(v);

		return data;
	}

	public static function fromData(data:BLSpriteData):BLSprite
		return new BLSprite().loadData(data);

	public var zoomFactor(default, null):FlxPoint;

	public var useFallbackOrigin:Bool = true;
	public var useFallbackOffset:Bool = true;
	public var sourceSize:Null<FlxPoint>; // flxanimate sets this once it loaded, otherwise its manual

	public var curAnimName(get, never):String; inline function get_curAnimName() return curAnim?.name #if flxanimate ?? curInstance?.symbol.name #end ?? '';
	public var fallbackAnimName(get, never):String; inline function get_fallbackAnimName() return fallbackAnim?.name #if flxanimate ?? fallbackInstance?.symbol.name #end ?? '';

	#if flxanimate
	public var flxAnimate:Null<FlxAnimate>;
	public var curInstance(get, never):Null<FlxElement>; inline function get_curInstance() return flxAnimate?.anim.curInstance;
	public var fallbackInstance:Null<FlxElement>;
	#end

	public var curAnim(get, never):Null<FlxAnimation>; inline function get_curAnim() return animation.curAnim;
	public var fallbackAnim(get, default):FlxAnimation;
	inline function get_fallbackAnim() {
		if (fallbackAnim != null && fallbackAnim.parent != animation) fallbackAnim = null;
		return fallbackAnim;
	}

	public var animationOffsets:Map<String, Array<Float>>;
	
	var _pendingAnimations:Map<String, BLAnimData>;
	var _currentAnimOffset:FlxPoint;
	var _tempScale:FlxPoint;
	var _tempPoint:FlxPoint;

	public function new(
		x = 0.0, y = 0.0, ?graphic:BLGraphicAsset, ?antialiasing:Bool, ?centerScreen:FlxAxes,
		?scale:Array<Float>, ?scalePoint:FlxPoint,
		?scrollFactor:Array<Float>, ?scrollFactorPoint:FlxPoint,
		?zoomFactor:Array<Float>, ?zoomFactorPoint:FlxPoint,
		?animArray:Array<BLAnimData>
	) {
		super(x, y);

		if (graphic != null) loadBLGraphic(graphic, animArray);
		if (antialiasing != null) this.antialiasing = antialiasing;

		if (scale != null) this.scale.set(scale[0], scale.length == 1 ? scale[0] : scale[1]);
		else if (scalePoint != null) this.scale.copyFrom(scalePoint);

		if (scrollFactor != null) this.scrollFactor.set(scrollFactor[0], scrollFactor.length == 1 ? scrollFactor[0] : scrollFactor[1]);
		else if (scrollFactorPoint != null) this.scrollFactor.copyFrom(scrollFactorPoint);

		if (zoomFactor != null) this.zoomFactor.set(zoomFactor[0], zoomFactor.length == 1 ? zoomFactor[0] : zoomFactor[1]);
		else if (zoomFactorPoint != null) this.zoomFactor.copyFrom(zoomFactorPoint);

		if (graphic != null) updateHitbox();

		if (centerScreen != null) {
			screenCenter(centerScreen);
			if (centerScreen.x) this.x = Math.floor(this.x) + x;
			if (centerScreen.y) this.y = Math.floor(this.y) + y;
		}
	}

	override function initVars() {
		super.initVars();

		animation.destroy();
		animation = new BLAnimationController(this);
		zoomFactor = FlxPoint.get(1, 1);
		animationOffsets = [];

		_pendingAnimations = [];
		_currentAnimOffset = FlxPoint.get();
		_tempScale = FlxPoint.get();
		_tempPoint = FlxPoint.get();
	}

	override function destroy() {
		super.destroy();
		zoomFactor = FlxDestroyUtil.put(zoomFactor);
		if (animationOffsets != null) animationOffsets.clear(); animationOffsets = null;
		if (_pendingAnimations != null) _pendingAnimations.clear(); _pendingAnimations = null;
		_currentAnimOffset = FlxDestroyUtil.put(_currentAnimOffset);
		_tempScale = FlxDestroyUtil.put(_tempScale);
		_tempPoint = FlxDestroyUtil.put(_tempPoint);
		#if flxanimate
		flxAnimate = FlxDestroyUtil.destroy(flxAnimate);
		#end
	}

	override function clone():BLSprite
		return (new BLSprite(x, y, antialiasing, scale, scrollFactor, zoomFactor)).loadGraphicFromSprite(this);

	override function loadGraphicFromSprite(sprite:FlxSprite):BLSprite {
		super.loadGraphicFromSprite(sprite);
		return this;
	}

	override function centerOrigin() {
		if (sourceSize != null) {
			origin.set(sourceSize.x * 0.5, sourceSize.y * 0.5);
			return;
		}
		final anim = fallbackAnim;
		if (useFallbackOrigin && anim != null && anim.frames.length > 0) {
			var size = frames.frames[anim.frames[0]].sourceSize;
			origin.set(size.x * 0.5, size.y * 0.5);
		}
		#if flxanimate
		else if (useFallbackOrigin && fallbackInstance != null)
			origin.copyFrom(fallbackInstance.symbol.transformationPoint);
		#end
		else
			origin.set(frameWidth * 0.5, frameHeight * 0.5);
	}

	override function updateHitbox() {
		#if flxanimate if (flxAnimate == null) #end @:privateAccess {
			//width = flxAnimate._flashRect.width;
			//height = flxAnimate._flashRect.height;
			width = Math.abs(scale.x) * frameWidth;
			height = Math.abs(scale.y) * frameHeight;
		}

		if (sourceSize != null)
			offset.set(-0.5 * (Math.abs(scale.x) * sourceSize.x - sourceSize.x), -0.5 * (Math.abs(scale.y) * sourceSize.y - sourceSize.y));
		else {
			final anim = fallbackAnim;
			if (useFallbackOffset && anim != null && anim.frames.length > 0) {
				var size = frames.frames[anim.frames[0]].sourceSize;
				offset.set(-0.5 * (Math.abs(scale.x) * size.x - size.x), -0.5 * (Math.abs(scale.y) * size.y - size.y));
			}
			else
				offset.set(-0.5 * (width - frameWidth), -0.5 * (height - frameHeight));
		}

		centerOrigin();
	}

	public function fixHitbox(centerOrigin = true) {
		#if flxanimate if (flxAnimate == null) #end @:privateAccess {
			//width = flxAnimate._flashRect.width;
			//height = flxAnimate._flashRect.height;
			width = Math.abs(scale.x) * frameWidth;
			height = Math.abs(scale.y) * frameHeight;
		}
		if (centerOrigin) this.centerOrigin();
	}

	inline public function centerHitbox() {
		fixHitbox();
		#if flxanimate
		if (useFallbackOffset && flxAnimate != null)
			offset.set(fallbackInstance.symbol.transformationPoint.x * scale.x, fallbackInstance.symbol.transformationPoint.y * scale.y);
		else
		#end
			offset.set(0.5 * width, 0.5 * height);
	}

	override function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):BLSprite {
		if (graphic is String) graphic = AssetUtil.getGraphic(cast graphic);
		return cast super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
	}

	public function loadData(data:BLSpriteData):BLSprite {
		loadBLGraphic(data.image, data.animations);
		antialiasing = data.antialiasing != null ? data.antialiasing : true;

		if (data.scrollFactor is Float) scrollFactor.set(data.scrollFactor, data.scrollFactor);
		else if (data.scrollFactor != null) scrollFactor.set(data.scrollFactor[0], cast(data.scrollFactor, Array<Dynamic>).length == 1 ? data.scrollFactor[0] : data.scrollFactor[1]);

		if (data.zoomFactor is Float) zoomFactor.set(data.zoomFactor, data.zoomFactor);
		else if (data.zoomFactor != null) zoomFactor.set(data.zoomFactor[0], cast(data.zoomFactor, Array<Dynamic>).length == 1 ? data.zoomFactor[0] : data.zoomFactor[1]);

		if (data.scale is Float) scale.set(data.scale, data.scale);
		else if (data.scale != null) scale.set(data.scale[0], cast(data.scale, Array<Dynamic>).length == 1 ? data.scale[0] : data.scale[1]);

		updateHitbox();

		if (data.offset != null) offset.set(data.offset[0], data.offset[1]);
		if (data.color != null) color = data.color;
		if (data.blend != null) blend = ParseUtil.parseBlendMode(data.blend);

		return this;
	}

	public function loadBLGraphic(graphic:BLGraphicAsset, ?animArray:Array<BLAnimData>):BLSprite {
		#if flxanimate
		if (graphic is FlxAnimateFrames) return loadAtlas(graphic, animArray);
		else
		#end
		if (graphic is FlxAtlasFrames || (animArray != null && animArray.length > 0)) return loadAnimGraphic(graphic, animArray);
		else if (graphic is String) {
			var path:String = graphic;
			var base = Paths.withoutExt(path);
			if (base == path) {
				var anims = '$base/anims.json';
				var animExists = AssetUtil.textExists(anims);

				if (AssetUtil.textExists(path = '$base/sprites.xml')) {
					if (animExists) return loadAnimGraphic(AssetUtil.getSparrowAtlas(path), getAnimData(anims));
					else return loadAnimGraphic(AssetUtil.getSparrowAtlas(path));
				}
				#if flxanimate
				else if (AssetUtil.textExists('$base/Animation.json')) {
					if (animExists) return loadAtlas(base, getAnimData(anims));
					else return loadAtlas(base);
				}
				#end
			}
			else {
				var anims = '$base-anims.json';
				if (AssetUtil.textExists('$base.xml')) {
					if (AssetUtil.textExists(anims)) return loadAnimGraphic(AssetUtil.getSparrowAtlas(path), getAnimData(anims));
					else return loadAnimGraphic(AssetUtil.getSparrowAtlas(path));
				}
			}
		}

		return loadGraphic(cast graphic);
	}

	public function makeSolidColor(width:Int, height:Int, color:FlxColor = FlxColor.WHITE):BLSprite {
		makeGraphic(1, 1, color);
		scale.set(width, height);
		updateHitbox();

		return this;
	}

	public function scaleToGame():BLSprite {
		var v = 1 / Math.min(width / FlxG.width, height / FlxG.height);
		scale.set(v, v); updateHitbox();

		return this;
	}

	#if flxanimate
	public function loadAtlas(graphic:BLGraphicAsset, ?animArray:Array<BLAnimData>):BLSprite @:privateAccess {
		var atlas:FlxAnimateFrames;

		if (graphic is BitmapData) throw "BitmapData is unsupported";
		else if (graphic is FlxAnimateFrames) atlas = graphic;
		else atlas = AssetUtil.getTextureAtlas(cast graphic);

		if (flxAnimate == null) initFlxAnimate();
		if (flxAnimate.frames == atlas) return this;

		final dir = graphic is String ? cast graphic : Paths.dir(atlas.parents[0].assetsKey);

		flxAnimate.frames = atlas;
		if (!AssetUtil.textExists('$dir/metadata.json')) flxAnimate.anim._loadAtlas(haxe.Json.parse(flxAnimate.atlasSetting(dir)));
		else flxAnimate.anim._loadExAtlas(dir);

		if (animArray != null) {
			addAnims(animArray);
			if (curInstance == null) playAnim(animArray[0].name, true);
		}

		_matrix.setTo(1, 0, 0, 1, -10000, -10000);
		flxAnimate.scale.set(1, 1);
		flxAnimate._flashRect.setEmpty();
		flxAnimate.parseElement(flxAnimate.anim.curInstance, _matrix, colorTransform, scrollFactor);
		sourceSize = FlxPoint.get(flxAnimate._flashRect.width, flxAnimate._flashRect.height);

		return this;
	}
	#end

	public function loadAnimGraphic(graphic:BLGraphicAsset, ?animArray:Array<BLAnimData>, preloadMulti = false):BLSprite {
		var newFrames:FlxAtlasFrames;

		if (graphic is BitmapData) throw "BitmapData is unsupported";
		else if (graphic is FlxAtlasFrames) newFrames = graphic;
		else newFrames = AssetUtil.getSparrowAtlas(cast graphic);
		if (newFrames == frames) return this;

		frames = newFrames;
		if (animArray != null) {
			addAnims(animArray, preloadMulti);
			if (fallbackAnim != null) playAnim(fallbackAnim.name, true);
		}
		return this;
	}
	
	public function addAnims(animArray:Array<BLAnimData>, preloadMulti = false):BLSprite {
		for (i in 0...animArray.length) addAnim(animArray[i], preloadMulti);
		return this;
	}

	public function addAnim(anim:BLAnimData, preloadMulti = false):BLSprite {
		// implement multi atlas in flxAnimate???
		if (anim.asset != null) {
			if (preloadMulti || !(anim.asset is String)) {
				if (frames == null) throw "Cannot push multiple assets into non-existing frames";
				else if (!(frames is FlxAtlasFrames)) throw "TODO, fix this like idk make it so its a FlxAtlasFrames?";
				var multiFrames:FlxAtlasFrames;

				if (anim.asset is BitmapData) throw "BitmapData is unsupported";
				else if (anim.asset is FlxAtlasFrames) multiFrames = anim.asset;
				else multiFrames = AssetUtil.getSparrowAtlas(cast anim.asset);

				cast(frames, FlxAtlasFrames).addAtlas(multiFrames);
				if (_pendingAnimations.exists(anim.name)) _pendingAnimations.remove(anim.name);
			}
			else {
				_pendingAnimations.set(anim.name, anim);
				return this;
			}
		}

		#if flxanimate
		if (flxAnimate != null) @:privateAccess {
			if (anim.id == null && anim.indices != null)
				flxAnimate.anim.addBySymbolIndices(anim.name, flxAnimate.anim.stageInstance.symbol.name,
					anim.indices, anim.fps, anim.loop);
			else if (anim.indices != null)
				flxAnimate.anim.addBySymbolIndices(anim.name, anim.id,
					anim.indices, anim.fps, anim.loop);
			else
				flxAnimate.anim.addBySymbol(anim.name, anim.id, anim.fps, anim.loop);

			final instance = flxAnimate.anim.animsMap.get(anim.name)?.instance;
			if (instance != null) {
				if (anim.flipX) instance.matrix.a *= -1;
				if (anim.flipY) instance.matrix.d *= -1;
				if (fallbackInstance == null) fallbackInstance = instance;
			}
		}
		#end

		if (frames != null) {
			if (anim.id == null && anim.indices != null) animation.add(anim.name, anim.indices, anim.fps, anim.loop, anim.flipX, anim.flipY);
			else if (anim.indices != null) animation.addByIndices(anim.name, anim.id, anim.indices, "", anim.fps, anim.loop, anim.flipX, anim.flipY);
			else animation.addByPrefix(anim.name, anim.id ?? anim.name, anim.fps, anim.loop, anim.flipX, anim.flipY);

			if (fallbackAnim == null) fallbackAnim = animation.getByName(anim.name);
		}

		if (anim.offset != null) animationOffsets.set(anim.name, anim.offset);

		return this;
	}

	public function loadPendingAnimations()
		for (anim in _pendingAnimations.keys()) addAnim(_pendingAnimations.get(anim), true);

	public function playAnim(name:String, ?fallback:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):BLSprite {
		if (_pendingAnimations.exists(name)) {
			addAnim(_pendingAnimations.get(name), true);
			return playAnim(name, fallback, force, reversed, frame);
		}

		if (!hasAnim(name)) {
			FlxG.log.warn('No animation named "' + name + '"');
			if (fallback != null) return playAnim(fallback, force, reversed, frame);
			else if (fallbackAnim != null && name != fallbackAnim.name) return playAnim(fallbackAnim.name, force, reversed, frame);
			return this;
		}

		#if flxanimate
		if (flxAnimate != null) flxAnimate.anim.play(name, force, reversed, frame);
		else
		#end
		animation.play(name, force, reversed, frame);
		fixHitbox();

		var animOffsets = animationOffsets.get(name);
		if (animOffsets != null) _currentAnimOffset.set(animOffsets[0] ?? 0, animOffsets[1] ?? 0);
		else _currentAnimOffset.set(0, 0);

		return this;
	}

	public function restartAnim() {
		#if flxanimate
		if (flxAnimate != null) flxAnimate.anim.playElement(curInstance, true, flxAnimate.anim.reversed);
		else
		#end
		curAnim.restart();
	}

	public function renameAnim(name:String, to:String):BLSprite {
		if (animationOffsets.exists(name)) {
			var offset:Array<Float> = animationOffsets[name];
			animationOffsets.remove(name);
			animationOffsets.set(to, offset);
		}

		#if flxanimate
		if (flxAnimate != null) @:privateAccess {
			final sym = flxAnimate.anim.getByName(name);
			if (sym == null) {
				FlxG.log.warn('No animation named "$name"');
				return this;
			}

			flxAnimate.anim.animsMap.remove(name);
			flxAnimate.anim.animsMap.set(to, sym);

			return this;
		}
		#end

		if (animation._animations == null) return this;

		final anim:FlxAnimation = animation.getByName(name);
		if (anim == null) {
			FlxG.log.warn('No animation named "$name"');
			return this;
		}
		//if (hasAnim(to)) removeAnim(to);

		anim.name = to;
		animation._animations.remove(name);
		animation._animations.set(to, anim);

		return this;
	}

	public function removeAnim(name:String):BLSprite {
		animationOffsets.remove(name);

		#if flxanimate
		if (flxAnimate != null) @:privateAccess {
			flxAnimate.anim.animsMap.remove(name);
			return this;
		}
		#end
		if (animation._animations == null) return this;

		var anim:FlxAnimation = animation.getByName(name);
		if (anim == null) {
			FlxG.log.warn('No animation named "' + name + '"');
			return this;
		}

		animation._animations.remove(name);

		//anim.destroy();
		return this;
	}

	override function set_frames(Frames:FlxFramesCollection):FlxFramesCollection {
		if (Frames == frames) return super.set_frames(Frames);
		animationOffsets.clear();
		_pendingAnimations.clear();
		fallbackAnim = null;
		sourceSize = null;
		#if flxanimate
		fallbackInstance = null;
		#end
		return super.set_frames(Frames);
	}

	public function hasAnim(name:String):Bool {
		if (_pendingAnimations.exists(name)) return true;
		#if flxanimate
		else if (flxAnimate != null) return flxAnimate.anim.existsByName(name);
		#end
		else return animation.getByName(name) != null;
	}

	public function hasFrames(prefix:String):Bool {
		#if flxanimate
		if (flxAnimate != null) @:privateAccess {
			if (flxAnimate.anim.symbolDictionary == null) return false;
			for (name => _ in flxAnimate.anim.symbolDictionary) if (flxAnimate.anim.startsWith(name, prefix)) return true;
			return false;
		}
		#end
		var frames = [];
		@:privateAccess animation.findByPrefix(frames, prefix);
		return frames.length != 0;
	}

	function correctAnimName(name:String, fallback:String = 'idle'):String {
		if (hasAnim(name)) return name;

		var idx = name.lastIndexOf('-');
		return if (idx != -1) correctAnimName(name.substr(0, idx), fallback);
			else if (fallback != null && fallback != name) fallback;
			else null;
	}

	public function isSimpleZoomFactor():Bool return FlxMath.equal(1, zoomFactor.x) && FlxMath.equal(1, zoomFactor.y);

	override function isSimpleRender(?camera:FlxCamera):Bool {
		if (FlxG.renderTile) return false;
		return isSimpleZoomFactor() && isSimpleRenderBlit(camera);
	}

	@:noCompletion
	override function drawComplex(camera:FlxCamera) {
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0) {
			updateTrig();
			if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		getScreenPosition(_point, camera).subtract(offset);
		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (!isSimpleZoomFactor()) {
			_matrix.translate(-0.5 * camera.width, -0.5 * camera.height);
			_matrix.scale(FlxMath.lerp(1, camera.scaleX, zoomFactor.x) / camera.scaleX, FlxMath.lerp(1, camera.scaleY, zoomFactor.y) / camera.scaleY);
			_matrix.translate(0.5 * camera.width, 0.5 * camera.height);
		}

		if (isPixelPerfectRender(camera)) {
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}

		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}

	#if flxanimate
	function initFlxAnimate() {
		flxAnimate = new FlxAnimate();
	}

	override function updateAnimation(elapsed:Float) {
		if (flxAnimate != null) flxAnimate.anim.update(elapsed);
		else super.updateAnimation(elapsed);
	}

	override function draw() {
		if (flxAnimate != null) drawFlxAnimate();
		else super.draw();
	}

	function drawFlxAnimate() @:privateAccess {
		if (alpha <= 0) return;

		flxAnimate.setPosition(x, y);
		flxAnimate.origin = origin;
		flxAnimate.offset = offset;
		flxAnimate.scale = scale;
		flxAnimate.angle = angle;
		flxAnimate.shader = shader;

		_matrix.setTo(checkFlipX() ? -1 : 1, 0, 0, checkFlipY() ? -1 : 1, 0, 0);

		flxAnimate._flashRect.setEmpty();
		flxAnimate.parseElement(flxAnimate.anim.curInstance, _matrix, colorTransform, cameras, scrollFactor);

		width = flxAnimate._flashRect.width;
		height = flxAnimate._flashRect.height;
		frameWidth = Math.round(width);
		frameHeight = Math.round(height);

		flxAnimate.relativeX = flxAnimate._flashRect.x - x;
		flxAnimate.relativeY = flxAnimate._flashRect.y - y;
	}
	#end

	private function getSourceSizeX():Float {
		if (sourceSize != null) return sourceSize.x;

		final anim = fallbackAnim;
		if (anim != null && anim.frames.length > 0) return frames.frames[anim.frames[0]].sourceSize.x;

		return frameWidth;
	}

	private function getSourceSizeY():Float {
		if (sourceSize != null) return sourceSize.y;

		final anim = fallbackAnim;
		if (anim != null && anim.frames.length > 0) return frames.frames[anim.frames[0]].sourceSize.y;

		return frameHeight;
	}

	private function preZoomFactorProcedure(camera:FlxCamera) {
		_tempPoint = scale;
		(scale = _tempScale).copyFrom(_tempPoint).scale(
			FlxMath.lerp(1, camera.scaleX, zoomFactor.x) / camera.scaleX,
			FlxMath.lerp(1, camera.scaleY, zoomFactor.y) / camera.scaleY
		);
		_tempScale = _tempPoint;
	}

	private function postZoomFactorProcedure(camera:FlxCamera) {
		_tempPoint = scale;
		scale = _tempScale;
		_tempScale = _tempPoint;
	}

	private function getRealScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint {
		if (result == null) result = FlxPoint.get();
		if (camera == null) camera = getDefaultCamera();

		result.set(x, y);
		if (pixelPerfectPosition) result.floor();
		return result.subtract(
			camera.scroll.x * scrollFactor.x * (camera.scaleX / FlxMath.lerp(1, camera.scaleX, zoomFactor.x)),
			camera.scroll.y * scrollFactor.y * (camera.scaleY / FlxMath.lerp(1, camera.scaleY, zoomFactor.y))
		);
	}

	override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint {
		final x = -_currentAnimOffset.x - (frameWidth - getSourceSizeX()) * Math.min(_facingHorizontalMult, 0),
			y = -_currentAnimOffset.y - (frameHeight - getSourceSizeY()) * Math.min(_facingVerticalMult, 0);
		if (x == 0 && y == 0) return getRealScreenPosition(result, camera);

		final sx = scale.x * _facingHorizontalMult, sy = scale.y * _facingVerticalMult;
		return getRealScreenPosition(result, camera).add(x * _cosAngle * sx - y * _sinAngle * sy, y * _cosAngle * sy + x * _sinAngle * sx);
	}

	override function getRotatedBounds(?newRect:FlxRect):FlxRect {
		final sx = scale.x * _facingHorizontalMult, sy = scale.y * _facingVerticalMult,
			x = -_currentAnimOffset.x - (frameWidth - getSourceSizeX()) * Math.min(_facingHorizontalMult, 0),
			y = -_currentAnimOffset.y - (frameHeight - getSourceSizeY()) * Math.min(_facingVerticalMult, 0);

		return super.getRotatedBounds(newRect).offset(x * _cosAngle * sx - y * _sinAngle * sy, y * _cosAngle * sy + x * _sinAngle * sx);
	}

	override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect {
		final x = -_currentAnimOffset.x - (frameWidth - getSourceSizeX()) * Math.min(_facingHorizontalMult, 0),
			y = -_currentAnimOffset.y - (frameHeight - getSourceSizeY()) * Math.min(_facingVerticalMult, 0);
		if (x == 0 && y == 0) return super.getScreenBounds(newRect, camera);

		final sx = scale.x * _facingHorizontalMult, sy = scale.y * _facingVerticalMult;
		preZoomFactorProcedure(camera);
		newRect = super.getScreenBounds(newRect, camera).offset(x * _cosAngle * sx - y * _sinAngle * sy, y * _cosAngle * sy + x * _sinAngle * sx);
		postZoomFactorProcedure(camera);
		return if (isPixelPerfectRender(camera)) newRect.floor() else newRect;
	}
}