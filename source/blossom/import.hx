#if !macro
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.typeLimit.NextState;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

import blossom.backend.constants.*;
import blossom.backend.util.AssetUtil;
import blossom.backend.util.SoundUtil;
import blossom.backend.Conductor;
import blossom.BLState;
#end

import haxe.ds.ObjectMap;
import haxe.ds.WeakMap;

import blossom.backend.Paths;
import blossom.backend.Types;

using StringTools;
using flixel.util.FlxArrayUtil;