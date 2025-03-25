package bl;

import flixel.text.FlxText;
import flixel.util.FlxAxes;

class BLText extends FlxText {
	public function new(
		x = 0.0, y = 0.0, ?antialiasing:Bool,
		fieldWidth = 0.0, ?text:String, ?font:String, ?size:Int,
		color = FlxColor.WHITE, alignment:FlxTextAlign = CENTER, borderStyle:FlxTextBorderStyle = OUTLINE, borderColor = FlxColor.BLACK,
		?centerScreen:FlxAxes, ?scale:Array<Float>, ?scalePoint:FlxPoint, ?scrollFactor:Array<Float>, ?scrollFactorPoint:FlxPoint
	) {
		super(x, y, fieldWidth, text, size);
		setFormat(Paths.font(font ?? 'vcr'), size, color, alignment, borderStyle, borderColor);

		if (antialiasing != null) this.antialiasing = antialiasing;

		if (scale != null) this.scale.set(scale[0], scale.length == 1 ? scale[0] : scale[1]);
		else if (scalePoint != null) this.scale.copyFrom(scalePoint);

		if (scrollFactor != null) this.scrollFactor.set(scrollFactor[0], scrollFactor.length == 1 ? scrollFactor[0] : scrollFactor[1]);
		else if (scrollFactorPoint != null) this.scrollFactor.copyFrom(scrollFactorPoint);

		updateHitbox();

		if (centerScreen != null) {
			screenCenter(centerScreen);
			if (centerScreen.x) this.x = Math.floor(this.x) + x;
			if (centerScreen.y) this.y = Math.floor(this.y) + y;
		}
	}
}