package bl.util;

import haxe.io.Bytes;

import sys.io.File;
import sys.FileSystem;

import flixel.util.typeLimit.OneOfTwo;

using StringTools;

class FileUtil {
	public static function createMissingFolders(path:String) {
		#if sys
		if (!FileSystem.exists(path)) FileSystem.createDirectory(path);
		#end
	}

	public static function saveFile(path:String, content:OneOfTwo<String, Bytes>):Bool {
		#if sys
		try {
			createMissingFolders(Paths.dir(path));
			if (content is Bytes) File.saveBytes(path, content); else File.saveContent(path, content);
			return true;
		} catch(e) {trace(e);}
		#end
		return false;
	}

	public static function openURL(targetUrl:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [targetUrl, '&']);
		#else
		FlxG.openURL(targetUrl);
		#end
	}

	public static function openFolder(targetPath:String) {
		#if windows
		Sys.command('explorer', [Paths.fix(targetPath.replace('/', '\\'))]);
		#elseif mac
		Sys.command('open', [Paths.fix(targetPath)]);
		#elseif linux
		Sys.command('open', [Paths.fix(targetPath)]);
		#end
	}

	public static function openSelectFile(targetPath:String) {
		#if windows
		Sys.command('explorer', ['/select,' + Paths.fix(targetPath.replace('/', '\\'))]);
		#elseif mac
		Sys.command('open', ['-R', Paths.fix(targetPath)]);
		#elseif linux
		Sys.command('open', [Paths.fix(targetPath)]);
		#end
	}

	public static function openFile(targetPath:String) {
		#if windows
		Sys.command('start ' + Paths.fix(targetPath.replace('/', '\\')));
		#elseif linux
		Sys.command('/usr/bin/xdg-open', [Paths.fix(targetPath)]);
		#else
		Sys.command('open', [Paths.fix(targetPath)]);
		#end
	}
}