package funkin.stage;

class DefaultStage extends Stage {
	public static var classStageID:String = 'stage';

	//public static function preload()
		//return AssetUtil.loadGraphic(Paths.image('stage.jpg'));

	override function resetStage() {
		super.resetStage();

		characterPositions.set(BF, {
			x: 1150, y: 800,
			camX: -70
		});
		characterPositions.set(DAD, {
			x: 150, y: 800,
			camX: 70, flipX: true
		});
		characterPositions.set(GF, {
			x: 700, y: 710,
			scroll: 0.98,
			layer: -1
		});

		defaultZoom = 0.75;
		centerPosition.set(650, 510);
	}

	override function create() {
		super.create();

		//add(new BLSprite(-1408, -1005, Paths.image('stage.jpg'), [1.33333333], [0.98]));
	}
}