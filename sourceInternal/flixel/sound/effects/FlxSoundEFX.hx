package flixel.sound.effects;

import lime.media.openal.AL;
import lime.media.openal.ALEffect;
import flixel.sound.filters.FlxSoundFilter;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

class FlxSoundEFX implements IFlxDestroyable {
	public var filter:FlxSoundFilter;

	var _effect:ALEffect;

	public function new() {
		_effect = AL.createEffect();
	}

	public function destroy() {
		AL.deleteEffect(_effect);
		_effect = null;
	}
}