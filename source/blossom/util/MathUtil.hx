package blossom.util;

final class MathUtil {
	/**
	 * Checks if a is less than b with considering a margin of error.
	 * 
	 * @param a Float
	 * @param b Float
	 * @param margin Float (Default: EPSILON)
	 * 
	 * @return Bool
	**/
	public static function lessThan(a:Float, b:Float, margin:Float = 0.0000001):Bool {
		return a < b - margin;
	}

	/**
	 * Checks if a is less than or equally b with considering a margin of error.
	 * 
	 * @param a Float
	 * @param b Float
	 * @param margin Float (Default: EPSILON)
	 * 
	 * @return Bool
	**/
	public static function lessThanEqual(a:Float, b:Float, margin:Float = 0.0000001):Bool {
		return a <= b - margin;
	}

	/**
	 * Checks if a is greater than b with considering a margin of error.
	 * 
	 * @param a Float
	 * @param b Float
	 * @param margin Float (Default: EPSILON)
	 * 
	 * @return Bool
	**/
	public static function greaterThan(a:Float, b:Float, margin:Float = 0.0000001):Bool {
		return a > b + margin;
	}

	/**
	 * Checks if a is greater than or equally b with considering a margin of error.
	 * 
	 * @param a Float
	 * @param b Float
	 * @param margin Float (Default: EPSILON)
	 * 
	 * @return Bool
	**/
	public static function greaterThanEqual(a:Float, b:Float, margin:Float = 0.0000001):Bool {
		return a >= b + margin;
	}

	/**
	 * Checks if a is approximately equal to b.
	 * 
	 * @param a Float
	 * @param b Float
	 * @param margin Float (Default: EPSILON)
	 * 
	 * @return Bool
	**/
	public static function equal(a:Float, b:Float, margin:Float = 0.0000001):Bool {
		return Math.abs(a - b) <= margin;
	}

	/**
	 * Checks if a are not approximately equal to b.
	 * 
	 * @param a Float
	 * @param b Float
	 * @param margin Float (Default: EPSILON)
	 * 
	 * @return Bool
	**/
	public static function notEqual(a:Float, b:Float, margin:Float = 0.0000001):Bool {
		return Math.abs(a - b) > margin;
	}

	public static function maxInt(v0:Int, v1:Int)
		#if cpp
		return untyped __cpp__("((({0}) < ({1})) ? ({1}) : ({0}))", v0, v1);
		#else
		return v0 < v1 ? v1 : v0;
		#end

	public static function minInt(v0:Int, v1:Int)
		#if cpp
		return untyped __cpp__("((({0}) > ({1})) ? ({1}) : ({0}))", v0, v1);
		#else
		return v0 > v1 ? v1 : v0;
		#end

	public static function bound(value:Float, min:Float, max:Float):Float
		#if cpp
		return untyped __cpp__("((({0}) < ({1})) ? ({1}) : (({0}) > ({2})) ? ({2}) : ({0}))", value, min, max);
		#else
		return (value < min) ? min : (value > max) ? max : value;
		#end

	public static function boundInt(value:Int, min:Int, max:Int):Int
		#if cpp
		return untyped __cpp__("((({0}) < ({1})) ? ({1}) : (({0}) > ({2})) ? ({2}) : ({0}))", value, min, max);
		#else
		return (value < min) ? min : (value > max) ? max : value;
		#end

	public static function boolToInt(b:Bool):Int
		#if cpp
		return untyped __cpp__("(({0}) ? 1 : 0)", b);
		#else
		return b ? 1 : 0;
		#end
}