package bl.object.transition;

import flixel.math.FlxRect;

class TransitionWipe extends TransitionScreen {
	var tween:FlxTween;

	override function create() {
		super.create();
		if (!skip) screen.clipRect = FlxRect.get(0, 0, screen.width, screen.height);
	}

	override function start() {
		super.start();
		if (!skip) tween = FlxTween.tween(screen.clipRect, {width: 0}, duration, {ease: FlxEase.linear});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (active) screen.clipRect = screen.clipRect;
	}

	override function destroy() {
		if (tween != null) tween.cancel();
		tween = null;
		
		if (screen != null) screen.clipRect.put();
		super.destroy();
	}
}