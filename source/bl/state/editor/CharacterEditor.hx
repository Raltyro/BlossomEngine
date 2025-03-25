package bl.state.editor;

import flixel.addons.ui.*;
import flixel.ui.*;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.text.FlxInputText;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;

import haxe.Json;
//import hxjson5.Json5;

import bl.data.Skin;
import bl.data.Song.ChartCharacterID;
import bl.input.TurboActions.TurboKeys;
import bl.play.component.Character;
import bl.play.component.HealthMeter;
import bl.play.component.Stage;
import bl.play.*;
import bl.state.ConfirmationSubState;
import bl.BLSprite.BLAnimData;

using StringTools;

typedef AnimCache = BLAnimData & {?changed:Bool, ?missing:Bool}

class CharacterEditor extends BLStateUI {
	public static inline final UNHIGHLIGHTED_COLOR = 0xFFDDDDDD;
	public static inline final HIGHLIGHTED_COLOR = 0xFFFFFFFF;
	public static inline final UNHIGHLIGHTED_YELLOW_COLOR = 0xFFBBBB00;
	public static inline final HIGHLIGHTED_YELLOW_COLOR = 0xFFFFFF00;
	public static inline final UNHIGHLIGHTED_RED_COLOR = 0xFFBB0000;
	public static inline final HIGHLIGHTED_RED_COLOR = 0xFFFF0000;
	public static inline final LABELS_Y_INTERVAL = 22;
	public static inline final LABELS_Y = 308;
	
	public static final SORT_ANIMATIONS = [
		'idle',
		'danceLeft',
		'danceRight',
		'singLEFTmiss',
		'singDOWNmiss',
		'singUPmiss',
		'singRIGHTmiss',
		'singLEFT',
		'singDOWN',
		'singUP',
		'singRIGHT',
		'hey',
		'firstDeath',
		'deathLoop',
		'deathConfirm'
	];

	public static var notFirstTime:Bool = false;

	var charInitial:String;
	var stageInitial:String = 'stage';
	var wasInPlayState:Bool;

	var stage:Stage;
	var character:Character;
	var ghostCharacter:Character;
	var camGame:PlayCamera;
	var healthMeter:HealthMeter;

	var changedSomething:Bool;
	var characterID:String;
	var characterName:String;
	var characterImage:String;

	var invalidCharacter(default, set):Bool;
	var invalidGhostCharacter(default, set):Bool;
	var useGameOverPivot(default, set):Bool;
	var charPos(default, set):ChartCharacterID = BF;
	var ghostCharPos(default, set):ChartCharacterID = BF;
	var iconColor(default, set):FlxColor;
	var charAnims:Array<AnimCache>;
	var ghostCharAnims:Array<AnimCache>;
	var ghostCharAnimKeys:Map<String, Int>;

	var mousePosition:FlxPoint;
	var mouseLastPosition:FlxPoint;
	var turboA:TurboKeys;
	var turboS:TurboKeys;
	var turboW:TurboKeys;
	var turboD:TurboKeys;
	var turboLEFT:TurboKeys;
	var turboDOWN:TurboKeys;
	var turboUP:TurboKeys;
	var turboRIGHT:TurboKeys;

	var changeCallbacks:Map<String, Void->Void> = [];
	var characterChange:FlxSignal = new FlxSignal();
	var animChange:FlxSignal = new FlxSignal();
	var ghostCharacterChange:FlxSignal = new FlxSignal();

	var charMenu:FlxUITabMenu;
	var mainMenu:FlxUITabMenu;
	var charIDBox:FlxUIInputText;

	var ghostMenu:FlxUITabMenu;
	var ghostCharIDBox:FlxUIInputText;

	var curAnimIdx:Int;
	var curAnimLabel:FlxText;
	var curGhostAnimIdx:Int;
	var curGhostAnimLabel:FlxText;
	var charAnimLabelGroup:FlxTypedGroup<FlxText>;
	var charAnimLabels:Map<String, FlxText> = [];

	var fuck:FlxUIButton;

	public function new(characterID = 'bf', inPlayState = false) {
		super();

		charInitial = characterID;
		wasInPlayState = inPlayState;
		if (FlxG.state is PlayState) stageInitial = PlayState.instance.chart.stage;
	}

	override function create() {
		super.create();

		Main.statsCounter.visible = false;

		FlxG.cameras.insert(camGame = new PlayCamera(conductor), 0, false);
		camGame.follow(new FlxObject(0, 0), LOCKON, 1);

		add(charAnimLabelGroup = new FlxTypedGroup<FlxText>());
		add(curAnimLabel = new BLText(514, 10, '', 'vcr', 26));
		add(curGhostAnimLabel = new BLText(514, 38, '', 'vcr', 26));
		curGhostAnimLabel.alpha = .6;

		add(healthMeter = new HealthMeter(conductor, Skin.getSkin('default')));
		healthMeter.setPosition(FlxG.width - healthMeter.width - 70, FlxG.height - healthMeter.height - 50);

		changeStage(stageInitial);
		changeCharacter(charInitial);
		characterID = character.characterID;
		characterName = character.characterName;
		resetCamera();

		add(charMenu = new FlxUITabMenu([
			{name: 'char', label: 'Character'},
			{name: 'anim', label: 'Animations'},
			{name: 'oth', label: 'Other'}
		], true));
		charMenu.setPosition(10, 10);
		charMenu.resize(270, 294);
		buildAnimTab();
		buildCharTab();
		buildOtherTab();
		animChange.dispatch();

		add(mainMenu = new FlxUITabMenu([{name: 'set', label: 'Settings'}], true));
		mainMenu.setPosition(290, 10);
		mainMenu.resize(220, 162);
		buildMainMenu();

		add(ghostMenu = new FlxUITabMenu([{name: 'ghost', label: 'Ghost Settings'}], true));
		ghostMenu.setPosition(290, 182);
		ghostMenu.resize(220, 122);
		buildGhostMenu();

		mousePosition = FlxPoint.get();
		mouseLastPosition = FlxPoint.get();
		add(turboA = new TurboKeys([A], 0.4, 0.02));
		add(turboS = new TurboKeys([S], 0.4, 0.02));
		add(turboW = new TurboKeys([W], 0.4, 0.02));
		add(turboD = new TurboKeys([D], 0.4, 0.02));
		add(turboLEFT = new TurboKeys([LEFT], 0.4, 0.02));
		add(turboDOWN = new TurboKeys([DOWN], 0.4, 0.02));
		add(turboUP = new TurboKeys([UP], 0.4, 0.02));
		add(turboRIGHT = new TurboKeys([RIGHT], 0.4, 0.02));

		updateWindowTitle();

		if (!notFirstTime) {
			openSubState(new ConfirmationSubState("Controls for the Character Editor
A, S, W, D to change the offset
Alt + (A, S, W, D) to change origin offset
LEFT, DOWN, UP, RIGHT to change current camera focus pos
C to switch camera focus pivot (normal, game over)
Ctrl + (W, S) to change current animation
Ctrl + (A, S) to change current ghost animation
Q, E or Mouse Scroll Wheel to zoom in/out
R, T to reset camera (T set's the camera to character focus camera)
F to re-play the current animation", ""));
		}
		notFirstTime = true;
	}

	function resetCamera() @:privateAccess {
		camGame.target.setPosition(character.x - FlxG.width / 4.5, character.y - Math.min(character.getSourceSizeY() / 2.5, FlxG.height / 2));
		camGame.zoom = 1;
	}
	//camGame.target.setPosition(stage.centerPosition.x, stage.centerPosition.y);

	function changeStage(stageID:String):Bool {
		if (stage != null) stage.destroy();

		// Some stages aren't build to work with Editors
		final exists = (stage = Stage.make(stageID)) != null;
		insert(0, stage = stage ?? Stage.makeWithDefault()).camera = camGame;
		if (stage.foreground != null) stage.foreground.camera = camGame;
		try {stage.create();} catch(e) {trace(e);}
		try {stage.postCreate();} catch(e) {trace(e);}

		charPos = charPos;
		ghostCharPos = ghostCharPos;
		if (ghostCharacter != null) ghostCharacterChange.dispatch();
		if (character != null) resetCamera();

		return exists;
	}

	function changeCharacter(charID:String) {
		if (character != null) character.destroy();

		AssetUtil.regetText(Paths.character(charID));
		invalidCharacter = (character = Character.make(charID, conductor)) == null;
		insert(members.indexOf(stage) + 1, character = character ?? Character.makeWithDefault(conductor)).camera = camGame;
		character.cameraPivotUseGameOver = useGameOverPivot;
		character.dontPlayLoop = character.specialAnim = character.showCameraPivot = character.showPivot = true;

		characterImage = character is CustomCharacter ? cast(character, CustomCharacter).characterData.image : character.graphic?.key;
		characterName = character.characterName;
		charPos = charPos;

		healthMeter.iconP1 = character.getHealthIcon();
		@:bypassAccessor iconColor = healthMeter.iconP1.iconColor;

		fetchCharAnims();

		updateWindowTitle();
	}

	function changeGhostCharacter(charID:String) {
		if (ghostCharacter != null) ghostCharacter.destroy();

		AssetUtil.regetText(Paths.character(charID));
		invalidGhostCharacter = (ghostCharacter = Character.make(charID, conductor)) == null;
		insert(members.indexOf(character) + 1, ghostCharacter = ghostCharacter ?? Character.makeWithDefault(conductor)).camera = camGame;
		ghostCharacter.cameraPivotUseGameOver = useGameOverPivot;
		character.dontPlayLoop = ghostCharacter.specialAnim = true;

		healthMeter.iconP2 = ghostCharacter.getHealthIcon();
		fetchGhostCharAnims();
		ghostCharPos = ghostCharPos;
	}

	function changeCharacterImage(image:String) {
		if (characterImage == image) return;
		characterImage = image;

		CoolUtil.suppressWarning();
		character.loadAnimGraphic(image, charAnims);
		character.loadPendingAnimations();
		CoolUtil.reviveWarning();

		for (i => anim in charAnims) {
			if (character.animation.getByName(anim.name) == null) {
				charAnimLabels[anim.name].color = curAnimIdx == i ? HIGHLIGHTED_RED_COLOR : UNHIGHLIGHTED_RED_COLOR;
				anim.missing = true;
			}
			else if (anim.missing) {
				anim.missing = false;
				charAnimLabels[anim.name].color = curAnimIdx == i ?
					(anim.changed ? HIGHLIGHTED_YELLOW_COLOR : HIGHLIGHTED_COLOR) :
					(anim.changed ? UNHIGHLIGHTED_YELLOW_COLOR : UNHIGHLIGHTED_COLOR);
			}
		}
	}

	function updateWindowTitle() CoolUtil.changeWindowTitle(' | Character Editor - $characterID' + (changedSomething ? '*' : '') + ' ($characterName)');

	inline function changeCall(f:Void->Void):Void->Void return () -> {
		if (!changedSomething) {
			changedSomething = true;
			updateWindowTitle();
		}
		else changedSomething = true;
		f();
	};

	inline function buildCharTab() @:privateAccess {
		final group = new FlxUI(null, charMenu);
		group.name = "char";

		group.add(new FlxText(10, 10, 'Character Name & Image', 8));
		final charNameBox = new FlxUIInputText(10, 28, 250, characterName, 8);
		charNameBox.focusLost = changeCall(() -> {
			characterName = charNameBox.text;
			updateWindowTitle();
		});
		characterChange.add(() -> charNameBox.text = characterName);
		group.add(charNameBox);

		final charImageBox = new FlxUIInputText(10, 46, 250, characterImage, 8);
		charImageBox.focusLost = changeCall(() -> {
			if (AssetUtil.graphicExists(charImageBox.text)) {
				charImageBox.color = FlxColor.BLACK;
				changeCharacterImage(charImageBox.text);
			}
			else 
				charImageBox.color = FlxColor.RED;
		});
		characterChange.add(() -> {
			charImageBox.color = FlxColor.BLACK;
			charImageBox.text = characterImage;
		});
		group.add(charImageBox);

		final aa = new FlxUICheckBox(180, 6, null, null, "Antialiasing", 80);
		aa.callback = changeCall(() -> character.antialiasing = aa.checked);
		characterChange.add(() -> aa.checked = character.antialiasing);
		aa.checked = character.antialiasing;
		group.add(aa);

		final originX = new FlxUINumericStepper(10, 68, 1, character.characterOrigin.x);
		changeCallbacks[originX.name = 'originX'] = changeCall(() -> {
			character.characterOrigin.x = originX.value;
			character.updateHitbox();
		});
		characterChange.add(() -> originX.value = character.characterOrigin.x);
		group.add(new FlxText(originX.x + originX.width + 2, 68, 'Origin X', 8));
		group.add(originX);

		final originY = new FlxUINumericStepper(136, 68, 1, character.characterOrigin.y);
		changeCallbacks[originY.name = 'originY'] = changeCall(() -> {
			character.characterOrigin.y = originY.value;
			character.updateHitbox();
		});
		characterChange.add(() -> originY.value = character.characterOrigin.y);
		group.add(new FlxText(originY.x + originY.width + 2, 68, 'Origin Y', 8));
		group.add(originY);

		final scaleX = new FlxUINumericStepper(10, 90, 0.1, character.scale.x, -999, 999, 2);
		changeCallbacks[scaleX.name = 'scaleX'] = changeCall(() -> {
			character.scale.x = scaleX.value;
			character.updateHitbox();
		});
		characterChange.add(() -> scaleX.value = character.scale.x);
		group.add(new FlxText(scaleX.x + scaleX.width + 2, 90, 'Scale X', 8));
		group.add(scaleX);

		final scaleY = new FlxUINumericStepper(136, 90, 0.1, character.scale.y, -999, 999, 2);
		changeCallbacks[scaleY.name = 'scaleY'] = changeCall(() -> {
			character.scale.y = scaleY.value;
			character.updateHitbox();
		});
		characterChange.add(() -> scaleY.value = character.scale.y);
		group.add(new FlxText(scaleY.x + scaleY.width + 2, 90, 'Scale Y', 8));
		group.add(scaleY);

		final flipX = new FlxUICheckBox(10, 112, null, null, "Flip X", 50);
		flipX.callback = changeCall(() -> character.flipX = flipX.checked);
		characterChange.add(() -> flipX.checked = character.flipX);
		flipX.checked = character.flipX;

		final flipY = new FlxUICheckBox(136, 112, null, null, "Flip Y", 50);
		flipY.callback = changeCall(() -> character.flipY = flipX.checked);
		characterChange.add(() -> flipY.checked = character.flipY);
		flipY.checked = character.flipY;

		group.add(flipX);
		group.add(flipY);

		final stroke = new FlxUINumericStepper(10, 158, 0.01, character.strokeTime, -999, 999, 2);
		changeCallbacks[stroke.name = 'stroke'] = changeCall(() -> character.strokeTime = stroke.value);
		characterChange.add(() -> stroke.value = character.strokeTime);
		group.add(new FlxText(stroke.x + stroke.width + 2, 158, 'Stroke Time', 8));
		group.add(stroke);

		final hold = new FlxUINumericStepper(10, 180, 0.5, character.holdInterval, -999, 999, 2);
		changeCallbacks[hold.name = 'hold'] = changeCall(() -> character.holdInterval = hold.value);
		characterChange.add(() -> hold.value = character.holdInterval);
		group.add(new FlxText(hold.x + hold.width + 2, 180, 'Hold Interval', 8));
		group.add(hold);

		final camFocusX = new FlxUINumericStepper(10, 224, 1, character.cameraFocus.x);
		changeCallbacks[camFocusX.name = 'camFocusX'] = changeCall(() -> {
			character.cameraFocus.x = camFocusX.value;
			character.updateHitbox();
		});
		characterChange.add(() -> camFocusX.value = character.cameraFocus.x);
		group.add(new FlxText(camFocusX.x + camFocusX.width + 2, 224, 'Cam X', 8));
		group.add(camFocusX);

		final camFocusY = new FlxUINumericStepper(136, 224, 1, character.cameraFocus.y);
		changeCallbacks[camFocusY.name = 'camFocusY'] = changeCall(() -> {
			character.cameraFocus.y = camFocusY.value;
			character.updateHitbox();
		});
		characterChange.add(() -> camFocusY.value = character.cameraFocus.y);
		group.add(new FlxText(camFocusY.x + camFocusY.width + 2, 224, 'Cam Y', 8));
		group.add(camFocusY);

		function setSourceSize(?x:Float, ?y:Float) {
			if (character.sourceSize == null)
				character.sourceSize = new FlxPoint(character.getSourceSizeX(), character.getSourceSizeY());
			
			if (x != null) character.sourceSize.x = x;
			if (y != null) character.sourceSize.y = y;
		}

		final width = new FlxUINumericStepper(10, 246, 1, character.sourceSize?.x ?? character.getSourceSizeX());
		changeCallbacks[width.name = 'width'] = changeCall(() -> {
			setSourceSize(width.value);
			character.updateHitbox();
		});
		characterChange.add(() -> width.value = character.sourceSize?.x ?? character.getSourceSizeX());
		group.add(new FlxText(width.x + width.width + 2, 246, 'Width', 8));
		group.add(width);

		final height = new FlxUINumericStepper(136, 246, 1, character.sourceSize?.y ?? character.getSourceSizeY());
		changeCallbacks[height.name = 'height'] = changeCall(() -> {
			setSourceSize(null, height.value);
			character.updateHitbox();
		});
		characterChange.add(() -> height.value = character.sourceSize?.y ?? character.getSourceSizeY());
		group.add(new FlxText(height.x + height.width + 2, 246, 'Height', 8));
		group.add(height);

		charMenu.addGroup(group);
	}

	function buildAnimTab() {
		final group = new FlxUI(null, charMenu);
		group.name = "anim";

		group.add(new FlxText(10, 10, 'Animation to Update', 8));
		final animBox = new FlxUIInputText(10, 28, 250, '', 8);
		animChange.add(() -> animBox.text = charAnims[curAnimIdx].name);
		group.add(animBox);

		group.add(new FlxText(10, 50, 'Animation ID', 8));
		final idBox = new FlxUIInputText(10, 68, 250, '', 8);
		animChange.add(() -> idBox.text = charAnims[curAnimIdx].id);
		group.add(idBox);

		final flipX = new FlxUICheckBox(10, 90, null, null, "Flip X", 50);
		animChange.add(() -> flipX.checked = charAnims[curAnimIdx].flipX);
		group.add(flipX);

		final flipY = new FlxUICheckBox(136, 90, null, null, "Flip Y", 50);
		animChange.add(() -> flipY.checked = charAnims[curAnimIdx].flipY);
		group.add(flipY);

		final fps = new FlxUINumericStepper(10, 112, 1, 30, 0, 999);
		animChange.add(() -> fps.value = charAnims[curAnimIdx].fps);
		group.add(new FlxText(fps.x + fps.width + 2, 112, 'FPS', 8));
		group.add(fps);

		final loop = new FlxUICheckBox(136, 112, null, null, "Loop", 50);
		animChange.add(() -> loop.checked = charAnims[curAnimIdx].loop);
		group.add(loop);

		group.add(new FlxText(10, 160, 'Animation Indices (ADVANCED)', 8));
		final indBox = new FlxUIInputText(10, 178, 250, '', 8);
		animChange.add(() -> {
			if (charAnims[curAnimIdx].indices == null)
				indBox.text = '';
			else {
				final str = Std.string(charAnims[curAnimIdx].indices).replace('[', '').replace(']', '');
				indBox.text = str;
			}
		});
		group.add(indBox);

		group.add(new FlxText(10, 200, 'Animation Image (ADVANCED)', 8));
		final imageBox = new FlxUIInputText(10, 218, 250, '', 8);
		animChange.add(() -> {
			final asset = charAnims[curAnimIdx].asset;
			if (asset != null) imageBox.text = cast(asset, String);
			else imageBox.text = '';
		});
		group.add(imageBox);

		final update = new FlxUIButton(136 - 60, 244, 'Update', () -> {
			final indices:Array<Int> = [];
			for (str in indBox.text.replace('[', '').replace(']', '').replace(' ', '').trim().split(',')) {
				final ind = Std.parseInt(str);
				if (ind != null) indices.push(ind);
			}

			var anim:AnimCache = null, i:Int = -1;
			for (idx => o in charAnims) if (o.name == animBox.text) {
				anim = o;
				i = idx;
				break;
			}
			if (anim == null) anim = {name: animBox.text, offset: [0, 0]};
			
			anim.asset = imageBox.text.trim() == '' ? null : imageBox.text;
			anim.id = idBox.text;
			anim.fps = fps.value;
			anim.loop = loop.checked;
			anim.flipX = flipX.checked;
			anim.flipY = flipY.checked;
			anim.indices = indices.length == 0 ? null : indices;
			anim.changed = true;

			CoolUtil.suppressWarning();
			character.addAnim(anim, true);
			CoolUtil.reviveWarning();

			if (i == -1) {
				i = charAnims.length;
				fetchCharAnim(anim.name);
			}

			if (anim.missing = character.animation.getByName(anim.name) == null) {
				charAnimLabels[anim.name].color = curAnimIdx == i ? HIGHLIGHTED_RED_COLOR : UNHIGHLIGHTED_RED_COLOR;
			}
			else {
				if (curAnimIdx == i) character.playAnim(anim.name, true);
				else playAnim(anim.name);
				charAnimLabels[anim.name].color = anim.changed ? HIGHLIGHTED_YELLOW_COLOR : HIGHLIGHTED_COLOR;
			}

			if (!changedSomething) {
				changedSomething = true;
				updateWindowTitle();
			}
			else changedSomething = true;
		});
		update.x -= Math.floor(update.width / 2);
		group.add(update);

		final remove = new FlxUIButton(136 + 60, 244, 'Remove', () -> {
			var removed = false, i = charAnims.length;
			while (--i >= 0) {
				if (charAnims[i].name == animBox.text) {
					removed = true;
					charAnims.swapAndPop(i);
					charAnimLabels[animBox.text].kill();
					charAnimLabels.remove(animBox.text);
				}
			}

			if (removed) {
				character.removeAnim(animBox.text);
				for (i => anim in charAnims)
					charAnimLabels[anim.name].y = LABELS_Y + i * LABELS_Y_INTERVAL;
			
				goAnim(0);
			}
		});
		remove.x -= Math.floor(remove.width / 2);
		group.add(remove);

		charMenu.addGroup(group);
	}

	inline function buildOtherTab() {
		final group = new FlxUI(null, charMenu);
		group.name = "oth";

		group.add(new FlxText(10, 10, 'Icon Image & Colors RGB', 8));
		final iconBox = new FlxUIInputText(10, 28, 250, character.characterIconData?.image ?? '', 8);
		iconBox.focusLost = changeCall(() -> {
			final img = iconBox.text.trim() == '' ? null : iconBox.text;
			if (character.characterIconData != null)
				character.characterIconData.image = img;
			else if (img != null)
				character.characterIconData = {image: img};
		});
		characterChange.add(() -> iconBox.text = character.characterIconData?.image ?? '');
		group.add(iconBox);

		final iconR = new FlxUINumericStepper(10, 58, 1, iconColor.red, 0, 255);
		changeCallbacks[iconR.name = 'iconR'] = changeCall(() -> {
			iconColor.red = Math.floor(iconR.value);
			iconColor = iconColor;
		});
		characterChange.add(() -> iconR.value = iconColor.red);
		group.add(iconR);

		final iconG = new FlxUINumericStepper(106, 58, 1, iconColor.green, 0, 255);
		changeCallbacks[iconG.name = 'iconG'] = changeCall(() -> {
			iconColor.green = Math.floor(iconG.value);
			iconColor = iconColor;
		});
		characterChange.add(() -> iconG.value = iconColor.green);
		group.add(iconG);

		final iconB = new FlxUINumericStepper(203, 58, 1, iconColor.blue, 0, 255);
		changeCallbacks[iconB.name = 'iconB'] = changeCall(() -> {
			iconColor.blue = Math.floor(iconB.value);
			iconColor = iconColor;
		});
		characterChange.add(() -> iconB.value = iconColor.blue);
		group.add(iconB);

		final deathCamFocusX = new FlxUINumericStepper(10, 152, 1, character.cameraFocus.x);
		changeCallbacks[deathCamFocusX.name = 'deathCamFocusX'] = changeCall(() -> {
			character.deathCameraFocus.x = deathCamFocusX.value;
			character.updateHitbox();
		});
		characterChange.add(() -> deathCamFocusX.value = character.deathCameraFocus.x);
		group.add(new FlxText(deathCamFocusX.x + deathCamFocusX.width + 2, 152, 'Cam Death X', 8));
		group.add(deathCamFocusX);

		final deathCamFocusY = new FlxUINumericStepper(136, 152, 1, character.deathCameraFocus.y);
		changeCallbacks[deathCamFocusY.name = 'deathCamFocusY'] = changeCall(() -> {
			character.deathCameraFocus.y = deathCamFocusY.value;
			character.updateHitbox();
		});
		characterChange.add(() -> deathCamFocusY.value = character.deathCameraFocus.y);
		group.add(new FlxText(deathCamFocusY.x + deathCamFocusY.width + 2, 152, 'Cam Death Y', 8));
		group.add(deathCamFocusY);

		group.add(new FlxText(10, 174, 'Game Over Character ID & SFX & Music', 8));
		final deathCharIDBox = new FlxUIInputText(10, 192, 250, character.deathCharacterID ?? '', 8);
		deathCharIDBox.focusLost = changeCall(() -> {
			character.deathCharacterID = deathCharIDBox.text.trim() == '' ? null : deathCharIDBox.text;
		});
		characterChange.add(() -> deathCharIDBox.text = character.deathCharacterID ?? '');
		group.add(deathCharIDBox);

		final deathCharSFXBox = new FlxUIInputText(10, 210, 250, character.deathSFXPath ?? '', 8);
		deathCharSFXBox.focusLost = changeCall(() -> {
			character.deathSFXPath = deathCharSFXBox.text.trim() == '' ? null : deathCharSFXBox.text;
		});
		characterChange.add(() -> deathCharSFXBox.text = character.deathSFXPath ?? '');
		group.add(deathCharSFXBox);

		final deathCharMusicBox = new FlxUIInputText(10, 228, 250, character.deathMusicPath ?? '', 8);
		deathCharMusicBox.focusLost = changeCall(() -> {
			character.deathMusicPath = deathCharMusicBox.text.trim() == '' ? null : deathCharMusicBox.text;
		});
		characterChange.add(() -> deathCharMusicBox.text = character.deathMusicPath ?? '');
		group.add(deathCharMusicBox);

		final deathCharEndMusicBox = new FlxUIInputText(10, 246, 250, character.deathEndMusicPath ?? '', 8);
		deathCharEndMusicBox.focusLost = changeCall(() -> {
			character.deathEndMusicPath = deathCharEndMusicBox.text.trim() == '' ? null : deathCharEndMusicBox.text;
		});
		characterChange.add(() -> deathCharEndMusicBox.text = character.deathEndMusicPath ?? '');
		group.add(deathCharEndMusicBox);

		charMenu.addGroup(group);
	}

	inline function buildMainMenu() {
		final group = new FlxUI(null, mainMenu);
		group.name = "set";

		group.add(new FlxText(10, 10, 'Character ID', 8));
		(charIDBox = new FlxUIInputText(10, 28, 200, characterID, 8)).focusLost = () -> {
			characterID = charIDBox.text;
			updateWindowTitle();
		}
		group.add(charIDBox);

		final reload = fuck = new FlxUIButton(210, 6, 'Reload', reload.bind());
		reload.x -= reload.width;
		group.add(reload);

		final charPosBox = new FlxUINumericStepper(10, 50, 1, charPos);
		changeCallbacks[charPosBox.name = 'charPos'] = () -> charPos = cast Math.floor(charPosBox.value);
		group.add(new FlxText(charPosBox.x + charPosBox.width + 2, 50, 'CharPos', 8));
		group.add(charPosBox);

		final showPivot = new FlxUICheckBox(10, 72, null, null, "Show Pivot", 60);
		showPivot.checked = true;
		showPivot.callback = () -> character.showPivot = showPivot.checked;
		characterChange.add(() -> character.showPivot = showPivot.checked);
		group.add(showPivot);

		final showCamPivot = new FlxUICheckBox(120, 72, null, null, "Show Camera Pivot", 80);
		showCamPivot.checked = true;
		showCamPivot.callback = () -> character.showCameraPivot = showCamPivot.checked;
		characterChange.add(() -> character.showCameraPivot = showCamPivot.checked);
		group.add(showCamPivot);

		final save = new FlxUIButton(210, 48, 'Save', save.bind());
		save.x -= save.width;
		group.add(save);

		group.add(new FlxText(10, 94, 'Stage ID Preview', 8));
		final stageIDBox = new FlxUIInputText(10, 112, 200, stage.stageID, 8);
		stageIDBox.focusLost = () -> if (stageIDBox.text != stage.stageID)
			stageIDBox.color = changeStage(stageIDBox.text) ? FlxColor.BLACK : FlxColor.RED;
		group.add(stageIDBox);

		mainMenu.addGroup(group);
	}

	inline function buildGhostMenu() {
		final group = new FlxUI(null, ghostMenu);
		group.name = "ghost";

		group.add(new FlxText(10, 10, 'Ghost Character ID', 8));
		(ghostCharIDBox = new FlxUIInputText(10, 28, 200, charInitial, 8)).focusLost = () ->
			if (ghostCharacter?.visible) changeGhostCharacter(ghostCharIDBox.text);

		final showGhost = new FlxUICheckBox(120, 6, null, null, "Show Ghost", 60);
		showGhost.callback = () -> {
			if (showGhost.checked && (ghostCharacter == null || ghostCharIDBox.text != ghostCharacter.characterID))
				changeGhostCharacter(ghostCharIDBox.text);
			else
				ghostCharacter.visible = showGhost.checked;
		}

		group.add(ghostCharIDBox);
		group.add(showGhost);

		final alphaBox = new FlxUINumericStepper(10, 50, 10, 30);
		changeCallbacks[alphaBox.name = 'ghostAlpha'] = () -> if (ghostCharacter != null) {
			ghostCharacter.apply(ghostCharacter.stagePosition);
			ghostCharacter.alpha *= alphaBox.value / 100;
		}
		ghostCharacterChange.add(() -> ghostCharacter.alpha *= alphaBox.value / 100);
		group.add(new FlxText(alphaBox.x + alphaBox.width + 2, 50, 'Alpha', 8));
		group.add(alphaBox);

		final charPosBox = new FlxUINumericStepper(10, 72, 1, ghostCharPos);
		changeCallbacks[charPosBox.name = 'ghostCharPos'] = () -> ghostCharPos = cast Math.floor(charPosBox.value);
		group.add(new FlxText(charPosBox.x + charPosBox.width + 2, 72, 'CharPos', 8));
		group.add(charPosBox);

		final showPivot = new FlxUICheckBox(120, 50, null, null, "Show Pivot", 60);
		showPivot.callback = () -> if (ghostCharacter != null) ghostCharacter.showPivot = showPivot.checked;
		ghostCharacterChange.add(() -> ghostCharacter.showPivot = showPivot.checked);
		group.add(showPivot);

		final showCamPivot = new FlxUICheckBox(120, 72, null, null, "Show Camera Pivot", 80);
		showCamPivot.callback = () -> if (ghostCharacter != null) ghostCharacter.showCameraPivot = showCamPivot.checked;
		ghostCharacterChange.add(() -> ghostCharacter.showCameraPivot = showCamPivot.checked);
		group.add(showCamPivot);

		ghostMenu.addGroup(group);
	}

	function set_invalidCharacter(value:Bool) {
		if (charIDBox != null) charIDBox.color = value ? FlxColor.RED : FlxColor.BLACK;
		return invalidCharacter = value;
	}

	function set_invalidGhostCharacter(value:Bool) {
		if (ghostCharIDBox != null) ghostCharIDBox.color = value ? FlxColor.RED : FlxColor.BLACK;
		return invalidGhostCharacter = value;
	}

	function set_useGameOverPivot(value:Bool) {
		if (character != null) character.cameraPivotUseGameOver = value;
		if (ghostCharacter != null) ghostCharacter.cameraPivotUseGameOver = value;
		return useGameOverPivot = value;
	}

	function set_charPos(value:ChartCharacterID) {
		if (character != null) {
			character.apply(stage.characterPositions[value] ?? stage.characterPositions[BF]);
			characterChange.dispatch();
		}
		return charPos = value;
	}

	function set_ghostCharPos(value:ChartCharacterID) {
		if (ghostCharacter != null) {
			ghostCharacter.apply(stage.characterPositions[value] ?? stage.characterPositions[BF]);
			ghostCharacterChange.dispatch();
		}
		return ghostCharPos = value;
	}

	function set_iconColor(value:FlxColor) {
		if (character.characterIconData != null) character.characterIconData.color = value;
		else character.characterIconData = {color: value};
		if (healthMeter != null) {
			healthMeter.iconP1.iconColor = value;
			@:privateAccess healthMeter.reloadBar();
		}
		return iconColor = value;
	}

	function doOffset(x:Float, y:Float) {
		final x2 = charAnims[curAnimIdx].offset[0] += x, y2 = charAnims[curAnimIdx].offset[1] += y;
		character.animationOffsets[charAnims[curAnimIdx].name][0] = x2;
		character.animationOffsets[charAnims[curAnimIdx].name][1] = y2;
		@:privateAccess character._currentAnimOffset.set(x2, y2);

		charAnims[curAnimIdx].changed = true;
		updateCurAnimLabel();

		if (!changedSomething) {
			changedSomething = true;
			updateWindowTitle();
		}
		else changedSomething = true;
	}

	function doOriginOffset(x:Float, y:Float) {
		character.characterOrigin.x += x;
		character.characterOrigin.y += y;
		characterChange.dispatch();

		if (!changedSomething) {
			changedSomething = true;
			updateWindowTitle();
		}
		else changedSomething = true;
	}

	function doFocusOffset(x:Float, y:Float) {
		if (useGameOverPivot) {
			character.deathCameraFocus.x += x;
			character.deathCameraFocus.y += y;
			updateCurAnimLabel();
		}
		else if (character.currentDirection != null) {
			character.cameraFocusDirection[character.currentDirection].x += x;
			character.cameraFocusDirection[character.currentDirection].y += y;
		}
		else {
			character.cameraFocus.x += x;
			character.cameraFocus.y += y;
			updateCurAnimLabel();
		}

		if (!changedSomething) {
			changedSomething = true;
			updateWindowTitle();
		}
		else changedSomething = true;
	}

	function goGhostAnim(add:Int) {
		if (ghostCharacter == null) return;
		curGhostAnimIdx = FlxMath.wrap(curGhostAnimIdx + add, 0, ghostCharAnims.length - 1);

		final anim = ghostCharAnims[curGhostAnimIdx].name;
		ghostCharacter.playAnim(anim, ghostCharacter.dontPlayLoop = true);

		ghostCharacter.currentDirection = null;
		if (anim.startsWith('sing')) {
			if (anim.substr(4, 4) == 'LEFT') ghostCharacter.currentDirection = LEFT;
			else if (anim.substr(4, 4) == 'DOWN') ghostCharacter.currentDirection = DOWN;
			else if (anim.substr(4, 2) == 'UP') ghostCharacter.currentDirection = UP;
			else if (anim.substr(4, 5) == 'RIGHT') ghostCharacter.currentDirection = RIGHT;
		}

		updateCurGhostAnimLabel();
	}

	function goAnim(add:Int) {
		final prevAnimIdx = curAnimIdx;
		curAnimIdx = FlxMath.wrap(curAnimIdx + add, 0, charAnims.length - 1);

		final anim = charAnims[curAnimIdx].name;
		if (!charAnims[curAnimIdx].missing) character.playAnim(anim, character.dontPlayLoop = true);

		character.currentDirection = null;
		if (anim.startsWith('sing')) {
			if (anim.substr(4, 4) == 'LEFT') character.currentDirection = LEFT;
			else if (anim.substr(4, 4) == 'DOWN') character.currentDirection = DOWN;
			else if (anim.substr(4, 2) == 'UP') character.currentDirection = UP;
			else if (anim.substr(4, 5) == 'RIGHT') character.currentDirection = RIGHT;
		}
		animChange.dispatch();

		if (charAnims[prevAnimIdx] != null) {
			charAnimLabels[charAnims[prevAnimIdx].name].color =
				if (charAnims[prevAnimIdx].missing) UNHIGHLIGHTED_RED_COLOR;
				else if (charAnims[prevAnimIdx].changed) UNHIGHLIGHTED_YELLOW_COLOR;
				else UNHIGHLIGHTED_COLOR;
		}
		updateCurAnimLabel();
	}

	function playAnim(anim:String) {
		var idx = 0;
		for (i => v in charAnims) if (v.name == anim) {idx = i; break;}
		goAnim(idx - curAnimIdx);
	}

	function updateCurAnimLabel() {
		curAnimLabel.text = '${charAnims[curAnimIdx].name} ${charAnims[curAnimIdx].offset}';
		curAnimLabel.color = if (charAnims[curAnimIdx].missing) HIGHLIGHTED_RED_COLOR;
				else if (charAnims[curAnimIdx].changed) HIGHLIGHTED_YELLOW_COLOR;
				else HIGHLIGHTED_COLOR;

		final label = charAnimLabels[charAnims[curAnimIdx].name];
		if (label != null) {
			label.text = curAnimLabel.text;
			label.color = curAnimLabel.color;
		}
	}

	function updateCurGhostAnimLabel()
		curGhostAnimLabel.text = '${ghostCharAnims[curGhostAnimIdx].name} ${ghostCharAnims[curGhostAnimIdx].offset}';

	function fetchShit(char:Character, f:String->Void) {
		final anims = [for (v in @:privateAccess char.animation._animations.keys()) v];
		for (i in 0...anims.length) {
			final a = anims[i];
			for (n => b in anims) if (b.startsWith(a) && b.length > a.length) {
				anims.swapAndPop(n);
				anims.insert(i + 1, b);
				break;
			}
		}

		final pending = [];
		for (s in SORT_ANIMATIONS) {
			for (anim in anims) {
				if (anim == s) f(anim);
				else if (anim.startsWith(s)) pending.push(anim);
			}
			for (anim in pending) f(anim);
			pending.resize(0);
		}
		for (anim in anims) f(anim);
	}

	function buildCharAnim(char:Character, name:String):AnimCache {
		if (char.animationOffsets[name] == null) char.animationOffsets.set(name, [0, 0]);
		if (char is CustomCharacter) {
			for (data in cast(char, CustomCharacter).characterData.animations)
				if (data.name == name) return cast Reflect.copy(data);
		}

		final anim = char.animation.getByName(name);
		final frame = char.frames.frames[anim.frames[0]];
		final animCache:AnimCache = {
			name: name, offset: char.animationOffsets[name].copy(),
			fps: anim.frameRate, loop: anim.looped, flipX: anim.flipX, flipY: anim.flipY
		};

		// TODO: get the actual indices?
		animCache.id = frame.name.substr(0, frame.name.length - 3);
		if (frame.parent != char.graphic) animCache.asset = frame.parent.key;

		return animCache;
	}

	function fetchCharAnim(anim:String) {
		if (charAnimLabels.exists(anim)) return;
		var cache = charAnims[charAnims.length - 1];
		if (cache == null || cache.name != anim) charAnims.push(cache = buildCharAnim(character, anim));

		final label = charAnimLabelGroup.recycle(FlxText);
		label.text = '$anim ${cache.offset}';
		label.setPosition(10, LABELS_Y + (charAnims.length - 1) * LABELS_Y_INTERVAL);
		label.setFormat(Paths.font('vcr'), 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		label.color = UNHIGHLIGHTED_COLOR;
		if (character.curAnim?.name == anim) {
			label.color = HIGHLIGHTED_COLOR;
			curAnimIdx = charAnims.length - 1;
		}

		charAnimLabels.set(anim, label);
	}

	function fetchCharAnims() {
		charAnimLabels.clear();
		charAnimLabelGroup.killMembers();

		character.loadPendingAnimations();
		charAnims = [];
		curAnimIdx = 0;
		fetchShit(character, fetchCharAnim);
		updateCurAnimLabel();
		animChange.dispatch();
	}

	function fetchGhostCharAnim(anim:String) {
		if (ghostCharAnimKeys.exists(anim)) return;
		ghostCharAnimKeys.set(anim, ghostCharAnims.length);
		ghostCharAnims.push(buildCharAnim(ghostCharacter, anim));
	}

	function fetchGhostCharAnims() {
		ghostCharacter.loadPendingAnimations();
		ghostCharAnims = [];
		ghostCharAnimKeys = [];
		fetchShit(ghostCharacter, fetchGhostCharAnim);
		updateCurGhostAnimLabel();
	}

	function exit() {
		if (changedSomething)
			openSubState(new ConfirmationSubState('Are you sure you want to exit from unsaved Character?', () -> {
				changedSomething = false;
				exit();
			}));
		else {
			Main.statsCounter.visible = true;
			if (wasInPlayState) FlxG.switchState(PlayState.new.bind(null));
			else FlxG.switchState(goku.state.MenuGoku.new);
		}
	}

	function reload() {
		if (changedSomething)
			openSubState(new ConfirmationSubState('Are you sure you want to reload the Character?', () -> {
				changedSomething = false;
				updateWindowTitle();
				reload();
			}));
		else
			changeCharacter(characterID);
	}

	function save() {
		final stageSX = character.stagePosition.scaleX ?? character.stagePosition.scale ?? 1,
			stageSY = character.stagePosition.scaleY ?? character.stagePosition.scale ?? 1;

		final data:CharacterData = {
			image: character.graphic.key, name: characterName, antialiasing: character.antialiasing,
			strokeTime: character.strokeTime, holdInterval: character.holdInterval,
			flipX: character.flipX, flipY: character.flipY,
			scale: [character.scale.x / stageSX, character.scale.y / stageSY],
			origin: [character.characterOrigin.x, character.characterOrigin.y],
			cam: [character.cameraFocus.x, character.cameraFocus.y],
			icon: character.characterIconData,
			deathCam: [character.deathCameraFocus.x, character.deathCameraFocus.y],
			deathCharacterID: character.deathCharacterID, deathSFX: character.deathSFXPath,
			deathMusic: character.deathMusicPath, deathEndMusic: character.deathEndMusicPath,
			camDirection: [[0, 0], [0, 0], [0, 0], [0, 0]], animations: []
		};
		if (character.sourceSize != null) {
			data.width = character.sourceSize.x;
			data.height = character.sourceSize.y;
		}
		for (i in character.cameraFocusDirection.keys()) if (data.camDirection[i] != null) {
			data.camDirection[i][0] = character.cameraFocusDirection[i].x;
			data.camDirection[i][1] = character.cameraFocusDirection[i].y;
		}

		for (v in charAnims) {
			final anim = character.animation.getByName(v.name);
			final d:BLAnimData = {name: v.name, fps: Math.floor(anim?.frameRate ?? 24), loop: anim?.looped, flipX: anim?.flipX, flipY: anim?.flipY};
			for (i in Reflect.fields(v)) if (i != 'changed' && i != 'missing') Reflect.setField(d, i, Reflect.field(v, i));
			data.animations.push(d);
		}

		for (i in Reflect.fields(data)) if (Reflect.field(data, i) == null) Reflect.deleteField(data, i);
		openSubState(new SaveDialog(Json.stringify(data, null, '\t'), Paths.character(characterID), () -> {
			changedSomething = false;
			updateWindowTitle();
			fetchCharAnims();
		}));
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUINumericStepper.CHANGE_EVENT) {
			final box:FlxUINumericStepper = cast sender;
			if (changeCallbacks[box.name] != null) changeCallbacks[box.name]();
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		final shift = FlxG.keys.pressed.SHIFT;
		final speed:Int = shift ? 4 : 1;

		if (FlxG.mouse.wheel != 0) camGame.zoom += FlxG.mouse.wheel * speed / 5;
		if (!FlxInputText.globalManager.isTyping) {
			if (FlxG.keys.justPressed.TAB) {
				if (camera.visible = !camera.visible)
					turboLEFT.interval = turboDOWN.interval = turboUP.interval = turboRIGHT.interval = 0.02;
				else
					turboLEFT.interval = turboDOWN.interval = turboUP.interval = turboRIGHT.interval = character.strokeTime;
			}
			if (FlxG.keys.justPressed.C) useGameOverPivot = !useGameOverPivot;
			if (FlxG.keys.justPressed.F) {
				if (!charAnims[curAnimIdx].missing) {
					character.dontPlayLoop = false;
					character.playAnim(charAnims[curAnimIdx].name, true);
				}

				if (ghostCharacter != null) {
					ghostCharacter.dontPlayLoop = false;
					ghostCharacter.playAnim(ghostCharAnims[curGhostAnimIdx].name, true);
				}
			}

			if (camera.visible) {
				if (turboLEFT.activated) doFocusOffset(character.stageFlipX ? speed : -speed, 0);
				if (turboDOWN.activated) doFocusOffset(0, character.stageFlipY ? -speed : speed);
				if (turboUP.activated) doFocusOffset(0, character.stageFlipY ? speed : -speed);
				if (turboRIGHT.activated) doFocusOffset(character.stageFlipX ? -speed : speed, 0);
			}
			else {
				if (turboLEFT.activated) playAnim(character.stageFlipX ? 'singRIGHT' : 'singLEFT');
				if (turboDOWN.activated) playAnim(character.stageFlipY ? 'singUP' : 'singDOWN');
				if (turboUP.activated) playAnim(character.stageFlipY ? 'singDOWN' : 'singUP');
				if (turboRIGHT.activated) playAnim(character.stageFlipX ? 'singLEFT' : 'singRIGHT');
			}

			if (FlxG.keys.pressed.CONTROL) {
				if (turboW.activated) goAnim(-1);
				if (turboS.activated) goAnim(1);
				if (turboA.activated) goGhostAnim(-1);
				if (turboD.activated) goGhostAnim(1);
			}
			else if (FlxG.keys.pressed.ALT) {
				if (turboA.activated) doOriginOffset(character.stageFlipX ? -speed : speed, 0);
				if (turboS.activated) doOriginOffset(0, character.stageFlipY ? speed : -speed);
				if (turboW.activated) doOriginOffset(0, character.stageFlipY ? -speed : speed);
				if (turboD.activated) doOriginOffset(character.stageFlipX ? speed : -speed, 0);
			}
			else {
				if (turboA.activated) doOffset(character.stageFlipX ? -speed : speed, 0);
				if (turboS.activated) doOffset(0, character.stageFlipY ? speed : -speed);
				if (turboW.activated) doOffset(0, character.stageFlipY ? -speed : speed);
				if (turboD.activated) doOffset(character.stageFlipX ? speed : -speed, 0);
			}

			if (FlxG.keys.pressed.E) camGame.zoom += elapsed * speed;
			if (FlxG.keys.pressed.Q) camGame.zoom -= elapsed * speed;
			if (FlxG.keys.justPressed.R) {
				resetCamera();
				healthMeter.value = 1;
			}
			if (FlxG.keys.justPressed.T) {
				camGame.target.setPosition(
					character.x + character.cameraFocus.x * character.scale.x * (character.stageFlipX ? -1 : 1),
					character.y + character.cameraFocus.y * character.scale.y * (character.stageFlipY ? -1 : 1)
				);
				camGame.zoom = character.cameraZoomTarget * 0.9;
			}

			if (FlxG.keys.justPressed.ESCAPE) exit();
		}

		if (FlxG.mouse.justPressed) {
			for (anim => label in charAnimLabels) {
				if (FlxG.mouse.overlaps(label)) playAnim(anim);
			}
		}

		if (FlxG.mouse.pressedRight) {
			FlxG.mouse.getViewPosition(camGame, mousePosition);
			if (!FlxG.mouse.justPressedRight) {
				camGame.target.x += (mouseLastPosition.x - mousePosition.x) * (FlxG.mouse.justMoved ? speed : 1);
				camGame.target.y += (mouseLastPosition.y - mousePosition.y) * (FlxG.mouse.justMoved ? speed : 1);
			}
			mouseLastPosition.copyFrom(mousePosition);
		}
		else if (FlxG.mouse.pressed) {
			if (FlxG.mouse.overlaps(healthMeter))
				healthMeter.value = FlxMath.bound(FlxMath.remapToRange(
					FlxG.mouse.x - healthMeter.iconP1.frameWidth / 3, healthMeter.x + healthMeter.width, healthMeter.x, 0, 2
				), 0, 2);
		}
	}

	override function destroy() {
		super.destroy();

		mousePosition = FlxDestroyUtil.put(mousePosition);
		mouseLastPosition = FlxDestroyUtil.put(mouseLastPosition);
	}
}