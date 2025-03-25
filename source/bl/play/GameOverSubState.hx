package bl.play;

import bl.audio.Music;
import bl.play.component.Character;
import bl.play.component.Stage;
import bl.play.event.*;

using StringTools;

class GameOverSubState extends BLState {
	public static var instance:GameOverSubState;

	public static var musicPath:Null<String>;
	public static var endMusicPath:Null<String>;
	public static function reset() {
		musicPath = null;
		endMusicPath = null;
	}

	public var character:Character;
	public var stage:Stage;

	public var camGame:PlayCamera;
	public var music:Music;

	public var transitioning:Bool = false;

	public function new(?character:Character, ?stage:Stage) {
		super();
		bgColor = FlxColor.BLACK;

		this.character = character ?? Character.makeWithDefault();
		this.stage = stage;
	}

	override function create() {
		instance = this;

		if (character.deathCharacterID != null) {
			character = Character.makeWithDefault(character.deathCharacterID, character.ID);
			if (stage != null) stage.applyCharacter(character);
		}

		if (stage != null && stage.addInGameOver) {
			add(stage);
			add(character);
			add(stage.foreground);
		}
		else
			add(character);

		super.create();

		final event = modules.event(ModuleEvent.get(GameOverCreate, false).recycle());
		if (event.cancelled) return event.put();

		FlxG.sound.list.add(music = new Music().loadMusic(musicPath ?? character.deathMusicPath ?? Paths.music('gameplay/gameOver')));
		(conductor = new Conductor()).attachToMusic(music);

		character.specialAnim = true;
		character.playAnim('firstDeath', true);
		FlxG.sound.play(character.deathSFXPath ?? Paths.sound('fnf_loss_sfx', 'shared'));

		if (camera is PlayCamera) {
			(camGame = cast camera).conductor = conductor;
			camGame.bopStrength = 0;
		}
		else {
			FlxG.cameras.reset(camera = camGame = new PlayCamera(conductor));
			camGame.follow(new FlxObject(0, 0), LOCKON, funkinLerp(2.4));
			camGame.targetZoom = 1;
			camGame.zoomLerp = funkinLerp(3);
		}

		FlxTimer.wait(0.4, () -> {
			if (!exists) return;

			final point = FlxPoint.get();
			camGame.targetZoom = getCharacterCameraTargetPosition(point);
			camGame.target.setPosition(point.x, point.y);
			point.put();
		});

		modules.eventPost(event);
		event.put();
	}

	public function getCharacterCameraTargetPosition(?point:FlxPoint):Float {
		if (point == null) return stage.defaultZoom * character.cameraZoomTarget;

		final sx = character.scale.x * ((character.stageFlipX ?? false) ? -1 : 1);
		final sy = character.scale.y * ((character.stageFlipY ?? false) ? -1 : 1);

		point.set(
			character.x + character.deathCameraFocus.x * sx,
			character.y + character.deathCameraFocus.y * sy
		);

		return stage.defaultZoom * character.cameraZoomTarget;
	}

	override function update(elapsed:Float) {
		conductor.update(music.time, music.getActualPitch());

		if (!transitioning) {
			if (character.curAnim.name.startsWith('firstDeath') && character.curAnim.finished) {
				music.play();
				character.playAnim('deathLoop');
			}

			if (controls.justPressed.ACCEPT) {
				transitioning = true;

				music.loadMusic(endMusicPath ?? character.deathEndMusicPath ?? Paths.music('gameplay/gameOverEnd'), true).play();
				music.persist = true;
				music.looped = false;

				character.playAnim('deathConfirm', true);
				camGame.fade(FlxColor.BLACK, 3, () -> {
					FlxTimer.wait(0.25, () -> if (exists) FlxG.resetState()); // TODO: make it so it doesnt reset the whole state?
				}, true);
			}
			else if (controls.justPressed.BACK) PlayState.instance?.exit();
		}

		super.update(elapsed);
	}

	override function destroy() {
		remove(character);
		remove(stage);

		FlxG.sound.list.remove(music);
		if (!transitioning) music.destroy();

		super.destroy();
	}
}