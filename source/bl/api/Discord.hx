package bl.api;

import flixel.graphics.FlxGraphic;
import flixel.util.FlxSignal;

#if !NO_DISCORD
import cpp.Function;
import cpp.RawPointer;
import cpp.RawConstPointer;
import cpp.ConstPointer;
import cpp.ConstCharStar;
import cpp.Star;

import haxe.Int64;

import sys.thread.Deque;
import sys.thread.Thread;

import lime.app.Application;
import lime.net.HTTPRequest;
import hxdiscord_rpc.Discord as HxDiscord;
import hxdiscord_rpc.Types;
#end

enum abstract DiscordSignalType(String) from String to String {
	var READY = 'Ready';
	var DISCONNECTED = 'Disconnected';
	var ERROR = 'Error';
}

class Discord {
	public static final defaultID:String = "1045626896752320575";
	public static var clientID(default, set):String = defaultID;

	public static var active:Bool = false;

	public static var connected:Bool = false;
	public static var userId:String;
	public static var username:String;
	public static var discriminator:String;
	public static var avatar:String;

	public static function resetPresence() {
		details = 'Initial';
		state = null;
		largeImageKey = 'icon';
		largeImageText = 'YOU CANT BEAT EM';
		smallImageKey = '';
		smallImageText = '';
		clearTimestamp();
	}

	public static var details(default, set):String;
	public static var state(default, set):Null<String>;
	public static var largeImageKey(default, set):Null<String>;
	public static var largeImageText(default, set):Null<String>;
	public static var smallImageKey(default, set):Null<String>;
	public static var smallImageText(default, set):Null<String>;
	public static var startTimestamp(default, set):Float;
	public static var endTimestamp(default, set):Float;

	public static var onReady(default, null):FlxSignal = new FlxSignal();
	public static var onDisconnected(default, null):FlxTypedSignal<Int->String->Void> = new FlxTypedSignal<Int->String->Void>();
	public static var onError(default, null):FlxTypedSignal<Int->String->Void> = new FlxTypedSignal<Int->String->Void>();

	#if !NO_DISCORD
	private static var presence:DiscordRichPresence = new DiscordRichPresence();
	private static var requestSignals:Deque<{type:DiscordSignalType, ?data:Array<Dynamic>}> = new Deque();

	public static function start() {
		if (active) {
			trace("Discord RPC already Started!");
			return;
		}

		active = true;
		resetPresence();

		var discordHandlers:DiscordEventHandlers = new DiscordEventHandlers();
		discordHandlers.ready = Function.fromStaticFunction(ready);
		discordHandlers.disconnected = Function.fromStaticFunction(disconnected);
		discordHandlers.errored = Function.fromStaticFunction(error);

		Thread.create(_thread.bind(discordHandlers));
		Application.current.onExit.add((_) -> shutdown());
		Application.current.onUpdate.add(_update);
	}

	private static function _thread(discordHandlers:DiscordEventHandlers) {
		var localID:String = clientID;
		HxDiscord.Initialize(localID, RawPointer.addressOf(discordHandlers), true, null);

		while (localID == clientID && active) {
			#if DISCORD_DISABLE_IO_THREAD HxDiscord.UpdateConnection(); #end
			HxDiscord.RunCallbacks();

			Sys.sleep(2);
		}
	}

	private static function _update(_) {
		var request;
		while ((request = requestSignals.pop(false)) != null) {
			var signal = Reflect.field(Discord, 'on${request.type}');
			if (signal != null) try {
				var dispatch = Reflect.field(signal, 'dispatch');
				if (dispatch != null) Reflect.callMethod(signal, dispatch, request.data ?? []);
			}
			catch (e) {}
		}
	}

	public static function changePresence(details:String, ?state:String, ?largeImageKey:String, ?largeImageText:String,
		?smallImageKey:String, ?smallImageText:String)
	{
		if (largeImageKey != null) Discord.largeImageKey = largeImageKey;
		if (largeImageText != null) Discord.largeImageText = largeImageText;
			
		Discord.details = details;
		Discord.state = state;
		Discord.smallImageKey = smallImageKey;
		Discord.smallImageText = smallImageText;
		
		updatePresence();
	}

	public static function updatePresence() {
		presence.details = details;
		presence.state = state;
		presence.largeImageKey = largeImageKey;
		presence.largeImageText = largeImageText;
		presence.smallImageKey = smallImageKey;
		presence.smallImageText = smallImageText;
		presence.startTimestamp = Int64.fromFloat(startTimestamp);
		presence.endTimestamp = Int64.fromFloat(endTimestamp);

		HxDiscord.UpdatePresence(RawConstPointer.addressOf(presence));
	}

	inline public static function clearTimestamp() endTimestamp = startTimestamp = 0;

	public static function shutdown() if (active) {
		active = connected = false;
		HxDiscord.Shutdown();

		Application.current.onUpdate.remove(_update);
		_update(0);
	}

	public static function loadAvatarGraphic(?userId:String, ?avatar:String):Future<FlxGraphic> {
		if (userId == null) userId = Discord.userId;
		if (avatar == null) avatar = Discord.avatar;

		var key = 'https://cdn.discordapp.com/avatars/${userId}/${avatar}.png';
		var graphic = FlxG.bitmap.get(key);
		if (graphic != null) return Future.withValue(graphic);

		if (userId == null && avatar == null && !connected && active) {
			var promise = new Promise<FlxGraphic>();
			onReady.addOnce(() -> loadAvatarGraphic(userId, avatar).onComplete((graphic) -> promise.complete(graphic)));
			return promise.future;
		}
		else if (userId == null || avatar == null) return cast Future.withError('userId or avatar is null');

		return AssetUtil.loadHTTPGraphic(key, true);
	}

	private static function ready(request:RawConstPointer<DiscordUser>):Void {
		var ptr:Star<DiscordUser> = ConstPointer.fromRaw(request).ptr;
		userId = cast ptr.userId;
		username = cast ptr.username;
		discriminator = cast ptr.discriminator;
		avatar = cast ptr.avatar;

		connected = true;

		Sys.println('Discord: Connected to User (${username}#${discriminator}, avatar: ${avatar})');
		requestSignals.add({type: READY});
	}

	private static function disconnected(errorCode:Int, message:ConstCharStar):Void {
		connected = false;

		Sys.println('Discord: Disconnected ($errorCode: ${cast(message, String)})');
		requestSignals.add({type: READY, data: [errorCode, cast(message, String)]});
	}

	private static function error(errorCode:Int, message:ConstCharStar):Void {
		Sys.println('Discord: Error ($errorCode: ${cast(message, String)})');
		requestSignals.add({type: READY, data: [errorCode, cast(message, String)]});
	}

	static function set_clientID(newID:String):String {
		if (clientID != newID) {
			clientID = newID;
			if (active) {
				shutdown();
				start();
				//updatePresence();
			}
		}
		return newID;
	}

	static function set_details(v:String):String {details = v; updatePresence(); return v;}
	static function set_state(v:Null<String>):Null<String> {state = v; updatePresence(); return v;}
	static function set_largeImageKey(v:Null<String>):Null<String> {largeImageKey = v; updatePresence(); return v;}
	static function set_largeImageText(v:Null<String>):Null<String> {largeImageText = v; updatePresence(); return v;}
	static function set_smallImageKey(v:Null<String>):Null<String> {smallImageKey = v; updatePresence(); return v;}
	static function set_smallImageText(v:Null<String>):Null<String> {smallImageText = v; updatePresence(); return v;}
	static function set_startTimestamp(v:Float):Float {startTimestamp = v; updatePresence(); return v;}
	static function set_endTimestamp(v:Float):Float {endTimestamp = v; updatePresence(); return v;}
	#else
	public static function start() resetPresence();
	public static function changePresence(details:String, ?state:String, ?largeImageKey:String, ?largeImageText:String,
		?smallImageKey:String, ?smallImageText:String) {}
	public static function updatePresence() {}
	public static function clearTimestamp() {}
	public static function shutdown() {}

	public static function loadAvatarGraphic():Future<FlxGraphic> return cast Future.withError('getAvatarGraphic is unsupported');

	static function set_clientID(newID:String):String return clientID = newID;
	static function set_details(v:String):String return details = v;
	static function set_state(v:Null<String>):Null<String> return state = v;
	static function set_largeImageKey(v:Null<String>):Null<String> return largeImageKey = v;
	static function set_largeImageText(v:Null<String>):Null<String> return largeImageText = v;
	static function set_smallImageKey(v:Null<String>):Null<String> return smallImageKey = v;
	static function set_smallImageText(v:Null<String>):Null<String> return smallImageText = v;
	static function set_startTimestamp(v:Float):Float return startTimestamp = v;
	static function set_endTimestamp(v:Float):Float return endTimestamp = v;
	#end
}