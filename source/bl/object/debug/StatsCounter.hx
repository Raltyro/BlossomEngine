package bl.object.debug;

import openfl.display.DisplayObjectContainer;
import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;

class StatsCounter extends DisplayObjectContainer {
	public var fpsCounter:FPSCounter;
	public var flixelCounter:FlixelCounter;
	public var memoryCounter:MemoryCounter;
	public var drawCounter:DrawCounter;
	public var updateRateDuration:Int = 500;

	var debounceUpdate:Int = 1000;

	public var fontName(default, set):String = Paths.font('vcr.ttf');
	function set_fontName(font:String) {
		if (font == fontName) return fontName;
		for (obj in __children) if (obj != null && (obj is StatsText)) @:privateAccess cast(obj, StatsText).reloadFont();
		return fontName = font;
	}

	public function new(x:Float = 3, y:Float = 3, showFPS:Bool = true, showMEM:Bool = true, showDraw:Bool = true) {
		super();
		this.x = x;
		this.y = y;

		__drawableType = openfl.display._internal.IBitmapDrawableType.SPRITE;
		addChild(fpsCounter = new FPSCounter()).visible = showFPS;
		addChild(flixelCounter = new FlixelCounter()).visible = showFPS;
		addChild(memoryCounter = new MemoryCounter()).visible = showMEM;
		addChild(drawCounter = new DrawCounter()).visible = showDraw;
	}

	@:noCompletion override function addChildAt(child:DisplayObject, index:Int):DisplayObject {
		super.addChildAt(child, index);

		var other = __children[index - 1];
		child.x = 0;
		child.y = other == null ? 0 : other.y + other.height + 2;

		other = child;
		for (i in (index + 1)...__children.length) {
			if (__children[i] == null || !__children[i].visible) continue;
			__children[i].y = other.y + other.height + 2;
			other = __children[i];
		}

		return child;
	}

	@:noCompletion private override function __enterFrame(tickdt) {
		@:privateAccess if (FlxG.game != null && FlxG.game._lostFocus && FlxG.autoPause)
			return;

		if ((debounceUpdate += Math.floor(tickdt)) < updateRateDuration) return fpsCounter.__enterFrame(tickdt);
		super.__enterFrame(tickdt);
		debounceUpdate = 0;

		var y:Float = 0;
		for (child in __children) {
			if (child == null || !child.visible) continue;
			child.y = y;
			y += child.height + 2;
		}
	}
}

class StatsText extends TextField {
	public function new() {
		super();
		__textFormat.color = 0xFFFFFF;
		selectable = mouseEnabled = multiline = wordWrap = false;
		autoSize = openfl.text.TextFieldAutoSize.LEFT;
		
		__enterFrame(0);
		addEventListener(Event.ADDED, reloadFont);
	}

	private function reloadFont(?_) {
		var font = parent != null && (parent is StatsCounter) ? cast(parent, StatsCounter).fontName : "assets/fonts/vcr.ttf";
		if (__textFormat.font == font) return;

		__textFormat.font = font;
		defaultTextFormat = __textFormat;
	}

	@:noCompletion private override function get_height():Float {
		__updateLayout();
		return __textEngine.textHeight * Math.abs(scaleY);
	}

	@:noCompletion private override function set_text(text:String):String {
		if (__text == text) return text;
		return super.set_text(text);
	}

	inline function checkColor(bool:Bool) if (bool) textColor = 0xFF1111; else textColor = 0xFFFFFF;
}

class FPSCounter extends StatsText {
	public var fpsDisplay:Float = 0;
	public var redFPS:UInt = 24;

	var lastTime:Float = 0;
	var frameTime:Float = 0;
	var frames:UInt = 0;

	public function new() {
		super(); defaultTextFormat = new TextFormat(18);
	}

	override function __enterFrame(_) {
		frames++;

		if (FlxG.game != null) @:privateAccess {
			frameTime += FlxG.game._elapsedMS;
			lastTime = FlxG.game.ticks + FlxG.game._startTime;
		}
		else {
			var time = openfl.Lib.getTimer();
			frameTime += time - lastTime;
			lastTime = time;
		}

		if (frameTime > 1000) {
			if ((fpsDisplay = FlxMath.bound(frames, frames - 30, frames + 30)) == Math.NaN) fpsDisplay = 0;
			checkColor(frames < redFPS);
			text = Math.floor(fpsDisplay) + ' FPS';
			frameTime = frames = 0;
		}
	}
}

class FlixelCounter extends StatsText {
	public var stateName:String = 'None';
	var state:flixel.FlxState;

	public function new() {
		super(); defaultTextFormat = new TextFormat(14);
	}

	override function __enterFrame(_) {
		if (FlxG.game == null || FlxG.state == null) return;
		if (state == null || state != FlxG.state) stateName = Type.getClassName(Type.getClass(state = FlxG.state));
		text = stateName;
	}
}

#if windows
@:headerInclude("windows.h")
@:headerInclude("psapi.h")
/* Unstable
#elseif linux
@:headerInclude("unistd.h")
@:headerInclude("sys/resource.h")
@:headerInclude("stdio.h")
*/
#elseif mac
@:headerInclude("unistd.h")
@:headerInclude("sys/resource.h")
@:headerInclude("mach/mach.h")
#end
class MemoryCounter extends StatsText {
	public static var totalMemory(get, never):Float;
	public static var memoryPeak(get, never):Float;

	public var memoryDisplay:Float = 0;
	public var redMemory:UInt = 0x80000000; // 1 GB
	public var showPeak:Bool = true;

	public function new() {
		super(); defaultTextFormat = new TextFormat(14);
	}

	override function __enterFrame(_) {
		checkColor((memoryDisplay = totalMemory) > redMemory);
		text = CoolUtil.getSizeString(memoryDisplay) + (showPeak ? ' / ${CoolUtil.getSizeString(memoryPeak)} MEM' : " MEM");
	}

	#if (cpp && windows)
	@:functionCode("
		PROCESS_MEMORY_COUNTERS info;
		if (GetProcessMemoryInfo(GetCurrentProcess(), &info, sizeof(info)))
			return (size_t)info.WorkingSetSize;
	")
	@:noCompletion public static function get_totalMemory() return 0;
	/*#elseif linux
	@:functionCode("
		long rss = 0L;
		FILE* fp = NULL;
		
		if ((fp = fopen(\"/proc/self/statm\", \"r\")) == NULL)
			return (size_t)0L;
		
		fclose(fp);
		if (fscanf(fp, \"%*s%ld\", &rss) == 1)
			return (size_t)rss * (size_t)sysconf( _SC_PAGESIZE);
	")
	@:noCompletion public static function get_totalMemory() return 0;*/
	#elseif mac
	@:functionCode("
		struct mach_task_basic_info info;
		mach_msg_type_number_t infoCount = MACH_TASK_BASIC_INFO_COUNT;
		
		if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &infoCount) == KERN_SUCCESS)
			return (size_t)info.resident_size;
	")
	@:noCompletion public static function get_totalMemory() return 0;
	#else
	#if hl static var _temp = 0.; #end
	@:noCompletion public static function get_totalMemory() {
		var ret =
			#if cpp
			untyped __global__.__hxcpp_gc_used_bytes()
			#elseif (js && html5)
			untyped #if haxe4 js.Syntax.code #else __js__ #end ("(window.performance && window.performance.memory) ? window.performance.memory.usedJSHeapSize : 0")
			#else 0. #end;
		#if hl @:privateAccess hl.Gc._stats(_temp, _temp, ret); #end
		if (ret > _memPeak) _memPeak = ret;
		return ret;
	}
	#end

	static var _memPeak:Float;
	#if (cpp && windows)
	@:functionCode("
		PROCESS_MEMORY_COUNTERS info;
		if (GetProcessMemoryInfo(GetCurrentProcess(), &info, sizeof(info)))
			return (size_t)info.PeakWorkingSetSize;
	")
	/*#elseif linux
	@:functionCode("
		struct rusage rusage;
		getrusage(RUSAGE_SELF, &rusage);
		
		return (size_t)(rusage.ru_maxrss * 1024L);
	")*/
	#elseif mac
	@:functionCode("
		struct rusage rusage;
		getrusage(RUSAGE_SELF, &rusage);
		
		return (size_t)rusage.ru_maxrss;
	")
	#end
	@:noCompletion public static function get_memoryPeak() return _memPeak;
}

class DrawCounter extends StatsText {
	public var drawDisplay:UInt = 0;
	public var redDraw:UInt = 128;

	public function new() {
		super(); defaultTextFormat = new TextFormat(14);
	}

	override function __enterFrame(_) {
		#if (gl_stats && !disable_cffi && (!html5 || !canvas))
		checkColor((drawDisplay = openfl.display._internal.stats.Context3DStats.totalDrawCalls()) > redDraw);
		#elseif FLX_DEBUG
		checkColor((drawDisplay = @:privateAccess flixel.FlxBasic.visibleCount) > redDraw);
		#end
		text = '$drawDisplay Draws';
	}
}