package bl.audio;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;

typedef FlxSoundOrGroup = flixel.util.typeLimit.OneOfTwo<FlxSound, SoundGroup>;

/**
 * A group of FunkinSounds that are all synced together.
 * Unlike FlxSoundGroup, you can also control their time and pitch.
 * 
 * @author EliteMasterEric (FunkinCrew)
 * note: Modified for FNF Blossom
 */
class SoundGroup extends FlxTypedGroup<FlxSound> {
	public var time(get, set):Float;
	public var volume(get, set):Float;
	public var muted(get, set):Bool;
	public var pitch(get, set):Float;
	public var playing(get, never):Bool;
	public var looped(get, set):Bool;

	public var parent(default, set):Null<SoundGroup>;
	public var groups(default, null):Array<SoundGroup>;

	public function new() {
		super();
		groups = [];
	}

	//public dynamic function onComplete():Void {}

	/**
	 * Finds the largest deviation from the desired time inside this SoundGroup.
	 *
	 * @param targetTime	The time to check against.
	 * 						If none is provided, it checks the time of all members against the first member of this SoundGroup.
	 * @return The largest deviation from the target time found.
	 */
	public function checkSyncError(?targetTime:Float):Float {
		var error:Float = 0;

		forEachAlive(function(snd) {
			if (targetTime == null) targetTime = snd.getActualTime();
			else {
				var diff:Float = snd.getActualTime() - targetTime;
				if (Math.abs(diff) > Math.abs(error)) error = diff;
			}
		});
		return error;
	}

	public function resync(targetTime:Float) if (Math.abs(checkSyncError(targetTime)) > 12) time = targetTime;

	/**
	 * Add a sound to the group.
	 */
	public override function add(sound:FlxSound):FlxSound {
		final sound = super.add(sound);
		if (sound == null) return null;

		sound.time = this.time;

		/*result.onComplete = this.onComplete.bind()*/
		sound.pitch = this.pitch;
		sound.volume = this.volume;

		return sound;
	}

	/**
	 * Add a soundGroup to *this* group.
	 */
	public function addGroup(group:SoundGroup):SoundGroup {
		group.parent = this;
		return group;
	}

	/**
	 * Remove a soundGroup from *this* group.
	 */
	public function removeGroup(group:SoundGroup):SoundGroup {
		if (group.parent == this) group.parent = null;
		return group;
	}

	/**
	 * Play all the sounds in the group.
	 */
	public function play(forceRestart:Bool = false, startTime:Float = 0.0, ?endTime:Float) {
		forEachAlive((sound:FlxSound) -> sound.play(forceRestart, startTime, endTime));
		for (group in groups) group.play(forceRestart, startTime, endTime);
	}

	/**
	 * Pause all the sounds in the group.
	 */
	public function pause() {
		forEachAlive((sound:FlxSound) -> sound.pause());
		for (group in groups) group.pause();
	}

	/**
	 * Resume all the sounds in the group.
	 */
	public function resume() {
		forEachAlive((sound:FlxSound) -> sound.resume());
		for (group in groups) group.resume();
	}

	/**
	 * Fade in all the sounds in the group.
	 */
	public function fadeIn(duration:Float, ?from:Float = 0.0, ?to:Float = 1.0, ?onComplete:FlxTween->Void) {
		forEachAlive((sound:FlxSound) -> sound.fadeIn(duration, from, to, onComplete));
		for (group in groups) group.fadeIn(duration, from, to, onComplete);
	}

	/**
	 * Fade out all the sounds in the group.
	 */
	public function fadeOut(duration:Float, ?to:Float = 0.0, ?onComplete:FlxTween->Void) {
		forEachAlive((sound:FlxSound) -> sound.fadeOut(duration, to, onComplete));
		for (group in groups) group.fadeOut(duration, to, onComplete);
	}

	/**
	 * Stop all the sounds in the group.
	 */
	public function stop():Void {
		if (members != null) {
			forEachAlive((sound:FlxSound) -> sound.stop());
			for (group in groups) group.stop();
		}
	}

	public override function destroy():Void {
		stop();
		groups = null;
		super.destroy();
	}

	/**
	 * Remove all sounds from the group.
	 */
	public override function clear():Void {
		stop();
		groups.clearArray();
		super.clear();
	}

	function get_time():Float {
		var sound = getFirstAlive();
		if (sound != null) return sound.time;
		else return 0;
	}

	function set_time(time:Float):Float {
		forEachAlive((sound:FlxSound) -> sound.time = time);
		for (group in groups) group.time = time;
		return time;
	}

	function get_playing():Bool {
		var sound = getFirstAlive();
		if (sound != null) return sound.playing;
		else return false;
	}

	function get_volume():Float {
		var sound = getFirstAlive();
		if (sound != null) return sound.volume / (parent != null ? parent.volume : 1);
		else return 1;
	}

	function set_volume(volume:Float):Float {
		final realVolume = volume * (parent != null ? parent.volume : 1);
		forEachAlive((sound:FlxSound) -> sound.volume = realVolume);
		for (group in groups) group.volume = realVolume;
		return volume;
	}

	function get_muted():Bool {
		var sound = getFirstAlive();
		if (sound != null) return sound.muted;
		else return false;
	}

	function set_muted(muted:Bool):Bool {
		forEachAlive((sound:FlxSound) -> sound.muted = muted);
		for (group in groups) group.muted = muted;
		return muted;
	}

	function get_pitch():Float {
		#if FLX_PITCH
		var sound = getFirstAlive();
		if (sound != null) return sound.pitch / (parent != null ? parent.pitch : 1);
		else
		#end
		return 1;
	}

	function set_pitch(pitch:Float):Float {
		#if FLX_PITCH
		final realPitch = pitch * (parent != null ? parent.pitch : 1);
		forEachAlive((sound:FlxSound) -> sound.pitch = realPitch);
		for (group in groups) group.pitch = realPitch;
		#end
		return pitch;
	}

	function get_looped():Bool {
		var sound = getFirstAlive();
		if (sound != null) return sound.looped;
		else
		return false;
	}

	function set_looped(looped:Bool):Bool {
		forEachAlive((sound:FlxSound) -> sound.looped = looped);
		for (group in groups) group.looped = looped;
		return looped;
	}

	function set_parent(newParent:Null<SoundGroup>):Null<SoundGroup> {
		final realVolume = volume, realPitch = pitch; 

		if (parent != null) parent.groups.remove(this);
		if ((parent = newParent) != null) newParent.groups.push(this);

		volume = realVolume;
		pitch = realPitch;

		return newParent;
	}
}
