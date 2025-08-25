package blossom.backend.constants;

//import haxe.macro.Compiler;
import blossom.graphic.transitions.Transition.TransitionData;

final class GameConstants {
	public static var WIDTH:Int = 1280;
	public static var HEIGHT:Int = 720;
	public static var FRAMERATE:Int = 60;

	public static var INITIAL_STATE:NextState = ralty.SpectrumTestState.new;
	public static var DEFAULT_TRANSITION_IN:TransitionData = new TransitionData(blossom.graphic.transitions.TransitionFade, 0.5);
	public static var DEFAULT_TRANSITION_OUT:TransitionData = new TransitionData(blossom.graphic.transitions.TransitionFade, 0.5);
}