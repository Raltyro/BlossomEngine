package funkin.character;

class GF extends Character {
	public static var classCharacterID:String = 'gf';
	public static var classCharacterName:String = 'Girlfriend';
	public static var classCharacterIconData = {
		color: 0xFFA5004D
	};

	public static function preload()
		return CoolUtil.chainFutures([
			AssetUtil.loadSparrowAtlas(Paths.image('characters/GF_ass', 'shared')),
			AssetUtil.loadGraphic(HealthIcon.getIcon('gf'))
		]);

	override function resetCharacter() {
		super.resetCharacter();

		characterOrigin.set(346, 627);
		cameraFocus.set(-20, -410);

		cameraFocusDirection[LEFT].set(-18, 0);
		cameraFocusDirection[DOWN].set(0, 14);
		cameraFocusDirection[UP].set(0, -10);
		cameraFocusDirection[RIGHT].set(18, 0);
	}

	override function create() {
		super.create();

		loadAnimGraphic(Paths.image('characters/GF_ass', 'shared'), [
			{name: 'danceLeft', id: 'GF Dancing Beat', fps: 24, loop: false, indices: [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]},
			{name: 'danceRight', id: 'GF Dancing Beat', fps: 24, loop: false, indices: [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]},
			{name: 'cheer', id: 'GF Cheer', fps: 24, loop: false, offset: [0, 8]},
			{name: 'sad', id: 'gf sad', fps: 24, loop: false, offset: [-2, -12]},
			{name: 'scared', id: 'GF FEAR ', fps: 24, loop: false, offset: [-2, -8]},
		]);
	}
}

class GFCar extends Character {
	public static var classCharacterID:String = 'gf-car';
	public static var classCharacterName:String = 'Girlfriend Car';
	public static var classCharacterIconData = {
		color: 0xFFA5004D
	};

	public static function preload()
		return CoolUtil.chainFutures([
			AssetUtil.loadSparrowAtlas(Paths.image('characters/GF_ass', 'shared')),
			AssetUtil.loadGraphic(HealthIcon.getIcon('gf'))
		]);

	override function resetCharacter() {
		super.resetCharacter();

		characterOrigin.set(346, 627);
		cameraFocus.set(-20, -410);

		cameraFocusDirection[LEFT].set(-18, 0);
		cameraFocusDirection[DOWN].set(0, 14);
		cameraFocusDirection[UP].set(0, -10);
		cameraFocusDirection[RIGHT].set(18, 0);
	}

	override function create() {
		super.create();

		loadAnimGraphic(Paths.image('characters/GF_ass', 'shared'), [
			{name: 'danceLeft', id: 'GF Dancing Beat', fps: 24, loop: false, indices: [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]},
			{name: 'danceRight', id: 'GF Dancing Beat', fps: 24, loop: false, indices: [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]},
			{name: 'cheer', id: 'GF Cheer', fps: 24, loop: false, offset: [0, 8]},
			{name: 'sad', id: 'gf sad', fps: 24, loop: false, offset: [-2, -12]},
			{name: 'scared', id: 'GF FEAR ', fps: 24, loop: false, offset: [-2, -8]},
		]);
	}
}