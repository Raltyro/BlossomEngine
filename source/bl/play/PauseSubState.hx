package bl.play;

import flixel.group.FlxContainer;
import flixel.text.FlxText;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxStringUtil;

import bl.audio.Music;
import bl.input.TurboActions;
import bl.graphic.SpriteFrameBuffer;
import bl.object.AtlasText;
import bl.play.event.*;

typedef PauseMenuEntry = {
	text:String,
	callback:PauseSubState->Void,
	?filter:PauseSubState->Bool,
	?showHidden:Bool,

	?sprite:AtlasText
}

class PauseSubState extends BLState {
	public static final PAUSE_MENU_ENTRIES:Array<PauseMenuEntry> = [
		{text: 'Resume', callback: (state:PauseSubState) -> state.resume()},
		{text: 'Restart Song', callback: (state:PauseSubState) -> state.restart()},
		//{text: 'Change Difficulty', callback: },
		{text: 'Exit to Menu', callback: (state:PauseSubState) -> state.exit()}
	];

	public static final MUSIC_FINAL_DELAY:Float = 2;
	public static final MUSIC_FINAL_VOLUME:Float = 0.75;
	public static final AUTHOR_FADE_DELAY:Float = 15.0;
	public static final AUTHOR_FADE_DURATION:Float = 0.75;

	public static var instance:PauseSubState;

	public static var musicPath:Null<String>;
	public static function reset() {
		musicPath = null;
	}

	public var entries:Array<PauseMenuEntry>;
	public var previousMenuEntries:Array<Array<PauseMenuEntry>> = [];
	public var previousSelections:Array<Int> = [];

	public var allowInput:Bool;
	public var currentSelection:Int = 0;
	public var turboPREV:TurboActions;
	public var turboNEXT:TurboActions;

	public var previousMenuSprite:FlxSprite;
	public var previousEntryTexts:FlxTypedContainer<AtlasText>;
	public var entryTexts:FlxTypedContainer<AtlasText>;
	public var textBuffer:SpriteFrameBuffer;

	public var metadataLabels:FlxTypedContainer<FlxSprite>;
	public var titleLabel:FlxText;
	public var artistLabel:FlxText;
	public var charterLabel:FlxText;
	public var difficultyLabel:FlxText;
	public var blueballsLabel:FlxText;

	public var music:Music;

	var authorFadeTween:FlxTween;

	public function new() {
		super();
	}

	override function create() {
		instance = this;

		super.create();

		final event = modules.event(ModuleEvent.get(PauseMenuCreate, false).recycle());
		if (event.cancelled) return event.put();

		FlxG.sound.list.add(music = new Music().loadMusic(musicPath ?? PlayState.instance?.bf?.pauseMusicPath ?? Paths.music('breakfast')));
		//(conductor = new Conductor()).attachToMusic(music);
		music.volume = MUSIC_FINAL_VOLUME;

		createMetadataLabels();
		regenerateMenu(PAUSE_MENU_ENTRIES);

		FlxTimer.wait(MUSIC_FINAL_DELAY, () -> if (music != null) music.play());
		FlxTween.color(0.8, bgColor = FlxColor.TRANSPARENT, FlxColor.fromRGB(0, 0, 0, 153), {ease: FlxEase.quartOut, onUpdate: (t) -> bgColor = cast(t, ColorTween).color});

		add(turboPREV = new TurboActions([controls.controls.get(UI_UP), controls.controls.get(UI_LEFT)]));
		add(turboNEXT = new TurboActions([controls.controls.get(UI_DOWN), controls.controls.get(UI_RIGHT)]));
		allowInput = true;

		modules.eventPost(event);
		event.put();
	}

	function createMetadataLabels() {
		add(metadataLabels = new FlxTypedContainer<FlxSprite>());

		metadataLabels.add(titleLabel = new BLText(0, 20, PlayState.instance?.song.title ?? '', 32));
		metadataLabels.add(artistLabel = new BLText(0, 52, 'Artist: ${PlayState.instance?.song.artist ?? "Unknown"}', 32));
		metadataLabels.add(charterLabel = new BLText(0, 52, 'Charter: ${PlayState.instance?.song.charter ?? "Unknown"}', 32));
		charterLabel.visible = false;

		metadataLabels.add(difficultyLabel = new BLText(0, 84, 'Difficulty: ${FlxStringUtil.toTitleCase(PlayState.instance?.chart.difficulty ?? "Unknown")}', 32));
		metadataLabels.add(blueballsLabel = new BLText(0, 116, '${PlayState.deathCounter} Blue balls', 32));

		var delay = 0.1;
		metadataLabels.forEachExists((label) -> {
			label.setPosition(FlxG.width - 20 - label.width, label.y);
			if (!label.visible) return;

			label.alpha = 0;
			label.y -= 5;

			FlxTween.tween(label, {alpha: 1, y: label.y + 5}, 1.8, {ease: FlxEase.quartOut, startDelay: delay});
			delay += 0.1;
		});

		startLabelCharter();
	}

	function startLabelCharter() {
		authorFadeTween = FlxTween.tween(artistLabel, {alpha: 0}, AUTHOR_FADE_DURATION, {startDelay: AUTHOR_FADE_DELAY, ease: FlxEase.quartOut, onComplete: (_) -> {
			artistLabel.visible = false;
			charterLabel.visible = true;
			charterLabel.alpha = 0;
			authorFadeTween = FlxTween.tween(charterLabel, {alpha: 1}, AUTHOR_FADE_DURATION, {ease: FlxEase.quartOut, onComplete: (_) -> startLabelArtist()});
		}});
	}

	function startLabelArtist() {
		authorFadeTween = FlxTween.tween(charterLabel, {alpha: 0}, AUTHOR_FADE_DURATION, {startDelay: AUTHOR_FADE_DELAY, ease: FlxEase.quartOut, onComplete: (_) -> {
			charterLabel.visible = false;
			artistLabel.visible = true;
			artistLabel.alpha = 0;
			authorFadeTween = FlxTween.tween(artistLabel, {alpha: 1}, AUTHOR_FADE_DURATION, {ease: FlxEase.quartOut, onComplete: (_) -> startLabelCharter()});
		}});
	}

	function regenerateMenu(menuEntries:Array<PauseMenuEntry>) {
		final event = modules.event(ModuleEvent.get(RegeneratePauseMenu, false).recycle(menuEntries));
		if (event.cancelled) return event.put();

		currentSelection = 0;

		if (entryTexts == null) add(entryTexts = new FlxTypedContainer<AtlasText>());
		else {
			for (texts in entryTexts) texts.kill();
			entryTexts.clear();
		}

		entries = [];
		var idx = 0, hidden = false;
		for (entry in menuEntries) {
			if (entry != null && (!(hidden = (entry.filter != null && !entry.filter(this) || entry.callback == null)) || entry.showHidden)) {
				final text = entryTexts.recycle(AtlasText, () -> new AtlasText(entry.text, AtlasFont.BOLD));
				text.text = entry.text;

				entryTexts.add(text);
				entries.push({
					sprite: text,
					text: entry.text,
					callback: hidden ? null : entry.callback,
					filter: entry.filter,
					showHidden: hidden
				});

				text.ID = idx++;
			}
		}

		final selection = currentSelection;
		currentSelection = -3;
		updateEntriesPosition(true);
		currentSelection = selection;
		updateEntriesPosition();

		modules.eventPost(event);
		event.put();
	}

	function updateEntriesPosition(immediate = false) {
		entryTexts.forEachExists((text) -> {
			final entry = entries[text.ID];

			text.alpha = (currentSelection == text.ID ? 1 : 0.6) * ((entry?.showHidden ?? true) ? 0.6 : 1);
			final x = FlxMath.remapToRange((text.ID - currentSelection), 0, 1, 0, 1.3) * 20 + 90,
				y = FlxMath.remapToRange((text.ID - currentSelection), 0, 1, 0, 1.3) * 120 + (FlxG.height * 0.5);

			FlxTween.cancelTweensOf(text);
			if (immediate) text.setPosition(x, y);
			else FlxTween.tween(text, {x: x, y: y}, 0.6, {ease: FlxEase.quintOut});
		});
	}

	function changeSelection(change:Int = 0) {
		final prev = currentSelection;
		if ((currentSelection = FlxMath.wrap(currentSelection + change, 0, entries.length - 1)) != prev)
			SoundUtil.playSfx(Paths.sound('scrollMenu'));

		updateEntriesPosition();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (allowInput) {
			if (turboPREV.activated) changeSelection(-1);
			if (turboNEXT.activated) changeSelection(1);

			if (controls.justPressed.ACCEPT) {
				if (entries[currentSelection]?.callback != null)
					entries[currentSelection].callback(this);
				else
					SoundUtil.playSfx(Paths.sound('locked'));
			}
			else if (controls.justPressed.PAUSE) {
				resume();
			}
		}
	}

	override function destroy() {
		super.destroy();

		FlxG.sound.list.remove(music);
		music = FlxDestroyUtil.destroy(music);
		if (authorFadeTween != null) authorFadeTween.cancel();
		authorFadeTween = null;
	}

	public function resume() {
		close();
	}

	public function restart() {
		 FlxG.resetState(); // TODO: make it so it doesnt reset the whole state?
	}

	public function exit() {
		close();
		PlayState.instance?.exit();
	}
}