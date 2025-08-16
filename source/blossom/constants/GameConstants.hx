package blossom.constants;

import haxe.macro.Compiler;

final class GameConstants {
	public static var WIDTH:Int = 1280;
	public static var HEIGHT:Int = 720;
	public static var FRAMERATE:Int = 60;

	public static var INITIAL_STATE:NextState = BLState.new;
}