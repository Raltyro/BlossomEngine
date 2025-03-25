package bl.state.base;

import flixel.util.FlxGradient;
import flixel.text.FlxText;

import bl.graphic.BufferPool;
import bl.data.Skin;
import bl.object.transition.TransitionScreen;

typedef LoadingWorker = {
	?work:()->Void,
	?future:()->Future<Dynamic>,
	text:String,
	?async:Null<Bool>
}

class BaseLoadingScreen extends flixel.FlxSubState {
	var future:Future<Dynamic>;
	var onComplete:Void->Void;
	var _callback:BaseLoadingScreen->Future<Dynamic>;

	var text:String;
	var loaded:UInt;
	var total:UInt;
	var stuffs:Dynamic;

	var freezeBackground:Bool;
	var bg:FlxSprite;
	var fg:FlxSprite;
	var labelBar:FlxSprite;
	var label:FlxText;

	public static function translateWorkers(workers:Array<LoadingWorker>):BaseLoadingScreen->Future<Dynamic> {
		var promise = new Promise<Dynamic>();
		return (screen:BaseLoadingScreen) -> {
			screen.total = workers.length;
			screen.loaded = 0;
			screen.text = 'Loading: Initial';

			var i:UInt = -1, next = null;
			var nextWrapped = (_) -> next();//CoolUtil.afterUpdate(next, 2);
			next = () -> if (++i >= workers.length) promise.complete(null);
			else {
				final worker = workers[i];
				if (worker.future == null && worker.work == null) return next();

				screen.text = 'Loading: ${worker.text} (${(screen.loaded = i) + 1}/${screen.total = workers.length})';
				if (worker.future != null) {
					var future = worker.future();
					if (future.isComplete || future.isError) next();
					else CoolUtil.futureWaitTime(future).onComplete(nextWrapped).onError(nextWrapped);
				}
				else if (worker.async ?? false)
					CoolUtil.futureWaitTime(new Future<Dynamic>(() -> {
						worker.work();
						return null;
					}, true)).onComplete(nextWrapped);
				else {
					CoolUtil.afterUpdate(() -> {
						worker.work();
						next();
					}, 2);
				}
			}

			next();
			return promise.future;
		}
	}

	public function new(callback:BaseLoadingScreen->Future<Dynamic>, onComplete:Void->Void, freezeBackground:Bool = false) {
		super();
		this.onComplete = onComplete;
		_callback = callback;

		if (this.freezeBackground = freezeBackground) TransitionScreen.getScreen();
	}

	override function create() {
		stuffs = {
			pause: FlxG.autoPause,
			framerate: Main.framerate,
			statsCounter: Main.statsCounter?.visible ?? false
		}
		FlxG.autoPause = true;
		Main.framerate = 24;
		if (Main.statsCounter != null) Main.statsCounter.visible = false;

		Skin.clearCache();
		AssetUtil.clearUnused();
		AssetUtil.clearCache();
		BufferPool.clear();
		ModuleEvent.reset();

		future = _callback(this);
		_callback = null;

		if (future.isComplete) return complete();
		future.onComplete((_) -> complete());

		super.create();
		createUI();
	}

	var _text:String;
	var _loaded:UInt;
	var _completed:Bool;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if (_text != text) changeText(_text = text);
		if (_loaded != loaded) progress(_loaded = loaded);
		if (_completed) {
			_completed = false;
			if (stuffs != null) {
				FlxG.autoPause = stuffs.pause;
				Main.framerate = stuffs.framerate;
				if (Main.statsCounter != null) Main.statsCounter.visible = stuffs.statsCounter;
			}

			TransitionScreen.getScreen();
			onComplete();
		}
	}

	public function complete() _completed = true;

	// Usually for indicating loading text screen something
	public function changeText(text:String) {
		if (label != null) {
			label.text = text;
			label.screenCenter(X);
		}
	}

	public function progress(loaded:Int) {
		if (fg != null) fg.alpha = 1 - (loaded / total);
	}

	private function createUI() {
		if (freezeBackground) createFreezedBG();
		else if (_constructor != null) createBaseBG();
		createBaseFG();
		createBaseUI();
	}

	private function createFreezedBG() {
		add(bg = new BLSprite(TransitionScreen.graphic).scaleToGame());
		bg.screenCenter();
		bg.setPosition(Math.floor(bg.x), Math.floor(bg.y));
	}

	private function createBaseBG() {
		add(bg = new BLSprite(Paths.image('menu')).scaleToGame());
		bg.screenCenter();
		bg.setPosition(Math.floor(bg.x), Math.floor(bg.y));
		bg.color = 0xFF4F4F4F;
		bgColor = 0xFF000000;
	}

	private function createBaseFG() {
		add(fg = FlxGradient.createGradientFlxSprite(1, FlxG.height, [FlxColor.fromRGB(188, 158, 255, 100), FlxColor.fromRGB(80, 12, 108, 128)]));
		fg.scale.x = FlxG.width;
		fg.updateHitbox();
		fg.alpha = 1 - (loaded / total);
	}

	private function createBaseUI() {
		createBaseLabel();

		var title = new BLText(8, 8, Main.TITLE + '\n' + getRandomText(), 'vcr.ttf', 24, LEFT);
		title.alpha = .75;
		add(title);
	}

	private function createBaseLabel() {
		add(labelBar = new BLSprite(8, FlxG.height - 50).makeSolidColor(1264, 42, FlxColor.BLACK));
		labelBar.alpha = .5;

		add(label = new BLText(0, FlxG.height - 44, text, 'vcr.ttf', 24, NONE, X));
	}

	function getRandomText() {
		return FlxG.random.getObject([
			'Did you know this engine has been in works for 3 years',
			'Random text here',
			'This engine used to have 3 branches in work',
			'The first mod ever to use this mod is none other tha'
		]);
	}
}