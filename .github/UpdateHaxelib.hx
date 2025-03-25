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
		{name: "flixel", url: "https://github.com/swordcubes-grave-of-shite/flixel"},
		{name: "flixel-addons", version: "3.3.2"},
		{name: "polymod", version: "1.8.0"},
		{name: "hscript", version: "2.6.0"},
		{name: "flxanimate", url: "https://github.com/Dot-Stuff/flxanimate"},
		{name: "openfl", url: "https://github.com/Raltyro/openfl", ref: "517a694b5322e951232aa14d733e26286edc256c"},
		{name: "lime", url: "https://github.com/Raltyro/lime", ref: "6e8d499e108159e14bf93bf85dbe9a0e0d51aa67"},
		{name: "jsonpath", url: "https://github.com/EliteMasterEric/jsonpath"},
		{name: "thx.core", url: "https://github.com/fponticelli/thx.core", ref: '76d87418fadd92eb8e1b61f004cff27d656e53dd'},
		{name: "thx.semver", url: "https://github.com/fponticelli/thx.semver", ref: 'bdb191fe7cf745c02a980749906dbf22719e200b'},
		{name: "hxjson5"},
		{name: "hxIni"},
		{name: "hxvlc", url: "https://github.com/Vortex2Oblivion/hxvlc"},
		{name: "hxdiscord_rpc", version: "1.3.0"},
	];

	public static function main() {
		final prevCwd = Sys.getCwd(), mainCwd = getProcessOutput('haxelib', ['config']).rtrim();
		Sys.setCwd(mainCwd);

		try {
			Sys.println("Preparing installation...");

			for (lib in libraries) {
				if (lib.url != null) {
					if (lib.dir == null) lib.dir = lib.name;
					if (lib.ref == null) lib.ref = '';

					if (!FileSystem.exists(lib.dir)) FileSystem.createDirectory(lib.dir);
					else if (FileSystem.exists('${lib.dir}/dev')) continue;

					Sys.println('Installing "${lib.name}" from git url "${lib.url}" ${lib.ref}');

					if (FileSystem.exists('${lib.dir}/git')) {
						Sys.setCwd('${mainCwd}/${lib.dir}/git');
						Sys.command('git checkout');
						if (lib.ref == null) Sys.command('git pull origin ${lib.ref}'); else Sys.command('git pull origin');
					}
					else {
						Sys.setCwd('${mainCwd}/${lib.dir}');
						Sys.command('git clone --recurse-submodules ${lib.url} git');
						if (lib.ref == null) Sys.command('git pull origin ${lib.ref}'); else Sys.command('git pull origin');
						File.saveContent('.current', 'git');
					}
					Sys.setCwd(mainCwd);
				}
				else {
					Sys.println('Installing "${lib.name}"...');   
					var vers = lib.version != null ? lib.version : "";          

					Sys.command('haxelib install ${lib.name} ${vers} --quiet');
					if (lib.version != null) File.saveContent('${lib.name}/.current', vers);
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