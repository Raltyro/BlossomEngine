package blossom;

// implement keyboard input lol?

class BLClickableSprite extends BLSprite {
	public var onClick:Void->Void;
	public var onHover:Bool->Void;
	public var onRelease:Void->Void;

	public var hovered:Bool = false;
	public var pressed:Bool = false;

	public function new(x = 0.0, y = 0.0, ?graphic:BLGraphicAsset, ?animations:Array<BLAnimData>) {
		super(x, y, graphic, animations);
		bindCallbacks(onClick, onHover, onRelease);
	}

	public inline function bindCallbacks(?onClick:Void->Void, ?onHover:Bool->Void, ?onRelease:Void->Void):BLClickableSprite {
		if (onClick != null) this.onClick = onClick;
		if (onHover != null) this.onHover = onHover;
		if (onRelease != null) this.onRelease = onRelease;
		return this;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		final oldPressed = pressed, oldHovered = hovered;
		pressed = hovered = false;

		#if FLX_TOUCH
		for (touch in FlxG.touches.list) {
			if (hovered = touch.overlaps(this)) {
				pressed = touch.pressed;
				break;
			}
		}
		#end
		
		#if FLX_MOUSE
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