package blossom.play;

enum abstract PlayStateError(String) from String to String {
	var NO_SONG = "No Song to Play";
	var NO_SONGS_PLAYLIST = "No Songs to Play in Playlist";
	var UNREADABLE_CHART = "Can't read Song Chart Data";
	var NO_PARAMS = "No PlayStateParams to enter to PlayState";
	var NO_CHART = "No Chart to Play";
}

typedef PlayStateParams = {
	?errorCallback:(error:PlayStateError, switchedState:Bool)->Void,
	?cameraFollowPoint:FlxPoint,
	?song:Song,
	?difficulty:String,
	?playbackRate:Float,
	?startTimestamp:Float,
	?subStateLoading:Bool,
	?freezeBackground:Bool
}

typedef FollowCharacter = {
	character:Character,
	?lerp:Float
}

class PlayState extends BLState {
	public static var instance:PlayState;
	public static var lastParams:PlayStateParams;

	// Play Properties
	public var params:PlayStateParams;

	public function new(?params:PlayStateParams) {
		super();

		if ((this.params = params = params ?? lastParams) == null) return errorPlayState(params, NO_PARAMS, true);
		else if (params.song == null) return errorPlayState(params, NO_SONG, true);

		lastParams = params;

		previousCameraFollowPoint = params.cameraFollowPoint;
		playbackRate = params.playbackRate ?? 1;
		startTimestamp = params.startTimestamp ?? 0;
	}

	override function create() {
		instance = this;
		_constructor = PlayState.new.bind(params);

		super.create();
	}
}