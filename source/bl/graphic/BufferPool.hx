package bl.graphic;

import openfl.display.BitmapData;
import bl.util.BitmapDataUtil;

@:access(openfl.display.BitmapData)
class BufferPool {
	/* a copy of FlxPool, just for buffers */
	public static final MAX_BUFFERS = 16;

	public static var length(get, never):Int; static inline function get_length() return _pool.length;

	static var _pool:Array<BitmapData> = [];
	static var _used:Array<BitmapData> = [];

	public static function get(?width:Int, ?height:Int):BitmapData {
		var obj = _pool.pop();
		if (obj == null || obj.rect == null || obj.__texture == null) obj = BitmapDataUtil.create(width ?? 0, height ?? 0);
		else if (width != null && height != null) {
			BitmapDataUtil.resize(obj, width, height);
			BitmapDataUtil.clear(obj);
		}

		_used.push(obj);
		return obj;
	}

	public static function put(obj:BitmapData, disposeUnknown = true):BitmapData {
		if (obj != null) {
			final i = _used.indexOf(obj);
			if (i != -1) {
				_used.swapAndPop(i);
				if (length > MAX_BUFFERS) obj.dispose();
				else if (obj.rect != null && obj.__texture != null) _pool.push(obj);
			}
			else if (disposeUnknown) obj.dispose();
		}
		return null;
	}

	public static function clear() {
		var obj;
		while ((obj = _pool.pop()) != null) obj.dispose();
		if (_used.length != 0) trace('Warning! BufferPool still have left used ${_used.length} buffers!');
	}
}