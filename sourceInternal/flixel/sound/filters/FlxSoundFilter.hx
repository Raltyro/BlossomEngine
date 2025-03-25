package flixel.sound.filters;

import lime.media.openal.AL;
import lime.media.openal.ALFilter;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

class FlxSoundFilter implements IFlxDestroyable {
	var _filter:ALFilter;

	public function new() {
		_filter = AL.createFilter();
	}

	public function destroy() {
		AL.deleteFilter(_filter);
		_filter = null;
	}
}