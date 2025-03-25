package funkin.character;

class BF extends Character {
	public static var classCharacterID:String = 'bf';
	public static var classCharacterName:String = 'Boyfriend';
	public static var classCharacterIconData = {
		color: 0xFF31B0D1
	};

	public static function preload()
		return CoolUtil.chainFutures([
			AssetUtil.loadSparrowAtlas(Paths.image('characters/BOYFRIEND', 'shared')),
			AssetUtil.loadGraphic(HealthIcon.getIcon('bf'))
		]);

	override function resetCharacter() {
		super.resetCharacter();

		characterOrigin.set(236, 365);
		cameraFocus.set(-130, -230);
		deathCameraFocus.set(-10, -180);
		sourceSize = new FlxPoint(411, 412);
	}

	override function create() {
		super.create();

		final deathSparrowPath = Paths.image('characters/BOYFRIEND_DEAD', 'shared');
		loadAnimGraphic(Paths.image('characters/BOYFRIEND', 'shared'), [
			{name: 'idle', id: 'BF idle dance', fps: 24, loop: false, offset: [-5, 0]},
			{name: 'singLEFT', id: 'BF NOTE LEFT0', fps: 24, loop: false, offset: [9, -6]},
			{name: 'singDOWN', id: 'BF NOTE DOWN0', fps: 24, loop: false, offset: [-17, -48]},
			{name: 'singUP', id: 'BF NOTE UP0', fps: 24, loop: false, offset: [-45, 30]},
			{name: 'singRIGHT', id: 'BF NOTE RIGHT0', fps: 24, loop: false, offset: [-49, -6]},
			{name: 'singLEFTmiss', id: 'BF NOTE LEFT MISS0', fps: 24, loop: false, offset: [9, 20]},
			{name: 'singDOWNmiss', id: 'BF NOTE DOWN MISS0', fps: 24, loop: false, offset: [-17, -18]},
			{name: 'singUPmiss', id: 'BF NOTE UP MISS0', fps: 24, loop: false, offset: [-41, 30]},
			{name: 'singRIGHTmiss', id: 'BF NOTE RIGHT MISS0', fps: 24, loop: false, offset: [-43, 22]},
			{name: 'hey', id: 'BF HEY!!', fps: 24, loop: false, offset: [-4, 5]},
			{name: 'hurt', id: 'BF hit', fps: 24, loop: false, offset: [12, 19]},
			{name: 'scared', id: 'BF idle shaking', fps: 24, loop: true, offset: [-6, 1]},
			{name: 'dodge', id: 'boyfriend dodge', fps: 24, loop: false, offset: [-5, -12]},
			{name: 'pre-attack', id: 'bf pre attack', fps: 24, loop: false, offset: [-40, -35]},
			{name: 'attack', id: 'boyfriend attack', fps: 24, loop: false, offset: [293, 271]},

			{name: 'firstDeath', asset: deathSparrowPath, id: 'BF dies', fps: 24, loop: false, offset: [23, 7]},
			{name: 'deathLoop', asset: deathSparrowPath, id: 'BF Dead Loop', fps: 24, loop: true, offset: [23, 1]},
			{name: 'deathConfirm', asset: deathSparrowPath, id: 'BF Dead confirm', fps: 24, loop: false, offset: [23, 65]}
		]);
	}
}

class BFCar extends Character {
	public static var classCharacterID:String = 'bf-car';
	public static var classCharacterName:String = 'Boyfriend Car';
	public static var classCharacterIconData = {
		image: HealthIcon.getIcon('bf'),
		color: 0xFF31B0D1
	};

	public static function preload()
		return CoolUtil.chainFutures([
			AssetUtil.loadSparrowAtlas(Paths.image('characters/bfCar', 'shared')),
			AssetUtil.loadGraphic(HealthIcon.getIcon('bf'))
		]);

	override function resetCharacter() {
		super.resetCharacter();

		characterOrigin.set(236, 365);
		cameraFocus.set(-130, -230);
		deathCameraFocus.set(-10, -180);
		sourceSize = new FlxPoint(411, 412);
	}

	override function create() {
		super.create();

		final deathSparrowPath = Paths.image('characters/BOYFRIEND_DEAD', 'shared');
		final normalSparrowPath = Paths.image('characters/BOYFRIEND', 'shared');
		loadAnimGraphic(Paths.image('characters/bfCar', 'shared'), [
			{name: 'idle', id: 'BF idle dance', fps: 24, loop: false, offset: [-5, 0], indices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]},
			{name: 'idle-loop', id: 'BF idle dance', fps: 24, loop: true, offset: [-5, 0], indices: [10, 11, 12, 13]},
			{name: 'singLEFT', id: 'BF NOTE LEFT0', fps: 24, loop: false, offset: [9, -6], indices: [0, 1, 2, 3]},
			{name: 'singLEFT-loop', id: 'BF NOTE LEFT0', fps: 24, loop: true, offset: [9, -6], indices: [4, 5, 6, 7]},
			{name: 'singDOWN', id: 'BF NOTE DOWN0', fps: 24, loop: false, offset: [-17, -48], indices: [0, 1, 2, 3]},
			{name: 'singDOWN-loop', id: 'BF NOTE DOWN0', fps: 24, loop: true, offset: [-17, -48], indices: [4, 5, 6, 7]},
			{name: 'singUP', id: 'BF NOTE UP0', fps: 24, loop: false, offset: [-45, 30], indices: [0, 1, 2, 3]},
			{name: 'singUP-loop', id: 'BF NOTE UP0', fps: 24, loop: true, offset: [-45, 30], indices: [4, 5, 6, 7]},
			{name: 'singRIGHT', id: 'BF NOTE RIGHT0', fps: 24, loop: false, offset: [-49, -6], indices: [0, 1, 2, 3]},
			{name: 'singRIGHT-loop', id: 'BF NOTE RIGHT0', fps: 24, loop: true, offset: [-49, -6], indices: [4, 5, 6, 7]},
			{name: 'singLEFTmiss', id: 'BF NOTE LEFT MISS0', fps: 24, loop: false, offset: [9, 20]},
			{name: 'singDOWNmiss', id: 'BF NOTE DOWN MISS0', fps: 24, loop: false, offset: [-17, -18]},
			{name: 'singUPmiss', id: 'BF NOTE UP MISS0', fps: 24, loop: false, offset: [-41, 30]},
			{name: 'singRIGHTmiss', id: 'BF NOTE RIGHT MISS0', fps: 24, loop: false, offset: [-43, 22]},
			{name: 'hey', asset: normalSparrowPath, id: 'BF HEY!!', fps: 24, loop: false, offset: [-4, 5]},
			{name: 'hurt', asset: normalSparrowPath, id: 'BF hit', fps: 24, loop: false, offset: [12, 19]},
			{name: 'scared', asset: normalSparrowPath, id: 'BF idle shaking', fps: 24, loop: true, offset: [-6, 1]},
			{name: 'dodge', asset: normalSparrowPath, id: 'boyfriend dodge', fps: 24, loop: false, offset: [-5, -12]},
			{name: 'pre-attack', asset: normalSparrowPath, id: 'bf pre attack', fps: 24, loop: false, offset: [-40, -35]},
			{name: 'attack', asset: normalSparrowPath, id: 'boyfriend attack', fps: 24, loop: false, offset: [293, 271]},

			{name: 'firstDeath', asset: deathSparrowPath, id: 'BF dies', fps: 24, loop: false, offset: [23, 7]},
			{name: 'deathLoop', asset: deathSparrowPath, id: 'BF Dead Loop', fps: 24, loop: true, offset: [23, 1]},
			{name: 'deathConfirm', asset: deathSparrowPath, id: 'BF Dead confirm', fps: 24, loop: false, offset: [23, 65]}
		]);
	}
}