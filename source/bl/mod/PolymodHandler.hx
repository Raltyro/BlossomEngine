package bl.mod;

#if polymod
import polymod.format.ParseRules;
import polymod.Polymod;
#end

import bl.util.FileUtil;

class PolymodHandler {
	public static var loadedMods(default, null):Array<String> = [];
	public static var useSourceAssets:Bool = false;
	public static var useRealTimeAssets:Bool = #if debug true #else false #end; // FOR TESTING

	public static var MOD_FOLDER(get, never):String;
	static function get_MOD_FOLDER() return useSourceAssets ? SOURCE_MOD_FOLDER : DEFAULT_MOD_FOLDER;
	static final DEFAULT_MOD_FOLDER:String = 'mods';
	static final SOURCE_MOD_FOLDER:String =
		#if macos
		'../../../../../../../default_mods'
		#else
		'../../../../default_mods'
		#end;

	public static var CORE_FOLDER(get, never):Null<String>;
	static function get_CORE_FOLDER() return useSourceAssets ? SOURCE_CORE_FOLDER : DEFAULT_CORE_FOLDER;
	static final DEFAULT_CORE_FOLDER:Null<String> = null;
	static final SOURCE_CORE_FOLDER:Null<String> =
		#if macos
		'../../../../../../../assets'
		#else
		'../../../../assets'
		#end;

	public static function createModRoot() FileUtil.createMissingFolders(MOD_FOLDER);

	public static function loadMods(?mods:Array<String>) {
		#if polymod
		createModRoot();
		if (mods == null) mods = [];

		final loadedModList:Array<ModMetadata> = Polymod.init({
			modRoot: MOD_FOLDER,
			dirs: mods,
			framework: OPENFL,
			//apiVersionRule:
			//errorCallback:
			//customFilesystem:
			frameworkParams: getFrameworkParams(),
			ignoredFiles: Polymod.getDefaultIgnoreList(),
			parseRules: getParseRules(),
			//useScriptedClasses: true,
			loadScriptsAsync: true
		});

		if (loadedModList == null) return;

		loadedMods.resize(0);
		for (mod in loadedModList) {
			loadedMods.push(mod.id);
			trace('Loaded Mod ${mod.title} v${mod.modVersion} [${mod.id}]');
		}
		#end
	}

	static function getFrameworkParams():#if polymod FrameworkParams #else Dynamic #end {
		final assetLibraryPaths:Map<String, String> = [
			for (library in @:privateAccess lime.utils.Assets.libraries.keys())
				library => (library == 'default' ? 'preload' : library)
		];

		#if BASE_GAME_ASSETS
		assetLibraryPaths.set('week1', 'base_game/week1');
		assetLibraryPaths.set('week2', 'base_game/week2');
		assetLibraryPaths.set('week3', 'base_game/week3');
		assetLibraryPaths.set('week4', 'base_game/week4');
		assetLibraryPaths.set('week5', 'base_game/week5');
		assetLibraryPaths.set('week6', 'base_game/week6');
		assetLibraryPaths.set('week7', 'base_game/week7');
		assetLibraryPaths.set('weekend1', 'base_game/weekend1');
		#end

		if (!useSourceAssets && useRealTimeAssets) assetLibraryPaths.set('default', '');
		return {
			assetLibraryPaths: assetLibraryPaths,
			coreAssetRedirect: (!useSourceAssets && useRealTimeAssets) ? 'assets' : CORE_FOLDER
		}
	}

	static function getParseRules():#if !polymod Dynamic return null; #else ParseRules {
		final rules = ParseRules.getDefault();
		rules.addType('txt', TextFileFormat.LINES);
		rules.addType('hscript', TextFileFormat.PLAINTEXT);
		rules.addType('hxc', TextFileFormat.PLAINTEXT);
		rules.addType('hxs', TextFileFormat.PLAINTEXT);
		rules.addType('hx', TextFileFormat.PLAINTEXT);

		return rules;
	} #end
}