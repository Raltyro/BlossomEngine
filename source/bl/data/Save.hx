package bl.data;

import sys.io.File;
import sys.FileSystem;

import hxIni.IniManager;
import hxIni.IniManager.Ini;
import hxIni.IniManager.IniSection;

import flixel.input.actions.FlxActionInput.FlxInputDeviceID;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

import bl.input.Controls;
import bl.input.ColumnInputManager;

@:structInit class Settings {
	/* Gameplay */
	// General 
	public var autoPause:Bool = true;
	public var downscroll:Bool = false;
	public var centerscroll:Bool = false;
	public var ghostTap:Bool = false;
	public var timeType:Int = 0;
	public var judgmentWorldSpace:Bool = true;
	public var lostFocusPause:Bool = false;

	// Audio
	public var hitSound:Float = 0;
	public var sfxVolume:Float = 1;
	public var menuMusicVolume:Float = 1;
	public var musicVolume:Float = 1;
	public var vocalVolume:Float = 1;
	public var songOffset:Int = #if windows 20 #else 8 #end;
	public var streamInstrumental:Bool = true;

	/* Display */
	// Graphic
	public var antialiasing:Bool = true;
	public var lowQuality:Bool = false;
	public var shader:Bool = false;
	public var flashing:Bool = true;

	// Window
	public var fullscreen:Bool = false;
	public var framerate:Int = 0;

	// Stats Debug
	public var showFPS:Bool = #if debug true #else false #end;
	public var showState:Bool = false;
	public var showMemory:Bool = #if debug true #else false #end;
	public var showMemoryPeak:Bool = false;
	public var showDraws:Bool = #if debug true #else false #end;

	/* Controls */
	public var extraColumnsOption:Bool = false; // hidden
	public var keyBinds:Map<Control, Array<FlxKey>> = null;
	public var buttonBinds:Map<FlxInputDeviceID, Map<Control, Array<FlxGamepadInputID>>> = null;
	public var columnKeyBinds:Map<Int, Array<Array<FlxKey>>> = null;
	public var columnButtonBinds:Map<FlxInputDeviceID, Map<Int, Array<Array<FlxGamepadInputID>>>> = null;
}

class Save {
	public static var data_dir(default, null):String = "raltyro/blossom";
	public static var setting_path(default, null):String = "settings.ini";

	public static var settings:Settings = {};
	public static var data:Dynamic;

	public static function load() {
		loadData();
		loadSettings();
	}

	public static function loadData():Bool {
		if (FlxG.save.bind('funkin', data_dir)) {
			data = FlxG.save.data;
			return true;
		}
		else data = {};
		return false;
	}

	public static function saveData():Bool
		return FlxG.save.flush();

	public static function loadSettings():Bool {
		verifySettings();
		return true;
	}

	public static function verifySettings() {
		if (settings.keyBinds == null)
			settings.keyBinds = [for (idx in Controls.instance.controls.keys()) idx => Controls.getDefaultKeyBind(idx)];

		if (settings.buttonBinds == null)
			settings.buttonBinds = [FlxInputDeviceID.ALL => [for (idx in Controls.instance.controls.keys()) idx => Controls.getDefaultButtonBind(idx)]];

		if (settings.columnKeyBinds == null)
			settings.columnKeyBinds = ColumnInputManager.getDefaultColumnKeyBinds();

		if (settings.columnButtonBinds == null)
			settings.columnButtonBinds = [FlxInputDeviceID.ALL => ColumnInputManager.getDefaultColumnButtonBinds()];

		FlxG.autoPause = settings.autoPause;

		if (settings.framerate <= 0) settings.framerate = Main.DEFAULT_FRAMERATE;
		else Main.framerate = settings.framerate;

		FlxSprite.defaultAntialiasing = settings.antialiasing;

		Main.statsCounter.fpsCounter.visible = settings.showFPS;
		Main.statsCounter.flixelCounter.visible = settings.showState;
		Main.statsCounter.memoryCounter.visible = settings.showMemory;
		Main.statsCounter.memoryCounter.showPeak = settings.showMemoryPeak;
		Main.statsCounter.drawCounter.visible = settings.showDraws;
	}
}