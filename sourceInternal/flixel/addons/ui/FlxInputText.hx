// modified class just to make this specific shit extends FlxInputText

package flixel.addons.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI.NamedString;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.text.FlxInputText.FlxInputTextFilterMode;
import flixel.text.FlxInputText.FlxInputTextCase;
import flixel.text.FlxInputText.FlxInputTextChange;
import flixel.text.FlxInputTextManager;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

class FlxInputText extends flixel.text.FlxInputText {
	public static final NO_FILTER:FlxInputTextFilterMode = NONE;
	public static final ONLY_ALPHA:FlxInputTextFilterMode = ALPHABET;
	public static final ONLY_NUMERIC:FlxInputTextFilterMode = NUMERIC;
	public static final ONLY_ALPHANUMERIC:FlxInputTextFilterMode = ALPHANUMERIC;
	public static final CUSTOM_FILTER:FlxInputTextFilterMode = NONE; // uhh?

	public static final ALL_CASES:FlxInputTextCase = ALL_CASES;
	public static final UPPER_CASE:FlxInputTextCase = UPPER_CASE;
	public static final LOWER_CASE:FlxInputTextCase = LOWER_CASE;

	public static final BACKSPACE_ACTION:String = "backspace"; // press backspace
	public static final DELETE_ACTION:String = "delete"; // press delete
	public static final ENTER_ACTION:String = "enter"; // press enter
	public static final INPUT_ACTION:String = "input"; // manually edit

	/**
	 * This regular expression will filter out (remove) everything that matches.
	 * Automatically sets filterMode = FlxInputText.CUSTOM_FILTER.
	 */
	public var customFilterPattern(default, set):EReg;

	function set_customFilterPattern(cfp:EReg)
	{
		filterMode = REG(customFilterPattern = cfp);
		return customFilterPattern;
	}

	/**
	 * A function called whenever the value changes from user input, or enter is pressed
	 */
	public var callback:String->String->Void;

	public var params(default, set):Array<Dynamic>;
	private function set_params(p:Array<Dynamic>):Array<Dynamic> {
		params = p;
		if (params == null) params = [];
		var namedValue:NamedString = {name: "value", value: text};
		params.push(namedValue);
		return p;
	}

	/**
	 * callback that is triggered when this text field gets focus
	 * @since 2.2.0
	 */
	public var focusGained:Void->Void;

	/**
	 * callback that is triggered when this text field loses focus
	 * @since 2.2.0
	 */
	public var focusLost:Void->Void;

	/**
	 * Set the maximum length for the field (e.g. "3"
	 * for Arcade type hi-score initials). 0 means unlimited.
	 */
	public var maxLength(default, set):Int = 0;

	/**
	 * Change the amount of lines that are allowed.
	 */
	public var lines(default, set):Int;

	/**
	 * A FlxSprite representing the background sprite
	 */
	private var backgroundSprite(get, set):FlxSprite;
	function get_backgroundSprite() return _backgroundSprite;
	function set_backgroundSprite(v) return _backgroundSprite = v;

	/**
	 * A FlxSprite representing the flashing caret when editing text.
	 */
	private var caret(get, set):FlxSprite;
	function get_caret() return _caret;
	function set_caret(v) return _caret = v;

	/**
	 * A FlxSprite representing the fieldBorders.
	 */
	private var fieldBorderSprite(get, set):FlxSprite;
	function get_fieldBorderSprite() return _fieldBorderSprite;
	function set_fieldBorderSprite(v) return _fieldBorderSprite = v;

	/**
	 * The left- and right- most fully visible character indeces
	 */
	private var _scrollBoundIndeces:{left:Int, right:Int} = {left: 0, right: 0};

	private var _charBoundaries:Array<FlxRect>;

	/**
	 * Stores last input text scroll.
	 */
	private var lastScroll:Int;

	/**
	 * Creates a new `FlxInputText` object at the specified position.
	 * @param x               The X position of the text.
	 * @param y               The Y position of the text.
	 * @param fieldWidth      The `width` of the text object. Enables `autoSize` if `<= 0`.
	 *                         (`height` is determined automatically).
	 * @param text            The actual text you would like to display initially.
	 * @param size            The font size for this text object.
	 * @param textColor       The color of the text
	 * @param backgroundColor The color of the background (`FlxColor.TRANSPARENT` for no background color)
	 * @param embeddedFont    Whether this text field uses embedded fonts or not.
	 * @param manager         Optional input text manager that will power this input text.
	 *                        If `null`, `globalManager` is used
	 */
	public function new(x:Float = 0, y:Float = 0, fieldWidth:Float = 0, ?text:String, size:Int = 8, textColor:FlxColor = FlxColor.BLACK,
			backgroundColor:FlxColor = FlxColor.WHITE, embeddedFont:Bool = true, ?manager:FlxInputTextManager)
	{
		super(x, y, fieldWidth, text, size, textColor, backgroundColor, embeddedFont, manager);
		onTextChange.add((_, c) -> onChange(c));
	}

	private function set_maxLength(Value:Int):Int
	{
		maxLength = Value;
		if (text.length > maxLength)
		{
			text = text.substring(0, maxLength);
		}
		return maxLength;
	}

	private function set_lines(Value:Int):Int
	{
		if (Value == 0)
			return 0;

		if (Value > 1)
		{
			textField.wordWrap = true;
			textField.multiline = true;
		}
		else
		{
			textField.wordWrap = false;
			textField.multiline = false;
		}

		lines = Value;
		calcFrame();
		return lines;
	}

	override function startFocus() {
		if (!hasFocus && focusGained != null) focusGained();
		super.startFocus();
	}

	override function endFocus() {
		if (hasFocus && focusLost != null) focusLost();
		super.endFocus();
	}

	private function onChange(action:String):Void
	{
		if (callback != null)
		{
			callback(text, action);
		}
	}
}