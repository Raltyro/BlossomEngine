package bl.play;

class PlayCamera extends BLCamera {
	/**
	 * Zoom strength on bop
	 */
	public var bopStrength:Float = 0;

	/**
	 * Beat Intervals of camera bops.
	 */
	public var bopInterval:Float = 1;
	public var bopEvery:BeatType = MEASURE;

	/**
	 * How much measure offset the bop is
	 */
	public var bopOffset:Float = 0;

	/**
	 * The conductor for camera bops to work.
	 */
	public var conductor:Null<Conductor>;

	public function new(?conductor:Conductor, x = 0.0, y = 0.0, w = 0, h = 0, zoom = 0.0) {
		super(x, y, w, h, zoom);
		this.conductor = conductor;
	}

	inline public function bop(?strength:Float) if (!zoomTween?.active) zoom += (strength ?? bopStrength) * targetZoom;

	override function update(elapsed:Float) {
		if (conductor != null && bopStrength != 0) {
			var beat = conductor.getBeats(bopEvery, bopInterval, bopOffset);
			if (_lastBeat != beat) {
				_lastBeat = beat;
				bop();
			}
		}

		super.update(elapsed);
	}
}