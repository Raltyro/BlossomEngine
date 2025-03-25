package flixel.sound.filters;

import lime.media.openal.ALFilter;
import lime.media.openal.AL;
import flixel.math.FlxMath;

class FlxSoundFilterLowPass extends FlxSoundFilter {
	public var gain(default, set):Float = 1.0; // Range [0.0, 1.0]
	public var highFrequency(default, set):Float = 1.0; // Range [0.0, 1.0]

	public function new(gain = 1.0, highFrequency = 1.0) {
		super();
		AL.filterf(_filter, AL.FILTER_TYPE, AL.FILTER_LOWPASS);

		this.gain = gain;
		this.highFrequency = highFrequency;
	}

	function set_gain(v:Float):Float {
		AL.filterf(_filter, AL.LOWPASS_GAIN, v);
		return FlxMath.bound(v, 0.0, 1.0);
	}

	function set_highFrequency(v:Float):Float {
		AL.filterf(_filter, AL.LOWPASS_GAINHF, v);
		return FlxMath.bound(v, 0.0, 1.0);
	}
}