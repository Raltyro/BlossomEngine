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
import flixel.FlxCamera;
import flixel.FlxGame;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;

import bl.api.Discord;
import bl.data.Song;
import bl.data.Save;
import bl.math.*;
import bl.mod.event.*;
import bl.mod.Module;
import bl.mod.ModuleEvent;
import bl.mod.ModuleGroup;
import bl.play.component.Character;
import bl.play.component.HealthIcon;
import bl.play.component.Stage;
import bl.play.event.*;
import bl.play.PlayCamera;
import bl.play.PlayEvent;
import bl.play.PlayScript;
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