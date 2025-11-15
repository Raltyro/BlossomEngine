#if !macro
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.typeLimit.*;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

import blossom.backend.constants.*;
import blossom.backend.mod.ModuleEvent;
import blossom.backend.util.typeLimit.*;
import blossom.backend.util.typeLimit.Types;
import blossom.backend.util.AssetUtil;
import blossom.backend.util.SoundUtil;
import blossom.backend.Conductor;
import blossom.BLCamera;
//import blossom.BLSprite;
import blossom.BLState;
#end

import haxe.ds.ObjectMap;
import haxe.ds.WeakMap;

import blossom.backend.Paths;

using StringTools;
using flixel.util.FlxArrayUtil;