package bl;

class BLClickableSprite extends BLSprite {
	public var onClick:()->Void;
	public var onHover:Bool->Void;
	public var onRelease:()->Void;

	public var hovered:Bool = false;
	public var pressed:Bool = false;

	public function new(
		x = 0.0, y = 0.0, ?graphic:BLGraphicAsset, ?antialiasing = false,
		?centerScreen:FlxAxes, ?scale:Array<Float>, ?scalePoint:FlxPoint, ?scrollFactor:Array<Float>, ?scrollFactorPoint:FlxPoint,
		?animArray:Array<BLAnimData>, ?onClick:()->Void, ?onHover:Bool->Void, ?onRelease:()->Void)
	{
		super(x, y, graphic, antialiasing, centerScreen, scale, scrollFactor, animArray);
		inline bindCallbacks(onClick, onHover, onRelease);
	}

	public function bindCallbacks(?onClick:()->Void, ?onHover:Bool->Void, ?onRelease:()->Void):BLClickableSprite {
		if (onClick != null) this.onClick = onClick;
		if (onHover != null) this.onHover = onHover;
		if (onRelease != null) this.onRelease = onRelease;
		return this;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var oldPressed = pressed, oldHovered = hovered;
		pressed = hovered = false;

		#if android
		for (touch in FlxG.touches.list) {
			if (hovered = touch.overlaps(this)) {
				pressed = touch.pressed;
				break;
			}
		}
		#else
		if (hovered = FlxG.mouse.overlaps(this)) {
			pressed = FlxG.mouse.pressed;
		}
		#end

		if (hovered != oldHovered && onHover != null) onHover(hovered);
		if (pressed != oldPressed) {
			if (pressed) {if (onClick != null) onClick();}
			else if (onRelease != null) onRelease();
		}
	}
}