#if !macro
import lime.app.Future;
import lime.app.Promise;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.tweens.misc.*;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.FlxGame;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;

import bl.api.Discord;
import bl.data.Save;
import bl.math.*;
import bl.mod.Module;
import bl.mod.ModuleEvent;
import bl.mod.ModuleGroup;
import bl.play.PlayState;
import bl.state.base.BLState;
import bl.util.AssetUtil;
import bl.util.CoolUtil;
import bl.util.CoolUtil.funkinLerp;
import bl.util.SoundUtil;
import bl.BLCamera;
import bl.BLClickableSprite;
import bl.BLSprite;
import bl.BLText;
import bl.Conductor;
#end

import haxe.ds.ObjectMap;
import haxe.ds.WeakMap;

import bl.Paths;

using flixel.util.FlxArrayUtil;