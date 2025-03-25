package funkin.character;

class MomCar extends Character {
	public static var classCharacterID:String = 'mom-car';
	public static var classCharacterName:String = 'Mom Car';
	public static var classCharacterIconData = {
		image: HealthIcon.getIcon('mom'),
		color: 0xFFD8558E
	};

	public static function preload()
		return CoolUtil.chainFutures([
			AssetUtil.loadSparrowAtlas(Paths.image('characters/momCar', 'shared')),
			AssetUtil.loadGraphic(HealthIcon.getIcon('mom'))
		]);

	override function resetCharacter() {
		super.resetCharacter();

		characterOrigin.set(320, 744);
		cameraFocus.set(-200, -380);
		deathCameraFocus.set(-150, -360);
		sourceSize = new FlxPoint(479, 814);
	}

	override function create() {
		super.create();

		loadAnimGraphic(Paths.image('characters/momCar', 'shared'), [
			{name: 'idle', id: 'Mom Idle', fps: 24, loop: false, flipX: true, offset: [0, 0], indices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]},
			{name: 'idle-loop', id: 'Mom Idle', fps: 24, loop: true, flipX: true, offset: [0, 0], indices: [10, 11, 12, 13]},
			{name: 'singLEFT', id: 'Mom Pose Left', fps: 24, loop: false, flipX: true, offset: [217, -56], indices: [0, 1, 2, 3]},
			{name: 'singLEFT-loop', id: 'Mom Pose Left', fps: 24, loop: true, flipX: true, offset: [217, -56], indices: [4, 5, 6, 7]},
			{name: 'singDOWN', id: 'MOM DOWN POSE', fps: 24, loop: false, flipX: true, offset: [-10, -158], indices: [0, 1, 2, 3]},
			{name: 'singDOWN-loop', id: 'MOM DOWN POSE', fps: 24, loop: true, flipX: true, offset: [-10, -158], indices: [4, 5, 6, 7]},
			{name: 'singUP', id: 'Mom Up Pose', fps: 24, loop: false, flipX: true, offset: [-3, 81], indices: [0, 1, 2, 3]},
			{name: 'singUP-loop', id: 'Mom Up Pose', fps: 24, loop: true, flipX: true, offset: [-3, 81], indices: [4, 5, 6, 7]},
			{name: 'singRIGHT', id: 'Mom Left Pose', fps: 24, loop: false, flipX: true, offset: [-150, -20], indices: [0, 1, 2, 3]},
			{name: 'singRIGHT-loop', id: 'Mom Left Pose', fps: 24, loop: true, flipX: true, offset: [-150, -20], indices: [4, 5, 6, 7]},
		]);
	}
}