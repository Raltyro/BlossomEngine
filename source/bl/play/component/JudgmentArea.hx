package bl.play.component;

import flixel.group.FlxSpriteGroup;

import bl.data.Skin;
import bl.play.Highscore;

class JudgmentArea extends FlxSpriteGroup {
	public var judgmentVisible:Bool = true;
	public var comboVisible:Bool = true;
	public var timingVisible:Bool = true;
	public var stackPopUps:Bool = true;
	public var moveChildren:Bool = false;
	public var childrenLimit:Int = 255;

	public var skin:Skin;
	public var conductor:Null<Conductor>;

	var _cache:Map<String, Array<BLSprite>> = [];
	var _alive:Map<String, Array<BLSprite>> = [];
	var _arr:Array<BLSprite> = [];
	var _childrens:Int = 0;

	public function new(x = 0.0, y = 0.0, ?conductor:Conductor, ?skin:Skin) {
		super();

		this.conductor = conductor;
		this.skin = skin ?? new Skin();
		this.x = x;
		this.y = y;
	}


	public function popUp(tallies:Tallies, ?judgment:Judgment, ?timing:Float):Bool {
		if (!visible) return false;

		var popUpped = false;
		inline function makeSpr(name:String, scale:Float, alpha:Float, duration:Float):BLSprite {
			if (!_cache.exists(name)) {
				_cache.set(name, []);
				_alive.set(name, []);
			}
			var spr:BLSprite = null;
			if (_childrens > childrenLimit) spr = _alive.get(name)[0];
			if (spr == null) {
				_childrens++;
				_alive.get(name).push(spr = _cache.get(name).pop() ?? cast add(new BLSprite().loadData(skin.getSpriteData(name))));
			}
			else {
				spr.kill();
				FlxTween.cancelTweensOf(spr);
			}

			remove(spr, true);
			insert(length, spr);
			spr.revive();
			spr.scale.set(scale, scale);
			spr.updateHitbox();

			spr.color = FlxColor.WHITE;
			spr.alpha = 1;
			spr.moves = true;
			spr.velocity.set();
			spr.acceleration.set();
			FlxTween.cancelTweensOf(spr);
			FlxTween.tween(spr, {alpha: 1}, duration, {onComplete: (_) -> {
				FlxTween.tween(spr, {alpha: 0}, 0.2, {onComplete: (_) -> {
					_cache.get(name).push(spr);
					_alive.get(name).remove(spr);
					spr.kill();
					_childrens--;
				}});
			}});

			popUpped = true;
			return spr;
		}

		if (!stackPopUps) {
			_arr.clearArray();
			forEachAlive((sprite:FlxSprite) -> _arr.push(cast sprite));
		}

		final duration = (conductor?.beatLength ?? 500) * 0.001;

		if (judgment != null && judgmentVisible) {
			final judgeSpr = makeSpr(judgment.toString(), 0.7, 1, duration);
			judgeSpr.setPosition(x - judgeSpr.width / 2, y - judgeSpr.height);
			judgeSpr.acceleration.y = 550;
			judgeSpr.velocity.set(FlxG.random.float(0, -10), FlxG.random.float(-140, -175));
		}

		if (tallies != null && comboVisible) {
			final combo = tallies.combo, gold = tallies.misses == 0 && tallies.perfect + tallies.sick >= Highscore.getTotalNotes(tallies);
			if (Math.abs(combo) >= 5) {
				final str = Std.string(combo), negate = combo < 0;
				var x = x + 10, i = str.length, s = negate ? 0 : Math.min(str.length - 3, 0);
				while (--i >= s) {
					final numSpr = makeSpr(charToNum(str.charAt(i)), 0.5, 1, duration);
					numSpr.setPosition(x -= numSpr.width, y);
					numSpr.acceleration.y = FlxG.random.float(200, 300);
					numSpr.velocity.set(FlxG.random.float(-5, 5), FlxG.random.float(-140, -160));
					if (negate) numSpr.color = FlxColor.RED;
					else if (gold) numSpr.color = FlxColor.YELLOW;
				}
			}
		}

		if (timing != null && timingVisible) {
			final str = Std.string(Math.round(Math.abs(timing))), negate = timing < 0;
			var x = x + 20;
			for (i in 0...str.length) {
				final numSpr = makeSpr(charToNum(str.charAt(i)), 0.5, 1, duration);
				numSpr.setPosition(x, y);
				numSpr.acceleration.y = FlxG.random.float(200, 300);
				numSpr.velocity.set(FlxG.random.float(-5, 5), FlxG.random.float(-140, -160));
				numSpr.color = negate ? FlxColor.CYAN : FlxColor.GREEN;
				x += numSpr.width;
			}
		}

		if (popUpped) for (spr in _arr) {
			for (i => v in _alive) if (v.contains(spr)) {
				v.remove(spr);
				_cache.get(i).push(spr);
			}
			spr.kill();
			FlxTween.cancelTweensOf(spr);
		}

		return popUpped;
	}

	function charToNum(char:String) {
		final code = char.charCodeAt(0);
		if (code >= 48 && code < 58) return 'num$char';
		else if (code == 45) return 'numnegative';
		else return 'num0';
	}

	override public function setPosition(X:Float = 0, Y:Float = 0) {
		if (moveChildren) super.setPosition(X, Y);
		else {
			_skipTransformChildren = true;
			x = X;
			y = Y;
			_skipTransformChildren = false;
		}
	}

	override function set_x(Value:Float):Float {
		if (exists && moveChildren && x != Value) return super.set_x(Value);
		else return x = Value;
	}

	override function set_y(Value:Float):Float {
		if (exists && moveChildren && y != Value) return super.set_y(Value);
		else return y = Value;
	}
}