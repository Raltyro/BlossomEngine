package blossom.backend.util;

import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.sound.FlxSoundGroup;
import blossom.sound.Music;

class SoundUtil {
	public static function playMenuMusic(?conductor:Conductor):Music {
		var music = Paths.music("freakyMenu");
		return playMusic(music/*, conductor*/);
	}

	public static function playMusic(asset:MusicAsset, volume = 1.0, ?conductor:Conductor, ?onComplete:Null<Void->Void>):Music {
		final assetMusic:MusicData = asset is String ? null : asset;

		if (!(FlxG.sound.music is Music)) {
			if (FlxG.sound.music != null) FlxG.sound.music.destroy();
			FlxG.sound.defaultMusicGroup.add(FlxG.sound.music = new Music());
		}
		final music:Music = cast FlxG.sound.music;

		if (music.musicData != null && music.musicData.path == (assetMusic?.path ?? asset)) return music;

		music.loadMusic(asset, onComplete);
		music.persist = true;
		music.volume = volume;
		music.play();

		(conductor ?? Conductor.instance).mapTimeChanges(music.timeChanges);

		return music;
	}

	public static function playSound(asset:FlxSoundAsset, volume:Float = 1.0, ?group:FlxSoundGroup, ?autoDestroy:Bool = true, ?onComplete:Void->Void):FlxSound
		return FlxG.sound.play(asset, volume, group, autoDestroy, onComplete);	
}