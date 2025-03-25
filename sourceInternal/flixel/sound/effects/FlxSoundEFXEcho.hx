package flixel.sound.effects;

import lime.media.openal.ALEffect;
import lime.media.openal.AL;
import flixel.math.FlxMath;

class FlxSoundEFXEcho extends FlxSoundEFX {
	public var delay(default, set):Float = 0.1; // Range [0.0, 0.207]
	public var lrDelay(default, set):Float = 0.1; // Range [0.0, 0.404]
	public var damping(default, set):Float = 0.5; // Range [0.0, 0.99]
	public var feedback(default, set):Float = 0.5; // Range [0.0, 1.0]
	public var spread(default, set):Float = -1.0; // Range [-1.0, 1.0]

	public function new(delay = 0.1, damping = 0.5, feedback = 0.5, spread = -1.0) {
		super();
		AL.effecti(_effect, AL.EFFECT_TYPE, AL.EFFECT_REVERB);

		this.delay = delay;
		this.damping = damping;
		this.feedback = feedback;
		this.spread = spread;
	}

	function set_delay(v:Float):Float {
		AL.effectf(_effect, AL.ECHO_DELAY, v);
		return FlxMath.bound(v, 0.0, 0.207);
	}

	function set_lrDelay(v:Float):Float {
		AL.effectf(_effect, AL.ECHO_LRDELAY, v);
		return FlxMath.bound(v, 0.0, 0.404);
	}

	function set_damping(v:Float):Float {
		AL.effectf(_effect, AL.ECHO_DAMPING, v);
		return FlxMath.bound(v, 0.0, 0.99);
	}

	function set_feedback(v:Float):Float {
		AL.effectf(_effect, AL.ECHO_FEEDBACK, v);
		return FlxMath.bound(v, 0.0, 1.0);
	}

	function set_spread(v:Float):Float {
		AL.effectf(_effect, AL.ECHO_SPREAD, v);
		return FlxMath.bound(v, -1.0, 1.0);
	}
}