package bl.play.field;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxStringUtil;

import bl.data.Skin;
import bl.graphic.shader.RGBPalleteShader;
import bl.util.ShaderUtil;

class NoteObject extends BLSprite {
	public final skinField:String;
	public var skinLoaded(default, null):Bool;

	public var skin(default, set):Skin;
	function set_skin(value:Skin):Skin {
		if (skin == value) return value;

		skin = value;
		if (value != null && field != null) reloadSkin();
		return value;
	}

	public var field(default, set):Notefield;
	function set_field(value:Notefield) {
		if (field == value) return value;
		
		if ((field = value) != null && skin != null) reloadSkin();
		return value;
	}

	public var column(default, set):Int;
	function set_column(value:Int) {
		if (column == value) return value;

		column = value;
		if (field != null) reloadSkin();
		return value;
	}

	public var animationColors:Map<String, Array<FlxColor>>;
	public var skinColors:Array<FlxColor>;

	var _useAnimationColors:Bool;

	public function new(x = 0.0, y = 0.0, skinField:String, column:Int, ?skin:Skin) {
		super(x, y);
		this.skinField = skinField;
		@:bypassAccessor this.column = column;
		this.skin = skin;
	}

	@:allow(bl.play.field.Notefield)
	function reloadSkin() {
		if (skin == null) @:bypassAccessor skin = new Skin();
		final data = skin.getNoteskin(field?.keys)?.get(skinField);
		if (!(skinLoaded = data != null)) return;

		loadBLGraphic(data.image, data.animations);
		antialiasing = data.antialiasing != null ? data.antialiasing : true;
		scale.set(data.scales[column][0], data.scales[column][1]);
		angle = data.angles[column];

		updateHitbox();
		if (data.offsets != null && data.offsets[column] != null) offset.set(data.offsets[column][0], data.offsets[column][1]);
		if (data.blends != null && data.blends[column] != null) blend = data.blends[column]; else blend = null;

		_useAnimationColors = false;
		setRGBColors(skinColors = data.colors[column]);
		animationColors.clear();
		for (anim in data.animations) if (anim.colors != null) animationColors.set(anim.name, anim.colors[column]);
	}

	inline function setRGBColors(colors:Array<FlxColor>) {
		ShaderUtil.safeSetParameterColor(shader, 'r', colors[0]);
		ShaderUtil.safeSetParameterColor(shader, 'g', colors[1]);
		ShaderUtil.safeSetParameterColor(shader, 'b', colors[2]);
	}

	override function initVars() {
		super.initVars();
		shader = new RGBPalleteShader();
		animationColors = [];
	}

	override function destroy() {
		super.destroy();
		if (animationColors != null) animationColors.clear(); animationColors = null;
	}

	override function checkEmptyFrame() {
		if (_frame == null) reloadSkin();
		else super.checkEmptyFrame();
	}

	//@:allow(bl.play.field.Notefield)
	//private var defaultDraw:Bool = true;
	//override function draw() if (defaultDraw) super.draw();

	override function playAnim(name:String, ?fallback:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):BLSprite {
		if (hasAnim(name)) {
			final useAnimationColors = animationColors.exists(name);
			if (_useAnimationColors != useAnimationColors)
				setRGBColors((_useAnimationColors = useAnimationColors) ? animationColors.get(name) : skinColors);
		}
		return super.playAnim(name, fallback, force, reversed, frame);
	}

	override function toString() {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("column", column),
			LabelValuePair.weak("visible", visible)
		]);
	}
}