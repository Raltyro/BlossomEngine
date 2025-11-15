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
	static var libraries:Array<Library> = [
		{name: "lime", version: "8.3.0"},
		{name: "openfl", version: "9.5.0"},
		{name: "flixel", version: "6.1.1"},
		{name: "flixel-addons", version: "3.3.2"},
		{name: "flixel-animate", url: "https://github.com/MaybeMaru/flixel-animate"},
		{name: "moonchart", url: "https://github.com/MaybeMaru/moonchart"},
		{name: "hxjson5"},
		//{name: "hscript-improved", url: "https://github.com/CodenameCrew/hscript-improved"},
		{name: "rulescript", url: "https://github.com/Kriptel/RuleScript", ref: "dev"},
		{name: "hxvlc", version: "2.2.4"},
		{name: "hxdiscord_rpc", version: "1.3.0"},
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

					//Sys.command('haxelib --always --quiet --skip-dependencies git ${lib.name} ${lib.url}${lib.ref != null ? " " + lib.ref : ""}');

					if (FileSystem.exists('${lib.dir}/git')) {
						Sys.setCwd('${mainCwd}/${lib.dir}/git');
						Sys.command('git checkout');
						if (lib.ref == null) Sys.command('git pull origin'); else Sys.command('git pull origin ${lib.ref}');
					}
					else {
						Sys.setCwd('${mainCwd}/${lib.dir}');
						Sys.command('git clone "${lib.url}" git');
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

					Sys.command('haxelib --always --quiet --skip-dependencies install ${lib.name} ${vers}');
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