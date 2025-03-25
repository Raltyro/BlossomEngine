package bl.play.component;

import flixel.group.FlxSpriteContainer;
import flixel.ui.FlxBar;

import bl.data.Skin;

class HealthMeter extends FlxSpriteContainer {
	public static final INSET_BAR:Int = 3;

	public var skin(default, set):Skin;
	public var value(default, set):Float;
	public var iconP1(default, set):HealthIcon;
	public var iconP2(default, set):HealthIcon;
	public var reverse(default, set):Bool = false;

	public var max(default, set):Float = 2;
	public var min(default, set):Float = 0;

	public var target:Float;
	public var valueLerp:Null<Float> = funkinLerp(32);

	public var iconScale:Float = 1;
	public var iconOffset:Float = 16;
	public var iconLerp:Float = funkinLerp(20);

	/**
	 * What scale to target the icon scales to.
	 */
	public var targetIconScale:Float = 1;

	/**
	 * The strength on icon bop.
	 */
	public var bopStrength:Float = 0.2;

	/**
	 * Beat Intervals of icon bops.
	 */
	public var bopInterval:Float = 1;
	public var bopEvery:BeatType = BEAT;

	/**
	 * How much measure offset the icon bops is
	 */
	public var bopOffset:Float = 0;

	/**
	 * The conductor for icon bops to work.
	 */
	public var conductor:Null<Conductor>;

	var bar:FlxBar;
	var overlay:BLSprite;
	var _lastBeat:Float = 0;

	public function new(x = 0.0, y = 0.0, ?conductor:Conductor, ?skin:Skin, ?iconP1:HealthIcon, ?iconP2:HealthIcon) {
		super();

		this.conductor = conductor;
		this.iconP1 = iconP1;
		this.iconP2 = iconP2;
		this.skin = skin ?? new Skin();
		this.x = x;
		this.y = y;

		value = target = 1;
	}

	inline public function setRange(min:Float, max:Float)
		bar.setRange(@:bypassAccessor this.min = min, @:bypassAccessor this.max = max);

	public function updateIcon(icon:HealthIcon) {
		if (icon == null) return;
		if (icon.container != cast this.group) add(icon);

		icon.scale.set(iconScale, iconScale);
		icon.updateHitbox();

		final min2 = reverse ? 2 : 0, max2 = reverse ? 0 : 2;
		final center = bar.x + bar.width * FlxMath.remapToRange(value, min, max, max2, min2) * 0.5;
		icon.y = y + (height - icon.height) * 0.5;
		if (icon.flipX = (reverse ? iconP2 : iconP1) == icon) {
			icon.x = center - iconOffset;
			icon.updateHealthIcon(FlxMath.remapToRange(valueLerp == null ? value : target, min, max, min2, max2));
		}
		else {
			icon.x = center - (icon.width - iconOffset);
			icon.updateHealthIcon(FlxMath.remapToRange(valueLerp == null ? value : target, min, max, max2, min2));
		}
		if (icon.dontFlip) icon.flipX = false;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		iconScale += (targetIconScale - iconScale) * FlxMath.getElapsedLerp(iconLerp, elapsed);
		if (conductor != null) {
			final beat = conductor.getBeats(bopEvery, bopInterval, bopOffset);
			if (_lastBeat != beat) {
				_lastBeat = beat;
				iconScale += bopStrength;
			}
		}

		if (valueLerp == null) {
			updateIcon(iconP1);
			updateIcon(iconP2);
		}
		else {
			final v = value + (target - value) * FlxMath.getElapsedLerp(valueLerp, elapsed);
			if (v == value) {
				updateIcon(iconP1);
				updateIcon(iconP2);
			}
			else value = v;
		}
	}

	override function destroy() {
		bar.destroy();
		overlay.destroy();
		if (iconP1 != null) iconP1.destroy();
		if (iconP2 != null) iconP2.destroy();
		super.destroy();
	}

	override function set_width(_:Float):Float return inline get_width();
	override function set_height(_:Float):Float return inline get_height();
	override function get_width():Float return overlay?.width ?? 0;
	override function get_height():Float return overlay?.height ?? 0;

	function reloadBar() @:privateAccess {
		final w = Math.floor(Math.max(overlay.width - INSET_BAR * 2, 1)),
			h = Math.floor(Math.max(overlay.height - INSET_BAR * 2, 1));

		bar.barWidth = (bar._fillHorizontal || !FlxG.renderTile) ? w : 1;
		bar.barHeight = (!bar._fillHorizontal || !FlxG.renderTile) ? h : 1;

		final p1 = iconP1?.iconColor ?? FlxColor.WHITE, p2 = iconP2?.iconColor ?? FlxColor.WHITE;
		bar.createFilledBar(reverse ? p1 : p2, reverse ? p2 : p1);

		if (FlxG.renderTile) {
			bar.numDivisions = w;
			if (bar._fillHorizontal) bar.scale.y = bar.barHeight = h;
			else bar.scale.x = bar.barWidth = w;
			bar.updateHitbox();
		}
	}

	function set_skin(skin:Skin) {
		if (this.skin == skin) return skin;
		this.skin = skin;

		if (overlay != null) overlay.destroy();
		if (bar != null) bar.destroy();

		overlay = BLSprite.fromData(skin.getSpriteData('healthBar'));
		bar = new FlxBar(INSET_BAR, INSET_BAR, RIGHT_TO_LEFT, 1, 1, null, min, max);

		insert(0, overlay);
		insert(0, bar);

		reloadBar();
		updateIcon(iconP1);
		updateIcon(iconP2);

		return skin;
	}

	function set_value(value:Float) {
		if (this.value == value) return value;
		bar.value = reverse ? FlxMath.remapToRange(value, min, max, max, min) : value;
		this.value = value;
		updateIcon(iconP1);
		updateIcon(iconP2);
		return value;
	}

	function set_iconP1(icon:HealthIcon) {
		if (iconP1 != null) {
			if (icon == null) remove(iconP1);
			else iconP1.destroy();
		}
		iconP1 = icon;
		if (bar != null) {
			reloadBar();
			updateIcon(icon);
		}
		return icon;
	}

	function set_iconP2(icon:HealthIcon) {
		if (iconP2 != null) {
			if (icon == null) remove(iconP2);
			else iconP2.destroy();
		}
		iconP2 = icon;
		if (bar != null) {
			reloadBar();
			updateIcon(icon);
		}
		return icon;
	}

	function set_reverse(value:Bool) {
		if (reverse == value) return value;
		reverse = value;
		if (bar != null) {
			reloadBar();
			updateIcon(iconP1);
			updateIcon(iconP2);
		}
		return value;
	}

	function set_max(value:Float) {
		if (bar != null) bar.setRange(min, max);
		return max = value;
	}

	function set_min(value:Float) {
		if (bar != null) bar.setRange(min, max);
		return min = value;
	}
}