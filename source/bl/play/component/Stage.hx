package bl.play.component;

import flixel.group.FlxContainer;
import flixel.group.FlxGroup;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;
import flixel.FlxBasic;

import bl.data.Song.ChartCharacterID;
import bl.play.PlayState;
import bl.util.SortUtil;

@:structInit
class StageCharPos {
	public var x:Float = 0;
	public var y:Float = 0;
	public var angle:Float = 0;
	public var layer:Int = 0;

	@:optional public var alpha:Null<Float>;
	@:optional public var visible:Null<Bool>;

	public var scale:Float = 1;
	@:optional public var scaleX:Null<Float>;
	@:optional public var scaleY:Null<Float>;

	public var scroll:Float = 1;
	@:optional public var scrollX:Null<Float>;
	@:optional public var scrollY:Null<Float>;

	@:optional public var flipX:Null<Bool>;
	@:optional public var flipY:Null<Bool>;

	public var camX:Float = 0;
	public var camY:Float = 0;
}

@:autoBuild(bl.util.macro.BuildMacro.buildStages())
class Stage extends FlxContainer {
	public static final DEFAULT_STAGE:String = 'stage';
	@:noCompletion public static var stageClasses:Map<String, Class<Stage>>; // DO NOT DEFINE ANYTHING TO THIS, Taken care of BuildMacro

	public static function stageExists(stageID:String):Bool {
		if (stageClasses.exists(stageID)) return true;

		return false;
	}

	public static function preloadStage(stageID:String):Future<Bool> {
		if (stageClasses.exists(stageID)) {
			var f:() -> Future<Dynamic> = Reflect.field(stageClasses.get(stageID), 'preload');
			if (f == null) return Future.withValue(false);
			else {
				var promise = new Promise<Bool>();
				f().onComplete((_) -> promise.complete(true));
				return promise.future;
			}
		}

		return Future.withValue(false);
	}

	public static function make(stageID:String):Null<Stage> {
		if (stageID == null) return null;
		if (stageClasses.exists(stageID)) return Type.createInstance(stageClasses.get(stageID), []);

		return null;
	}

	#if !hscript inline #end public static function makeWithDefault(?stageID:String):Stage
		return make(stageID) ?? make(DEFAULT_STAGE) ?? new Stage();

	public var stageID:String;
	public var stageName:String;

	public var created:Bool = false;

	public var addInGameOver:Bool = false;

	public var conductor(get, set):Conductor;
	private var _conductor:Conductor;
	function get_conductor() return _conductor ?? playState?.conductor;
	function set_conductor(value:Conductor) return _conductor = value;

	public var playState(get, default):PlayState;
	function get_playState() {
		if (playState == null && (container != null && container is PlayState)) playState = cast container;
		return playState;
	}

	public var foreground:FlxContainer;
	public var characterPositions:Map<ChartCharacterID, StageCharPos> = [];
	public var centerPosition:FlxPoint;
	public var defaultZoom:Float = 1;
	public var backgroundColor:FlxColor = 0;

	public function new() {
		stageID = stageID ?? 'fallback';
		stageName = stageName ?? 'Fallback';
		super();

		centerPosition = FlxPoint.get();
		resetStage();
	}

	public function applyPlayState(?playState:PlayState) {
		if ((playState = playState ?? this.playState) != null) {
			playState.cameraFollowZoom = defaultZoom;
			playState.bgColor = backgroundColor;

			applyCharacters(playState.characters);
		}
	}

	public function sortCharacters(characters:Array<Character>, ?characterPositions:Map<ChartCharacterID, StageCharPos>) {
		if ((characterPositions = characterPositions ?? this.characterPositions) == null) return;

		var idx = container?.members.indexOf(this) ?? -2;
		if (idx == -2) return; else if (idx == -1) idx += container.length;

		for (character in sortCharacterArray(characters, characterPositions)) {
			final charIdx = container.members.indexOf(character);
			if (charIdx != -1 && charIdx != ++idx) {
				container.remove(character, true);
				container.insert(idx, character);
			}
		}
	}

	public function applyCharacters(characters:Array<Character>, ?characterPositions:Map<ChartCharacterID, StageCharPos>, dontSort = false) {
		if ((characterPositions = characterPositions ?? this.characterPositions) != null) {
			for (character in characters) applyCharacter(character, characterPositions.get(character.ID));
			if (!dontSort) sortCharacters(characters, characterPositions);
		}
	}

	public function applyCharacter(character:Character, ?characterPosition:StageCharPos) {
		if ((characterPosition = characterPosition ?? characterPositions.get(character.ID)) != null)
			character.apply(characterPosition);
	}

	public function sortCharacterArray(
		characters:Array<Character>, ?characterPositions:Map<ChartCharacterID, StageCharPos>,
		sameArray = false
	):Array<Character> {
		return SortUtil.sortCharacterByLayer(
			sameArray ? characters : [for (character in characters) character],
			(characterPositions ?? this.characterPositions)
		);
	}

	public function resetStage() {
		characterPositions.set(BF, {
			x: 450, y: 20
		});
		characterPositions.set(DAD, {
			x: -450, y: 20,
			flipX: true
		});
		characterPositions.set(GF, {
			x: 60, y: -10,
			scroll: 0.95,
			layer: -1
		});

		defaultZoom = 0.9;
		centerPosition.set(0, -300);
	}

	public function create() {
		foreground = new FlxContainer();
		created = true;
	}

	public function postCreate() {
		if (container != null) {
			container.add(foreground);
		}
	}

	override function destroy() {
		super.destroy();
		centerPosition = FlxDestroyUtil.put(centerPosition);
		foreground = FlxDestroyUtil.destroy(foreground);
		created = false;
	}

	override function toString():String
		return 'Stage(${this.stageID}, ${this.stageName})';
}