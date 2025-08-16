import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

using StringTools;

typedef Library = {
	name:String,
	?version:String,
	?url:String,
	?ref:String,
	?dir:String
}

class UpdateHaxelib {
	static final libraries:Array<Library> = [
		{name: "lime", url: "https://github.com/Raltyro/lime", ref: "9daf48fa4d96cd4177c9b1adb94f3c7ec4338668"},
		{name: "openfl", url: "https://github.com/swordcubes-grave-of-shite/openfl"},
		{name: "flixel", url: "https://github.com/swordcubes-grave-of-shite/flixel"},
		{name: "flixel-addons", version: "3.3.2"},
		{name: "hscript-improved", url: "https://github.com/CodenameCrew/hscript-improved"},
		{name: "flixel-animate", url: "https://github.com/MaybeMaru/flixel-animate"},
		{name: "hxvlc", version: "2.2.2"},
		{name: "hxdiscord_rpc"}
	];

	public static function main() {
		final prevCwd = Sys.getCwd(), mainCwd = getProcessOutput('haxelib', ['config']).rtrim();
		Sys.setCwd(mainCwd);

		try {
			Sys.println("Preparing installation...");

			for (lib in libraries) {
				if (lib.dir == null) lib.dir = lib.name.replace('.', ',');
				if (lib.url != null) {
					if (lib.ref == null) lib.ref = '';
					if (!FileSystem.exists(lib.dir)) FileSystem.createDirectory(lib.dir);

					Sys.println('Installing "${lib.name}" from "${lib.url}" ${lib.ref}');

					if (FileSystem.exists('${lib.dir}/git')) {
						Sys.setCwd('${mainCwd}/${lib.dir}/git');
						Sys.command('git checkout');
						if (lib.ref == null) Sys.command('git pull origin'); else Sys.command('git pull origin ${lib.ref}');
					}
					else {
						Sys.setCwd('${mainCwd}/${lib.dir}');
						Sys.command('git clone --recurse-submodules "${lib.url}" git');
						Sys.setCwd('${mainCwd}/${lib.dir}/git');
						if (lib.ref == null) Sys.command('git pull origin'); else Sys.command('git pull origin ${lib.ref}');
					}
					Sys.setCwd('${mainCwd}/${lib.dir}');
					File.saveContent('${mainCwd}/${lib.dir}/.current', 'git');
					Sys.setCwd(mainCwd);
				}
				else {
					Sys.println('Installing "${lib.name}"...');   
					var vers = lib.version != null ? lib.version : "";          

					Sys.command('haxelib install ${lib.name} ${vers} --quiet --skip-dependencies');
					if (lib.version != null) File.saveContent('${mainCwd}/${lib.dir}/.current', lib.version);
				}
			}
		}
		catch(e) {
			trace(e);
		}

		Sys.setCwd(prevCwd);
	}

	public static function getProcessOutput(cmd:String, args:Array<String>):String {
		try {
			var process = new Process(cmd, args), output = "";
			try {output = process.stdout.readAll().toString();}
			catch (_) {}

			process.close();
			return output;
		}
		catch (_) {
			return "";
		}
	}
}