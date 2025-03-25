package bl.play;

import lime.app.Future;

import flixel.group.FlxGroup;
import flixel.tweens.FlxTween.FlxTweenManager;
import flixel.input.actions.FlxActionInput.FlxInputDeviceID;
import flixel.text.FlxText;
import flixel.util.typeLimit.OneOfTwo;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxTimer.FlxTimerManager;
import flixel.util.FlxStringUtil;

import bl.audio.SoundGroup;
import bl.data.Skin;
import bl.data.Song;
import bl.input.ColumnInputManager;
import bl.play.component.*;
import bl.play.field.Note;
import bl.play.field.Notefield;
import bl.play.field.Playfield;
import bl.play.event.*;
import bl.play.scoring.BaseScoring;
import bl.play.Highscore.Tallies;
import bl.state.base.BaseLoadingScreen;
import bl.state.LoadingScreen;
import bl.util.SortUtil;
import bl.Conductor.Metronome;

// find a better way to do this
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

@:access(flixel.util.FlxTimer.FlxTimerManager)
@:access(flixel.tweens.FlxTween.FlxTweenManager)
class PlayState extends BLState {
	public static var instance:PlayState;
	public static var lastParams:PlayStateParams;

	public static var deathCounter:UInt;

	public static var storyDifficulty:String;
	public static var storyMode:Bool;
	public static var weekDifficulties:Array<String>;
	public static var playlist:Array<String>;

	// for Playlists, though the last index will always be the current song
	public static var prevSongs:Array<String>;
	public static var prevDifficulties:Array<String>;
	public static var prevTallies:Array<Tallies>;

	private inline static function defaultErrorCallback(error:PlayStateError, switchedState:Bool) throw '$error (switchedState: $switchedState)';
	private inline static function errorPlayState(?params:PlayStateParams, error:PlayStateError, switchedState:Bool) (params?.errorCallback ?? defaultErrorCallback)(error, switchedState);

	public static function playPlaylist(Playlist:Array<String>, ?WeekDiffs:Array<String>, ?diff:String, StoryMode:Bool = false, ?params:PlayStateParams) {
		playlist = Playlist;
		weekDifficulties = WeekDiffs ?? Song.DEFAULT_DIFFICULTIES;
		storyDifficulty = diff ?? Song.getDefaultDifficultyFromDiffs(weekDifficulties);
		storyMode = StoryMode;

		prevSongs = [];
		prevDifficulties = [];
		prevTallies = [];
		lastParams = null;

		playNext(params);
	}

	public static function playNext(?params:PlayStateParams) {
		if (playlist == null || playlist.length == 0) return errorPlayState(params, NO_SONGS_PLAYLIST, false);

		var songID = playlist.shift(), diff = storyDifficulty;
		var song = Song.parseEntry(songID);

		if (lastParams != null && song.difficulties.contains(lastParams.difficulty))
			diff = lastParams.difficulty;
		else if (!song.difficulties.contains(diff)) {
			diff = song.defaultDifficulty; // just incase if anything after this doesn't work

			if (weekDifficulties != null) {
				var idx = weekDifficulties.indexOf(diff) + 1;
				for (i in idx...weekDifficulties.length) if (song.difficulties.contains(weekDifficulties[i])) diff = weekDifficulties[i];
				for (i in 0...idx) if (song.difficulties.contains(weekDifficulties[i])) diff = weekDifficulties[i];
			}
		}

		playSong(song, diff, storyMode, params);
	}

	public static function playSong(songID:OneOfTwo<String, Song>, ?diff:String, StoryMode:Bool = false, ?params:PlayStateParams) {
		if (params == null) params = {};
		if (weekDifficulties == null) weekDifficulties = Song.DEFAULT_DIFFICULTIES;
		storyMode = StoryMode;

		deathCounter = 0;

		params.song = songID is Song ? songID : Song.parseEntry(songID);
		if (prevSongs != null) prevSongs.push(params.song.id);
		if (prevDifficulties != null) prevDifficulties.push(diff);

		//if ((params.chart = song.getChart()) == null) return errorPlayState(params, UNREADABLE_CHART, false);
		params.difficulty = diff;
		loadPlayState(params);
	}

	public static function loadPlayState(params:PlayStateParams):PlayState {
		var workers:Array<LoadingWorker> = [];

		final song = params.song;

		if (song != null) {
			workers.push({work: () -> {
				final chart = song.getChart(params.difficulty);
				if (chart == null) return errorPlayState(params, UNREADABLE_CHART, true);

				final arr:Array<Future<Dynamic>> = [song.loadVoices()];
				if (!Save.settings.streamInstrumental) arr.push(song.loadInstrumental());
				workers.push({text: 'Song Audios', future: () -> return CoolUtil.chainFutures(arr)});

				if (chart.stage != null) workers.push({future: Stage.preloadStage.bind(chart.stage), text: 'Stage'});
				if (chart.characters != null)
					workers.push({text: 'Characters', future: () -> return CoolUtil.chainFutures([
						for (char in chart.characters) Character.preloadCharacter(char.character)
					])});

				if (chart.events != null)
					workers.push({text: 'Events', future: () -> return CoolUtil.chainFutures([
						for (event in chart.events) PlayEvent.preloadEvent(event.event, event)
					])});

				if (PlayScript.songScriptExists(chart.song.id))
					workers.push({future: PlayScript.preloadSongScript.bind(chart.song.id), text: 'Script'});
			}, text: 'Chart${params.difficulty == null ? "" : " (" + params.difficulty + ")"}'});
		}

		var playState = new PlayState(params);
		final screen = new LoadingScreen((screen:BaseLoadingScreen) -> {
			FlxG.sound.music?.stop();
			FlxG.mouse.visible = false;
			return BaseLoadingScreen.translateWorkers(workers)(screen);
		}, FlxG.switchState.bind(playState), params.freezeBackground);

		if (params.subStateLoading && FlxG.state != null) FlxG.state.openSubState(screen);
		else FlxG.switchState(screen);

		return playState;
	}

	// Song
	public var song(get, never):Song; inline function get_song() return chart.song;
	public var chart:SongChart;
	public var difficulty:String;

	public var inst:FlxSound; // alias for FlxG.sound.music
	public var vocals:SoundGroup;

	public var events:PlayEventHandler;

	public var discordRPCAlbum:String;
	public var discordRPCIcon:String;

	// Cameras
	public var camGame:PlayCamera;
	public var camLogic:PlayCamera;
	public var camHUD:PlayCamera;
	public var camOther:PlayCamera;

	public var previousCameraFollowPoint:FlxPoint;
	public var cameraFollowCharacter:Null<Character>;
	public var cameraFollowCharacters:Array<FollowCharacter> = [];
	public var cameraFollowPosition:FlxPoint;
	public var cameraFollowPoint:FlxPoint;
	public var cameraFollowZoomDirect:Null<Float>;
	public var cameraFollowZoom:Float = 1;
	public var cameraFollowZoomMultiply:Float = 1;
	public var followCamera:Bool = true;
	public var followDirectionStrength:Float = 1;

	// Components
	public var skin:Skin;
	public var playfields:Array<Playfield> = [];
	public var characters:Array<Character> = [];
	public var stage:Stage;
	public var bf:Character;
	public var gf:Character;
	public var dad:Character;

	public var columnInputManager:ColumnInputManager;
	public var players:Array<Playfield> = [];
	public var player(get, never):Playfield; function get_player() return players[0];

	public var gameOverSubState:GameOverSubState;

	public var globalTimerManager:FlxTimerManager;
	public var globalTweenManager:FlxTweenManager;
	public var timerManager:FlxTimerManager;
	public var tweenManager:FlxTweenManager;

	// HUD
	public var healthMeter:HealthMeter;
	public var countdown:Countdown;
	public var scoreLabel:FlxText;

	// Play Properties
	public var params:PlayStateParams;

	public var playbackRate(default, set):Float;
	public var startTimestamp:Float;

	public var timePosition:Float = 0;
	public var offset:Float = 0;

	public var updateTimePosition:Bool = true;
	public var startingSong:Bool = false;
	public var endingSong:Bool = false;
	public var allowPause:Bool = false;
	public var allowInput:Bool = false;
	public var allowDeath:Bool = true;
	public var allowDebug:Bool = true;//#if FLX_DEBUG true #else false #end;

	public var lostFocus:Bool = false;
	public var paused:Bool = false;
	public var dead:Bool = false;

	public function new(?params:PlayStateParams) {
		super();

		if ((this.params = params = params ??lastParams) == null) return errorPlayState(params, NO_PARAMS, true);
		else if (params.song == null) return errorPlayState(params, NO_SONG, true);

		lastParams = params;

		previousCameraFollowPoint = params.cameraFollowPoint;
		playbackRate = params.playbackRate ?? 1;
		startTimestamp = params.startTimestamp ?? 0;
	}

	override function create() {
		instance = this;
		_constructor = PlayState.new.bind(params);

		if ((chart = params.song.getChart(params.difficulty)) == null) return errorPlayState(params, NO_CHART, true);
		difficulty = FlxStringUtil.toTitleCase(chart.difficulty);

		globalTimerManager = FlxTimer.globalManager;
		globalTweenManager = FlxTween.globalManager;
		FlxTimer.globalManager = timerManager = new FlxTimerManager();
		FlxTween.globalManager = tweenManager = new FlxTweenManager();

		FlxG.mouse.visible = false;
		CoolUtil.changeWindowTitle(' | ${song.title} (${difficulty})');
		updateDiscordPresence();

		events = new PlayEventHandler(this);

		GameOverSubState.reset();
		PauseSubState.reset();

		if (PlayScript.songScriptExists(song.id)) modules.add(PlayScript.makeSongScript(song.id, this));

		if (skin == null) skin = Skin.getSkin('default');

		initSong();
		initCameras();
		initCharacters();
		initStage();
		initHUD();
		initPlayfields();

		columnInputManager = new ColumnInputManager(player.keys, Save.settings.columnKeyBinds, Save.settings.columnButtonBinds[FlxInputDeviceID.ALL]);
		columnInputManager.inputPressed.add(handleColumnInputPressed);
		columnInputManager.inputReleased.add(handleColumnInputReleased);

		if (previousCameraFollowPoint != null) cameraFollowPoint.copyFrom(previousCameraFollowPoint);
		camGame.target.setPosition(cameraFollowPoint.x, cameraFollowPoint.y);
		camGame.targetZoom = cameraFollowZoomDirect ?? cameraFollowZoom;
		camGame.snapToTarget();

		events.create();

		AssetUtil.clearUnused();

		super.create();

		stage.postCreate();
		modules.call('postCreate');

		startCountdown();
	}

	function initSong() {
		final event = modules.event(ModuleEvent.get(InitSong, false).recycle());
		if (event.cancelled) return event.put();

		if (FlxG.sound.music != null) FlxG.sound.music.destroy();

		FlxG.sound.defaultMusicGroup.add(FlxG.sound.music = inst = song.buildInstrumental());
		vocals = new SoundGroup();
		inst.onComplete = endSong.bind();
		inst.persist = true;

		(Conductor.instance = conductor = new Conductor()).mapTimeChanges(chart.timeChanges, false);

		for (event in chart.events) events.add(event);
		events.refresh();

		modules.eventPost(event);
		event.put();
	}

	function initCameras() {
		final event = modules.event(ModuleEvent.get(InitCameras, false).recycle());
		if (event.cancelled) return event.put();

		cameraFollowPoint = FlxPoint.get();
		cameraFollowPosition = FlxPoint.get();

		camGame = new PlayCamera(conductor);
		camLogic = new PlayCamera(conductor);
		camHUD = new PlayCamera(conductor);
		camOther = new PlayCamera();

		camGame.follow(new FlxObject(0, 0), LOCKON, funkinLerp(2.4));

		camHUD.targetZoom = camGame.targetZoom = 1;
		camHUD.zoomLerp = camGame.zoomLerp = funkinLerp(3);

		camGame.bopStrength = 0.015;
		camHUD.bopStrength = 0.03;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camLogic, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		modules.eventPost(event);
		event.put();
	}

	function initCharacters() {
		final event = modules.event(ModuleEvent.get(InitCharacters, false).recycle());
		if (event.cancelled) return event.put();

		for (data in chart.characters) addCharacter(Character.makeWithDefault(data.character, conductor, data.ID));

		modules.eventPost(event);
		event.put();
	}

	function initStage() {
		final event = modules.event(ModuleEvent.get(InitStage, false).recycle());
		if (event.cancelled) return event.put();

		add(stage = Stage.makeWithDefault(chart.stage));
		stage.create();
		stage.applyPlayState();

		if (stage.centerPosition != null) cameraFollowPoint.copyFrom(stage.centerPosition);

		modules.eventPost(event);
		event.put();
	}

	function initHUD() {
		final event = modules.event(ModuleEvent.get(InitHUD, false).recycle());
		if (event.cancelled) return event.put();

		// TODO: make downscroll a property variable on playstate?
		final downscroll = Save.settings.downscroll;

		//scoreLabel = new BLText();

		final healthMeterYPos = downscroll ? 64 : FlxG.height - 64;
		healthMeter = new HealthMeter(0, healthMeterYPos, conductor, skin, bf?.getHealthIcon(), dad.getHealthIcon());
		if (!downscroll) healthMeter.y -= healthMeter.height;
		healthMeter.screenCenter(X);
		healthMeter.camera = camHUD;
		add(healthMeter);

		countdown = new Countdown(conductor, skin);
		countdown.camera = camHUD;
		add(countdown);

		modules.eventPost(event);
		event.put();
	}

	function initPlayfields() {
		final event = modules.event(ModuleEvent.get(InitPlayfields, false).recycle());
		if (event.cancelled) return event.put();

		final voicesByKey:Map<String, FlxSound> = [];
		for (data in chart.playfields) {
			final key = data.voice ?? '';
			var voice = voicesByKey.get(key);
			if (voice == null) {
				voicesByKey.set(key, voice = chart.buildVoice(key));
				vocals.add(voice);
			}

			if (data.x == null) data.x = switch (data.ID) {
				case BF: 0.75;
				case DAD: 0.25;
				case GF: 0.5;
				default: 0;
			}
			if (data.y == null) data.y = 0.5;
			final playfield = new Playfield(FlxG.width * data.x, FlxG.height * data.y, data.ID, getCharactersFromID(data.ID),
				voice, (data.skin != null ? Skin.getSkin(data.skin) : null) ?? skin, data.keys
			);
			for (note in data.notes) playfield.makeNote(note);

			playfield.visible = data.visible;
			playfield.flipX = data.flipX;
			playfield.flipY = data.flipY;
			playfield.speed = data.speed;
			playfield.camera = camLogic;

			add(playfield);
			playfields.push(playfield);

			if (data.ID == BF) {
				playfield.ghostTap = Save.settings.ghostTap;
				playfield.hitSoundVolume = Save.settings.hitSound;
				players.push(playfield);
			}
			else {
				playfield.autoPlay = true;
				playfield.judgmentArea.visible = false;
				playfield.spawnSplashes = false;
			}

			if (playfield.legacyJudgment = Save.settings.judgmentWorldSpace) add(playfield.judgmentArea);
		}

		// Make a temporary playfield
		if (player == null) {
			players.push(new Playfield(FlxG.width * 0.5, FlxG.height * 0.5, BF, getCharactersFromID(BF), skin, playfields[0]?.keys ?? 4));
			player.camera = camLogic;
			player.ghostTap = true;
			player.visible = false;
			playfields.push(player);
		}

		modules.eventPost(event);
		event.put();
	}

	function handleColumnInputPressed(column:Int, ticks:Float) @:privateAccess {
		final time = conductor.songPosition + ticks - columnInputManager.ticks;
		for (player in players) if (!player.autoPlay && !player.ignoreInputs) player.press(column, time);
	}

	function handleColumnInputReleased(column:Int, ticks:Float) @:privateAccess {
		final time = conductor.songPosition + ticks - columnInputManager.ticks;
		for (player in players) if (!player.autoPlay && !player.ignoreInputs) player.release(column, time);
	}

	public function changeStage(stage:Stage, applyCamera = false) {
		final characterBackups = spliceCharacter(0, characters.length, false);

		this.stage = FlxDestroyUtil.destroy(this.stage);

		for (character in characterBackups) addCharacter(character);

		insert(0, this.stage = stage);
		stage.create();
		stage.applyPlayState();

		if (stage.centerPosition != null && applyCamera) cameraFollowPoint.copyFrom(stage.centerPosition);

		stage.postCreate();
	}

	#if !hscript inline #end public function addCharacter(character:Character, ?apply:Bool) insertCharacter(character, apply);

	public function removeCharacter(idx:Int, destroy = true):Character {
		var character = characters[idx];
		characters.swapAndPop(idx);

		for (playfield in playfields) if (playfield.characters.contains(character)) playfield.characters.remove(character);
		character.container?.remove(character, true);
		if (destroy) character.destroy();
		return character;
	}

	public function spliceCharacter(idx:Int, len:Int, destroy = true):Array<Character> {
		var removed = characters.splice(idx, len);
		for (character in removed) {
			for (playfield in playfields) if (playfield.characters.contains(character)) playfield.characters.remove(character);
			character.container?.remove(character, true);
			if (destroy) character.destroy();
		}
		return removed;
	}

	public function assignCharacter(character:Character) {
		switch(character.ID) {
			case BF:
				bf = character;
				if (healthMeter != null) healthMeter.iconP1 = character.getHealthIcon();
			case DAD:
				dad = character;
				if (healthMeter != null) healthMeter.iconP2 = character.getHealthIcon();
			case GF:
				gf = character;
		}

		for (playfield in playfields) {
			if (playfield.ID == character.ID) {
				if (!playfield.characters.contains(character)) playfield.characters.push(character);
			}
			else if (playfield.characters.contains(character)) playfield.characters.remove(character);
		}
	}

	public function insertCharacter(?idx:Int, character:Character, apply = true) {
		if (characters.indexOf(character) == -1) {
			if (idx != null) characters.insert(idx, character);
			else characters.push(character);
		}
		assignCharacter(character);

		if (apply) {
			add(character);
			if (character.conductor == null) character.conductor = conductor;
			if (stage != null) {
				stage.applyCharacter(character);
				stage.sortCharacters(characters);
			}
		}
	}

	public function replaceCharacter(idx:Int, character:Character, apply = true) {
		var old = characters[idx], container = null, m = 0;
		if (old != null) {
			for (playfield in playfields) if (playfield.characters.contains(old)) playfield.characters.remove(old);

			container = old.container;
			m = container.members.indexOf(old);

			if (apply) {
				character.ID = old.ID;
				character.conductor = old.conductor;
			}
			old.destroy();
		}
		else if (apply && character.conductor == null) character.conductor = conductor;
		characters[idx] = character;

		assignCharacter(character);

		if (container != null) container.insert(m, character);
		else if (apply) add(character);

		if (apply && stage != null) {
			stage.applyCharacter(character);
			//stage.sortCharacters(characters);
		}
		if (cameraFollowCharacter == old) cameraFollowCharacter = character;
	}

	public function getCharactersFromID(id:Int, ?arr:Array<Character>):Array<Character> {
		if (arr == null) arr = [];
		for (character in characters) if (character.ID == id) arr.push(character);
		return arr;
	}

	public function getCharacterFromID(id:Int):Null<Character> {
		for (character in characters) if (character.ID == id) return character;
		return null;
	}

	public function getPlayfieldsFromID(id:Int, ?arr:Array<Playfield>):Array<Playfield> {
		if (arr == null) arr = [];
		for (playfield in playfields) if (playfield.ID == id) arr.push(playfield);
		return arr;
	}

	public function getPlayfieldFromID(id:Int):Playfield {
		for (playfield in playfields) if (playfield.ID == id) return playfield;
		return null;
	}

	public function getCharacterCameraTargetPosition(character:Character, ?point:FlxPoint, directionStrength = 1.0):Float {
		if (character == null) return stage.defaultZoom;
		else if (point == null) return stage.defaultZoom * character.cameraZoomTarget;

		final sx = character.scale.x * (character.stageFlipX ? -1 : 1);
		final sy = character.scale.y * (character.stageFlipY ? -1 : 1);

		point.set(
			character.x + character.cameraFocus.x * sx + (character.stagePosition?.camX ?? 0),
			character.y + character.cameraFocus.y * sy + (character.stagePosition?.camY ?? 0)
		);

		if (directionStrength != 0 && character.singing) {
			final p = character.cameraFocusDirection.get(character.currentDirection);
			if (p != null) point.add(p.x * directionStrength * sx, p.y * directionStrength * sy);
		}

		return stage.defaultZoom * character.cameraZoomTarget;
	}

	public function updateCameraFollow() {
		if (cameraFollowCharacter != null) {
			cameraFollowZoom = getCharacterCameraTargetPosition(cameraFollowCharacter, cameraFollowPoint, followDirectionStrength);
			if (cameraFollowCharacters != null && cameraFollowCharacters.length > 0) {
				final p = FlxPoint.weak();
				for (followChar in cameraFollowCharacters) {
					cameraFollowZoom += (getCharacterCameraTargetPosition(followChar.character, p, followDirectionStrength) - cameraFollowZoom) * followChar.lerp;
					cameraFollowPoint.add((p.x - cameraFollowPoint.x) * followChar.lerp);
				}
				p.putWeak();
			}
		}

		if (followCamera) {
			camGame.target.setPosition(cameraFollowPoint.x + cameraFollowPosition.x, cameraFollowPoint.y + cameraFollowPosition.y);
			camGame.targetZoom = (cameraFollowZoomDirect ?? cameraFollowZoom) * cameraFollowZoomMultiply;
		}
	}

	public function setHealthRange(min = 0.0, max = 2.0) {
		healthMeter.setRange(player.minHealth = min, player.maxHealth = max);
	}

	public function changeSkin(skin:Skin) {
		this.skin = skin;
		if (healthMeter != null) healthMeter.skin = skin;
		if (countdown != null) countdown.skin = skin;
	}

	public function freeze() {
		camGame.freeze();
		camLogic.freeze();
		camHUD.freeze();
	}

	public function unfreeze() {
		camGame.unfreeze();
		camLogic.unfreeze();
		camHUD.unfreeze();
	}

	// pause & gotoPause is different thing!
	public function pause() {
		if (paused) return;

		final event = modules.event(ModuleEvent.get(Pause, false).recycle());
		if (event.cancelled) return event.put();

		paused = true;

		inst.pause();
		vocals.pause();

		FlxTimer.globalManager = globalTimerManager;
		FlxTween.globalManager = globalTweenManager;

		columnInputManager.paused = true;

		modules.eventPost(event);
		event.put();
	}

	public function resume(fromPauseMenu = false) {
		if (!paused) return;

		final event = modules.event(ModuleEvent.get(Resume, false).recycle(fromPauseMenu));
		if (event.cancelled) return event.put();

		paused = false;

		inst.resume();
		vocals.resume();

		FlxTimer.globalManager = timerManager;
		FlxTween.globalManager = tweenManager;

		columnInputManager.paused = false;

		modules.eventPost(event);
		event.put();
	}

	public function startCountdown() {
		final startTime = startTimestamp - countdown.getBeats() * conductor.getBeatLength(conductor.timeChanges[0]);
		final event = modules.event(ModuleEvent.get(StartCountdown, false).recycle(startTime));
		if (event.cancelled) return event.put();

		countdown.start(timePosition = startTime);
		allowPause = allowInput = startingSong = true;

		modules.eventPost(event);
		event.put();
	}

	public function startSong() {
		final event = modules.event(ModuleEvent.get(StartSong, false).recycle());
		if (event.cancelled) return event.put();

		startingSong = false;
		countdown.stop();

		final time = Math.max(0, startTimestamp - conductor.offset);
		vocals.pitch = inst.pitch = playbackRate;
		inst.play(time);
		vocals.play(time);

		modules.eventPost(event);
		event.put();
	}

	public function endSong() {
		final event = modules.event(ModuleEvent.get(EndSong, false).recycle());
		if (event.cancelled) return event.put();

		inst.stop();
		vocals.stop();

		player.tallies.lastHealth = player.health;
		player.tallies.lastDeaths = deathCounter;
		(prevTallies = prevTallies ?? []).push(player.tallies);

		gotoNext();

		modules.eventPost(event);
		event.put();
	}

	public function exit() {
		final event = modules.event(ModuleEvent.get(ExitPlay).recycle(storyMode, isSubstate));
		if (event.cancelled) return;

		if (isSubstate) super.close();
		else if (storyMode) FlxG.switchState(bl.state.menu.StoryMenuState.new);
		else FlxG.switchState(bl.state.menu.FreeplayState.new);
	}

	public function gotoNext() {
		final event = modules.event(ModuleEvent.get(NextSong, false).recycle());
		if (event.cancelled) return event.put();

		if (playlist == null || playlist.length == 0) exit();
		else {
			BLState.skipNextTransOut = true;
			final point = (previousCameraFollowPoint ?? FlxPoint.get()).set(
				camGame.scroll.x + camGame.width * 0.5,
				camGame.scroll.y + camGame.height * 0.5
			);
			previousCameraFollowPoint = null;
			playNext({
				freezeBackground: true,
				cameraFollowPoint: point
			});
		}

		modules.eventPost(event);
		event.put();
	}

	public function gotoPause() {
		final event = modules.event(ModuleEvent.get(PauseMenu, false).recycle());
		if (event.cancelled) return event.put();

		pause();
		freeze();
		updateDiscordPresence();

		persistentDraw = true;
		persistentUpdate = false;

		final subState = new PauseSubState();
		subState.cameras = [camOther];
		openSubState(subState);

		modules.eventPost(event);
		event.put();
	}

	public function gotoGameOver() {
		final event = modules.event(ModuleEvent.get(GameOver, false).recycle());
		if (event.cancelled) return event.put();

		pause();

		dead = true;
		deathCounter++;
		updateDiscordPresence();

		persistentDraw = false;
		persistentUpdate = false;

		openSubState(new GameOverSubState(bf, stage));

		modules.eventPost(event);
		event.put();
	}

	public function checkDeath():Bool {
		if ((allowDeath && player.health <= player.minHealth) || (allowInput && allowDeath && controls.justPressed.RESET)) {
			gotoGameOver();
			return true;
		}
		return false;
	}

	override function beatHit():Bool {
		if (!super.beatHit()) return false;

		vocals.resync(inst.getActualTime());
		updateDiscordPresence();

		return true;
	}

	override function measureHit():Bool {
		if (!super.measureHit()) return false;

		return true;
	}

	override function metronomeHit(measureTicked:Bool):Bool {
		if (!super.metronomeHit(measureTicked)) return false;

		return true;
	}

	override function resetSubState() {
		final prevSubState = subState;
		super.resetSubState();

		if (subState == null) {
			if (prevSubState is PauseSubState && !(subState is PauseSubState)) {
				resume(true);
				unfreeze();
			}
		}
	}

	override function update(elapsed:Float) {
		if (startingSong) {
			if (!paused) {
				conductor.update(timePosition += elapsed * 1000 * playbackRate, playbackRate * FlxG.timeScale);
				if (timePosition >= startTimestamp) startSong();
			}
		}
		else if (!updateTimePosition) conductor.update(timePosition, playbackRate * FlxG.timeScale);
		else if (inst.playing) {
			conductor.update(inst.time - offset, inst.getActualPitch());
			timePosition = conductor.songPosition;
		}

		events.update(timePosition, elapsed);

		super.update(elapsed);
		updateCameraFollow();

		if (!paused) {
			if (timerManager.active) timerManager.update(elapsed);
			if (tweenManager.active) tweenManager.update(elapsed);
		}

		healthMeter.target = player.health;
		checkDeath();

		if (allowInput) {
			if (allowPause && controls.justPressed.PAUSE) gotoPause();
		}

		if (allowDebug) {
			//if (controls.justPressed.DEBUG_CHARACTER) FlxG.switchState(bl.state.editor.CharacterEditor.new.bind(bf.characterID, true));
			if (FlxG.keys.justPressed.ONE) endSong();
			if (FlxG.keys.justPressed.TWO) player.autoPlay = !player.autoPlay;
			if (FlxG.keys.justPressed.THREE) allowDeath = !allowDeath;
			if (FlxG.keys.justPressed.LBRACKET) playbackRate -= 0.25;
			if (FlxG.keys.justPressed.RBRACKET) playbackRate += 0.25;
		}
	}


	override function onFocus() {
		lostFocus = false;
		updateDiscordPresence();
	}

	override function onFocusLost() {
		lostFocus = true;
		updateDiscordPresence();

		if (Save.settings.lostFocusPause) gotoPause();
	}

	override function destroy() {
		for (character in characters) character.destroy();
		characters = null;

		super.destroy();
		stage.destroy();

		inst.destroy();
		vocals.destroy();
		if (FlxG.sound.music == inst) FlxG.sound.music = null;

		cameraFollowPoint = FlxDestroyUtil.put(cameraFollowPoint);
		cameraFollowPosition = FlxDestroyUtil.put(cameraFollowPosition);
		previousCameraFollowPoint = FlxDestroyUtil.put(previousCameraFollowPoint);

		FlxTimer.globalManager = globalTimerManager;
		FlxTween.globalManager = globalTweenManager;
		timerManager = FlxDestroyUtil.destroy(timerManager);
		tweenManager = FlxDestroyUtil.destroy(tweenManager);

		columnInputManager = FlxDestroyUtil.destroy(columnInputManager);		

		Discord.clearTimestamp();
	}

	function updateDiscordPresence() {
		var prefix = 'Playing ', isPlaying = false;
		if (startingSong) prefix = 'Starting on ';
		else {
			if (dead) prefix = 'Game Over on ';
			else if (paused) prefix = 'Paused on ';
			isPlaying = timePosition > 0 && timePosition < inst.length;
		}

		if (isPlaying) {
			Discord.endTimestamp = Date.now().getTime() / 1000;
			Discord.startTimestamp = Discord.endTimestamp - timePosition / 1000;
		}
		else {
			Discord.clearTimestamp();
		}

		if (discordRPCAlbum == null) discordRPCAlbum = 'album-${song.album}';
		if (discordRPCIcon == null && dad != null) discordRPCIcon = 'icon-${dad.characterID}';

		Discord.changePresence(
			'$prefix ${song.title} (${difficulty})',
			(storyMode ? 'Story Mode' : 'Freeplay'),
			discordRPCAlbum, null,
			discordRPCIcon, null
		);
	}

	function set_playbackRate(value:Float):Float {
		if (inst != null) inst.pitch = value;
		if (vocals != null) vocals.pitch = value;
		return playbackRate = value;
	}
}