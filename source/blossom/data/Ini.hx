package blossom;

typedef IniSection = Map<String, String>;
typedef RawIni = Map<String, IniSection>;

abstract Ini(RawIni) from RawIni to RawIni {
	public static inline function parse(text:String):Ini return IniParser.parse(text);
	public static inline function stringify(value:Ini):String return IniParser.stringify(value);

	public inline function new() this = new RawIni();
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
			var line = data.substring(iln, ((iln = data.indexOf('\n', iln) + 1) == 0 ? data.length : iln - 1));
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
}