package funkin.stage;

import openfl.display.BlendMode;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import bl.graphic.shader.AdjustColorShader;

class LimoRideErectStage extends Stage {
	public static var classStageID:String = 'limoRideErect';
	public static var classStageName:String = 'Limo Ride [Erect]';

	public static function preload()
		return CoolUtil.chainFutures([
			AssetUtil.loadSparrowAtlas(Paths.image('limo/erect/bgLimo', 'week4')),
			AssetUtil.loadSparrowAtlas(Paths.image('limo/fastCarLol', 'week4')),
			AssetUtil.loadSparrowAtlas(Paths.image('limo/henchmen', 'week4')),
			AssetUtil.loadSparrowAtlas(Paths.image('limo/henchhit', 'week4')),
			AssetUtil.loadSparrowAtlas(Paths.image('limo/erect/limo', 'week4')),
			AssetUtil.loadSparrowAtlas(Paths.image('limo/erect/limoSunset', 'week4')),
			AssetUtil.loadSparrowAtlas(Paths.image('limo/erect/shootingstar', 'week4')),
			AssetUtil.loadGraphic(Paths.image('limo/limoOverlay', 'week4')),
			AssetUtil.loadGraphic(Paths.image('limo/metalPole', 'week4')),
			AssetUtil.loadGraphic(Paths.image('limo/lightbulb', 'week4')),
			AssetUtil.loadGraphic(Paths.image('limo/erect/mist', 'week4')),
			AssetUtil.loadSound(Paths.sound('carPass0', 'week4')),
			AssetUtil.loadSound(Paths.sound('carPass1', 'week4')),
			AssetUtil.loadSound(Paths.sound('dancerdeath', 'week4'))
		]);

	public var nightValue:Null<Float>;
	public var nightMin:Float = 0;
	public var nightMax:Float = 1;

	var colorShader:AdjustColorShader;
	var sunOverlay:BLSprite;
	var bg:BLSprite;
	var bgLimo:BLSprite;
	var limo:BLSprite;
	var fastCar:BLSprite;
	var shootingStar:BLSprite;
	var mens:Array<BLSprite> = [];
	var bodiesBack:FlxTypedGroup<BLSprite>;
	var bodiesFront:FlxTypedGroup<BLSprite>;
	var pole:BLSprite;
	var bulb:BLSprite;
	var mist1:FlxBackdrop;
	var mist2:FlxBackdrop;
	var mist3:FlxBackdrop;
	var mist4:FlxBackdrop;
	var mist5:FlxBackdrop;
	var timer:Float;

	var shootingStarBeat:Int = 0;
	var shootingStarOffset:Int = 2;
	var fastCarCanDrive:Bool = false;
	var poleTimer:Float;
	var canKill:Bool = false;

	override function resetStage() {
		super.resetStage();

		characterPositions.set(BF, {
			x: 1218, y: 542,
			camX: -230, camY: 0
		});
		characterPositions.set(DAD, {
			x: 270, y: 818,
			camX: 0, camY: -20,
			flipX: true
		});
		characterPositions.set(GF, {
			x: 750, y: 765,
			camX: 80, camY: -140,
			scroll: 0.95,
			layer: -1
		});

		defaultZoom = 0.9;
		centerPosition.set(780, 400);
	}

	override function create() {
		super.create();

		if (playState != null) {
			conductor.onBeatHit.add(beatHit);
			playState.camGame.addShader(colorShader = new AdjustColorShader());
		}
		else
			cast(camera, BLCamera).addShader(colorShader = new AdjustColorShader());

		colorShader.hue.value = [-30];
		colorShader.saturation.value = [-20];
		colorShader.contrast.value = [0];
		colorShader.brightness.value = [-30];

		add(bg = new BLSprite(-220, -80, Paths.image('limo/erect/limoSunset', 'week4'), [0.9 * (2088 / 1024)], [0.1], [0.25]));
		bg.color = 0xFFEDFB;

		add(mist5 = new FlxBackdrop(Paths.image('limo/erect/mist', 'week4'), X));
		mist5.setPosition(-650, -200 + 320);
		mist5.scrollFactor.set(0.2, 0.2);
		mist5.blend = ADD;
		mist5.color = 0xE7A480;
		mist5.alpha = 1;
		mist5.velocity.set(100, 0);
		mist5.scale.set(1 / 0.25, 1 / 0.25); mist5.updateHitbox();
		mist5.scale.set(1.65 / 0.25 / 0.825, 1.65 / 0.25 / 0.825);
		//mist5.visible = false;

		add(shootingStar = new BLSprite(Paths.image('limo/erect/shootingstar', 'week4'), [1], [0.12], [
			{loop: false, name: 'shooting star', 'id': 'shooting star', fps: 24}
		]));
		shootingStar.blend = ADD;
		shootingStar.visible = false;

		poleTimer = timer + FlxG.random.float(13, 20);
		add(pole = new BLSprite(-10000, 140, Paths.image('limo/metalPole', 'week4'), [1.0], [0.4]));
		pole.moves = true;

		add(bodiesBack = new FlxTypedGroup<BLSprite>());

		add(bgLimo = new BLSprite(-200, 480, Paths.image('limo/erect/bgLimo', 'week4'), [1.0], [0.4], [
			{name: 'drive', id: 'background limo blue', loop: true, fps: 24}
		]));

		for (i in 0...5) {
			mens.push(cast add(new BLSprite(Paths.image('limo/henchmen', 'week4'), [1], [0.4], [
				{name: 'danceLeft', id: 'bg dancer sketch PINK', loop: false, fps: 24, indices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]},
				{name: 'danceRight', id: 'bg dancer sketch PINK', loop: false, fps: 24, indices: [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]}
			])));
		}

		add(bodiesFront = new FlxTypedGroup<BLSprite>());
		add(bulb = new BLSprite(-10000, 140, Paths.image('limo/lightbulb', 'week4'), [1.0], [0.4]));

		add(mist4 = new FlxBackdrop(Paths.image('limo/erect/mist', 'week4'), X));
		mist4.setPosition(-650, -180 + 320);
		mist4.scrollFactor.set(0.6, 0.6);
		mist4.blend = ADD;
		mist4.color = 0x9C77C7;
		mist4.alpha = 1;
		mist4.velocity.set(700, 0);
		mist4.scale.set(1 / 0.25, 1 / 0.25); mist4.updateHitbox();
		mist4.scale.set(1.5 / 0.25 / 0.825, 1.5 / 0.25 / 0.825);
		//mist4.visible = false;

		add(mist3 = new FlxBackdrop(Paths.image('limo/erect/mist', 'week4'), X));
		mist3.setPosition(-650, -20 + 320);
		mist3.scrollFactor.set(0.8, 0.8);
		mist3.blend = ADD;
		mist3.color = 0xA7D9BE;
		mist3.alpha = 0.5;
		mist3.velocity.set(900, 0);
		mist3.scale.set(1 / 0.25, 1 / 0.25); mist4.updateHitbox();
		mist3.scale.set(1.5 / 0.25 / 0.825, 1.5 / 0.25 / 0.825);
		//mist3.visible = false;

		add(limo = new BLSprite(-120, 520, Paths.image('limo/erect/limo', 'week4'), [
			{name: 'drive', id: 'Limo stage', loop: true, fps: 24}
		]));

		foreground.add(fastCar = new BLSprite(Paths.image('limo/fastCarLol', 'week4')));
		fastCar.moves = true;
		resetFastCar();

		foreground.add(mist1 = new FlxBackdrop(Paths.image('limo/erect/mist', 'week4'), X));
		mist1.setPosition(-650, 100 + 320);
		mist1.scrollFactor.set(1.1, 1.1);
		mist1.blend = ADD;
		mist1.color = 0xC6BFDE;
		mist1.alpha = 0.4;
		mist1.velocity.set(1700, 0);
		mist1.scale.set(1 / 0.25, 1 / 0.25); mist1.updateHitbox();
		mist1.scale.set(1 / 0.25 / 0.825, 1 / 0.25 / 0.825);
		//mist1.visible = false;

		foreground.add(mist2 = new FlxBackdrop(Paths.image('limo/erect/mist', 'week4'), X));
		mist2.setPosition(-650, 0 + 320);
		mist2.scrollFactor.set(1.2, 1.2);
		mist2.blend = ADD;
		mist2.color = 0x6A4DA1;
		mist2.alpha = 1;
		mist2.velocity.set(2100, 0);
		mist2.scale.set(1 / 0.25, 1 / 0.25); mist2.updateHitbox();
		mist2.scale.set(1.3 / 0.25 / 0.825, 1.3 / 0.25 / 0.825);
		//mist2.visible = false;

		mist1.moves = mist2.moves = mist3.moves = mist4.moves = mist5.moves = true;

		// unused sunOverlay in vanilla codes. recreated?
		foreground.add(sunOverlay = new BLSprite(-228, -90, Paths.image('limo/limoOverlay', 'week4'), [0.6 / 0.1], [0.1], [0.25]));
		sunOverlay.blend = OVERLAY;
	}

	override function destroy() {
		super.destroy();
		conductor?.onBeatHit.remove(beatHit);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		final inPlay = playState != null;

		timer += elapsed;
		mist1.y = 100 + 320 + (FlxMath.fastCos(timer)*200);
		mist2.y = 0 + 320 + (FlxMath.fastCos(timer*0.8)*100);
		mist3.y = -20 + 320 + (FlxMath.fastCos(timer*0.5)*200);
		mist4.y = -180 + 320 + (FlxMath.fastCos(timer*0.4)*300);
		mist5.y = -200 + 320 + (FlxMath.fastCos(timer*0.2)*100);

		bulb.setPosition(pole.x - 70, pole.y - 14);

		var x = bgLimo.x + 300, y = bgLimo.y - 380;
		for (i => men in mens) {
			if (canKill && inPlay && men.visible && pole.x - 200 > x) {
				killMen(x, y, i);
				men.visible = false;
			}
			men.setPosition(x, y);
			x += 300;
		}

		if (inPlay) {
			final value = FlxMath.bound(nightValue ?? FlxMath.remapToRange(conductor.songPosition, 0, playState.inst.length, nightMin, nightMax), nightMin, nightMax);
			bg.colorTransform.redMultiplier = (255 - Math.pow(value, 0.5) * 80) / 255;
			bg.colorTransform.greenMultiplier = (237 - Math.pow(value, 0.86) * 80) / 255;
			bg.colorTransform.blueMultiplier = (251 - Math.pow(value, 1.26) * 140) / 255;
			sunOverlay.alpha = 1 - value;
		}
	}

	override function applyCharacter(character:Character, ?characterPosition:StageCharPos) {
		super.applyCharacter(character, characterPosition);
		switch(character.ID) {
			case GF:
				if (playState.members.indexOf(character) != -1) {
					playState.remove(character);
					insert(members.indexOf(limo), character);
				}
		}
	}

	function beatHit() {
		for (men in mens) men.playAnim((men.curAnimName ?? '') == 'danceLeft' ? 'danceRight' : 'danceLeft');
		if (FlxG.random.bool(10) && timer > poleTimer) doPoleKiller();
		if (FlxG.random.bool(10) && fastCarCanDrive) fastCarDrive();
		if (FlxG.random.bool(30) && conductor.currentBeat > shootingStarBeat)
			doShootingStar(conductor.currentBeat);
	}

	function doPoleKiller() {
		poleTimer = timer + FlxG.random.float(20, 30);
		pole.x = -800;
		pole.velocity.x = FlxG.random.float(190, 220) / 0.07;
		canKill = true;
	}

	function getBody(grp:FlxTypedGroup<BLSprite>):BLSprite {
		final body = grp.recycle(BLSprite, () -> return new BLSprite(Paths.image('limo/henchhit', 'week4'), [1.0], [0.4], [
			{name: 'hit0', id: 'hench hit 1'}, {name: 'hit1', id: 'hench hit 2', offset: [-60, -30]},
			{name: 'arm0', id: 'hench arm 1'}, {name: 'arm1', id: 'hench arm 2'},
			{name: 'head0', id: 'hench head 1'}, {name: 'head1', id: 'hench head 2'},
			{name: 'leg0', id: 'hench leg 1'}, {name: 'leg1', id: 'hench leg 2'},
		]));
		body.moves = true;
		body.fallbackAnim = null;
		return body;
	}

	function killMen(x:Float, y:Float, i:Int) {
		if (i == 0) {
			SoundUtil.playSfx(Paths.sound('dancerdeath', 'week4'), 0.5);
			FlxTween.cancelTweensOf(bgLimo);
			FlxTween.tween(bgLimo, {x: 2000}, 4, {ease: FlxEase.cubeIn, onComplete: (_) -> {
				bgLimo.y += FlxG.random.int(-30, 10);
				canKill = false;
				for (men in mens) men.visible = true;
				FlxTween.tween(bgLimo, {x: -300}, 4, {ease: FlxEase.quadOut, onComplete: (_) -> FlxTween.tween(bgLimo, {x: -200}, 1, {ease: FlxEase.quadInOut})});
				FlxTween.tween(bgLimo, {y: 480}, 7, {ease: FlxEase.quintInOut});
			}});

			playState.camGame.advancedShake(0.002, 0.055, 0.7, 0.2, 1.0, 0.4, 0.7, FlxEase.quartOut);
		}

		final corpse = getBody(bodiesFront);
		corpse.playAnim('hit${FlxG.random.int(0, 1)}');
		corpse.setPosition(x, y);
		corpse.updateHitbox();
		corpse.velocity.copyFrom(pole.velocity);
		corpse.acceleration.set();
		corpse.angularVelocity = 0;
		corpse.flipX = false;
		corpse.angle = 0;

		FlxTimer.wait(2 / 24, () -> {
			final cx = corpse.x;
			corpse.kill();

			final arr = ['head${FlxG.random.int(0, 1)}'];
			for (i in 0...FlxG.random.int(1, 2)) arr.push('arm${FlxG.random.int(0, 1)}');
			for (i in 0...FlxG.random.int(1, 2)) arr.push('leg${FlxG.random.int(0, 1)}');

			for (name in arr) {
				final body = getBody(FlxG.random.bool(50) ? bodiesFront : bodiesBack);
				body.playAnim(name);
				body.setPosition(cx + FlxG.random.float(-100, 100), y + FlxG.random.float(-80, 240));
				body.updateHitbox();
				body.acceleration.set(FlxG.random.float(1200, 1300), 4312);
				body.velocity.set(FlxG.random.float(-340, 150), FlxG.random.float(-600, -1300));
				body.angle = FlxG.random.float(0, 360);
				body.angularVelocity = FlxG.random.float(600, 1200) * (FlxG.random.bool(50) ? -1 : 1);
				body.flipX = FlxG.random.bool(50);

				FlxTimer.wait(4, () -> body.kill());
			}
		});
	}

	function doShootingStar(beat:Int) {
		shootingStar.visible = true;
		shootingStar.setPosition(FlxG.random.int(300,900), FlxG.random.int(-10,20));
		shootingStar.flipX = FlxG.random.bool(50);
		shootingStar.playAnim('shooting star');

		shootingStarBeat = beat + shootingStarOffset;
		shootingStarOffset = FlxG.random.int(4, 8);
	}

	function resetFastCar() {
		fastCar.setPosition(-12600, FlxG.random.float(600, 700));
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive() {
		SoundUtil.playSfx(Paths.soundRandom('carPass', 0, 1, 'week4'), 0.7);
		fastCarCanDrive = false;

		fastCar.velocity.x = FlxG.random.float(170, 220) / 0.016 * 3;
		FlxTimer.wait(2, resetFastCar);
	}
}