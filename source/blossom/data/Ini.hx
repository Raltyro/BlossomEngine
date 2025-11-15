package blossom.data;

typedef IniSection = Map<String, String>;
typedef RawIni = Map<String, IniSection>;

abstract Ini(RawIni) from RawIni to RawIni {
	public static inline function parse(text:String):Ini return IniParser.parse(text);
	public static inline function stringify(ini:Ini):String return IniParser.stringify(ini);

	public inline function new() this = new RawIni();
	public inline function set(key:String, value:IniSection) this.set(key, value);
	@:arrayAccess public inline function get(key:String) return this.get(key);
	public inline function exists(key:String) return this.exists(key);
	public inline function remove(key:String) return this.remove(key);
	public inline function keys():Iterator<String> return this.keys();
	public inline function iterator():Iterator<IniSection> return this.iterator();
	public inline function keyValueIterator():KeyValueIterator<String, IniSection> return this.keyValueIterator();
	public inline function copy():Ini return cast this.copy();
	public inline function toString():String return this.toString();
	public inline function clear() this.clear();
	@:arrayAccess public inline function arrayWrite(k:String, v:IniSection):IniSection {
		this.set(k, v);
		return v;
	}
}

class IniParser {
	public static function parse(text:String):Ini {
		var result = new Ini();
		parseSectionsToIni(result, text);
		return result;
	}

	public static function parseSectionsToIni(ini:Ini, text:String) {
		var section:IniSection = null;

		var regexSec = ~/^\[(.+)\]/g, regexVal = ~/^([^#;].+)=(.+)/g, quote = ~/[\\'"](.+)[\\'"]/g, iln = 0;
		do {
			var line = text.substring(iln, ((iln = text.indexOf('\n', iln) + 1) == 0 ? text.length : iln - 1));
			if (regexSec.match(line)) {
				if ((section = ini.get(regexSec.matched(1))) == null) ini.set(regexSec.matched(1), section = new IniSection());
			}
			else if (regexVal.match(line)) {
				var s = regexVal.matched(2).trim();
				if (quote.match(s)) s = quote.matched(1);

				if (section == null) {
					if ((section = ini.get("Global")) == null) ini.set("Global", section = new IniSection());
				}
				section.set(regexVal.matched(1).trim(), s);
			}
		} while (iln != 0);
	}

	public static function stringify(ini:Ini):String throw "IMPLEMENT THIS! blossom.data.IniParser.stringify";
}