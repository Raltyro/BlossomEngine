package bl.object;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteContainer;
import flixel.math.FlxAngle;
import flixel.util.typeLimit.OneOfTwo;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;

class AtlasText extends FlxTypedSpriteContainer<AtlasChar> {
	public static final UPPER_CHARS = ~/^[A-Z]\d+$/;
	public static final LOWER_CHARS = ~/^[a-z]\d+$/;

	public var text(default, set):String;
	public var atlas(default, set):FlxAtlasFrames;

	public var typed:Bool;
	public var delay:Float;

	public var paused(default, null):Bool;
	public var typing(default, null):Bool;

	public var fontHeight:Float;
	public var caseAllowed:Case;

	var anims:Map<String, BLAnimData>;
	var _width:Float;
	var _height:Float;
	var _time:Float;

	public function new(x = 0.0, y = 0.0, text = '', font:OneOfTwo<AtlasFont, FlxAtlasFrames> = AtlasFont.BOLD, typed = false, delay = 0.03) {
		super(x, y);
		@:bypassAccessor this.text = text;
		this.typed = typed;
		this.delay = delay;
		if (font is FlxAtlasFrames) this.atlas = cast font;
		else this.atlas = AssetUtil.getSparrowAtlas(Paths.atlas('fonts/$font'));
	}

	public function pause() paused = true;
	public function reusme() paused = false;

	function restrictCase(text:String):String {
		if (text == null) return '';
		return switch (caseAllowed) {
			case Both: text;
			case Upper: text.toUpperCase();
			case Lower: text.toLowerCase();
		}
	}

	function set_atlas(value:FlxAtlasFrames):FlxAtlasFrames {
		if (value == atlas) return value;
		atlas = value;

		var containsUpper = false, containsLower = false;
		fontHeight = 0;
		for (frame in atlas.frames) {
			fontHeight = Math.max(fontHeight, frame.frame.height);
			containsUpper = containsUpper || UPPER_CHARS.match(frame.name);
			containsLower = containsLower || LOWER_CHARS.match(frame.name);
		}

		caseAllowed = containsUpper ? (containsLower == containsUpper ? Both : Upper) : Lower;

		if (typed) {
			var i = 0, stop = false, str = text;
			for (spr in members) if (spr != null && spr.exists) {
				if (stop && text.charAt(i++) != spr.char) stop = true;
				spr.destroy();
			}
			clear();

			text = str.substr(0, i);
			updateText();
			text = str;
		}
		else {
			for (spr in members) spr.destroy();
			clear();

			updateText();
		}

		return value;
	}

	inline function set_text(value:String):String {
		if (atlas == null) return value;
		if (restrictCase(text) == restrictCase(value)) return text = value;

		text = value;
		typing = typed;
		_time = 0;
		updateText();
		return value;
	}

	override function setPosition(x = 0.0, y = 0.0) {
		this.x = x;
		this.y = y;
	}

	override function initVars() {
		flixelType = GROUP;

		offset = FlxPoint.get();
		origin = FlxPoint.get(0, 0.5);
		scale = FlxPoint.get(1, 1);
		(scrollFactor = new FlxCallbackPoint(scrollFactorCallback)).set(1, 1);

		initMotionVars();
	}

	override function destroy() {
		offset = FlxDestroyUtil.put(offset);
		origin = FlxDestroyUtil.put(origin);
		scale = FlxDestroyUtil.put(scale);
		scrollFactor = FlxDestroyUtil.destroy(scrollFactor);

		@:bypassAccessor
		group = FlxDestroyUtil.destroy(group);

		super.destroy();
	}

	override function clone():AtlasText {
		var newAtlasText = new AtlasText(x, y, text, atlas, typed, delay);
		newAtlasText.paused = paused;
		newAtlasText.offset.copyFrom(offset);
		newAtlasText.origin.copyFrom(origin);
		newAtlasText.scale.copyFrom(scale);
		newAtlasText.scrollFactor.copyFrom(scrollFactor);
		newAtlasText.angle = angle;
		return newAtlasText;
	}

	override function update(elapsed:Float) {
		if (!paused && typing && (_time += elapsed) >= delay) {
			_time = Math.min(_time - delay, delay);
			updateText();
		}
		super.update(elapsed);
	}

	override function draw() @:privateAccess {
		final oldDefaultCameras = FlxCamera._defaultCameras;
		if (_cameras != null) FlxCamera._defaultCameras = _cameras;

		for (spr in members) {
			if (spr != null && spr.exists && spr.visible) {
				final px = spr.x, py = spr.y, sx = spr.scale.x, sy = spr.scale.y, s = spr.shader;

				final ppx = px - width * origin.x, ppy = py - height * origin.y;
				spr.setPosition(
					ppx * _cosAngle * scale.x - ppy * _sinAngle * scale.y + x + offset.x,
					ppy * _cosAngle * scale.y + ppx * _sinAngle * scale.x + y + offset.y
				);
				spr.scale.scale(scale.x, scale.y);
				spr.shader = shader;
				spr.draw();

				spr.setPosition(px, py);
				spr.scale.set(sx, sy);
				spr.shader = s;
			}
		}

		FlxCamera._defaultCameras = oldDefaultCameras;

		//#if FLX_DEBUG if (FlxG.debugger.drawDebug) drawDebug(); #end
	}

	override function preAdd(spr:AtlasChar) {
		spr.alpha = alpha;
		spr.scrollFactor.copyFrom(scrollFactor);
		spr.cameras = _cameras;
	}

	override function remove(sprite:AtlasChar, splice = false):AtlasChar {
		sprite.cameras = null;
		return group.remove(sprite, splice);
	}

	function updateText() {
		final text = restrictCase(this.text);
		var i = 0, clear = false;
		var last:AtlasChar = null;

		_height = _width = 0;

		for (spr in members) if (spr != null && spr.exists) {
			if (clear || spr.char != text.charAt(i++)) {
				clear = true;
				spr.kill();
			}
			else {
				_height = Math.max(_height, (last = spr).y);
				_width = Math.max(_width, spr.x + spr.width);
			}
		}

		if (!clear || !typing) {
			do {
				if (i >= text.length) {
					typing = false;
					break;
				}

				final spr = recycle(AtlasChar, () -> new AtlasChar(atlas, anims));
				spr.char = text.charAt(i++);

				if (spr.char == '\n') spr.setPosition(0, _height = (last?.y ?? 0) + fontHeight);
				else spr.setPosition(last == null ? 0 : last.x + (last.active ? last.width : 40), last?.y ?? 0);
				_width = Math.max(_width, spr.x + spr.width);

				last = spr;
			} while (!typed);
		}

		_height += fontHeight;
	}

	override function set_moves(value:Bool):Bool return moves = value;
	override function set_x(value:Float):Float return x = value;
	override function set_y(value:Float):Float return y = value;
	override function set_angle(value:Float):Float {
		if (angle != value) _angleChanged = true;
		super.set_angle(value);
		updateTrig();
		return value;
	}

	override function get_width():Float return _width;
	override function get_height():Float return _height;
}

class AtlasChar extends BLSprite {
	public var char(default, set):String;

	var anims:Map<String, BLAnimData>;

	public function new(x = 0.0, y = 0.0, atlas:FlxAtlasFrames, ?anims:Map<String, BLAnimData>, ?char:String) {
		super(x, y);
		frames = atlas;
		this.anims = anims ?? [];
		if (char != null) this.char = char;
	}

	function set_char(value:String):String {
		if (char == value) return value;
		if (!(active = value != ' ')) return char = value;

		if (!anims.exists(value)) anims.set(value, {name: value, id: getAnimID(value)});

		addAnim(anims.get(value), true);
		if (active = hasAnim(value)) playAnim(value);
		updateHitbox();

		return char = value;
	}

	override function centerOrigin() origin.set(0, 0);
	override function draw() if (active) super.draw();

	public static function getAnimID(char:String) {
		return switch (char) {
			case '&': '-and-';
			case '': '-angry faic-';
			case "'": '-apostraphie-';
			case "\\": '-back slash-';
			case ",": '-comma-';
			case '↓': '-down arrow-'; // U+2193
			case "”": '-end quote-'; // U+0022
			case "!": '-exclamation point-'; // U+0021
			case "/": '-forward slash-'; // U+002F
			case '>': '-greater-'; // U+003E
			case '♥' | '♡': '-heart-'; // U+2665
			case '←': '-left arrow-'; // U+2190
			case '<': '-less-'; // U+003C
			case '.': '-period-'; // U+002E
			case "?": '-question mark-';
			case '→': '-right arrow-'; // U+2192
			case "“": '-start quote-';
			case '↑': '-up arrow-'; // U+2191
			default: char;
		}
	}
}

enum abstract Case(String) from String to String {
	var Both = 'both';
	var Upper = 'upper';
	var Lower = 'lower';
}

enum abstract AtlasFont(String) from String to String {
	var BOLD = 'bold';
	var NORMAL = 'normal';
}