package blossom.backend.mod;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;

@:autoBuild(blossom.backend.macro.ModuleMacro.autoBuildModuleEvent())
class ModuleEvent implements IFlxDestroyable {
	static final caches:ObjectMap<Dynamic, Array<ModuleEvent>> = new ObjectMap<Dynamic, Array<ModuleEvent>>();

	inline public static function reset() caches.clear();

	public static function get<T:ModuleEvent>(cls:Class<T>, weak = true):T {
		var cache = caches.get(cls);
		if (cache == null) caches.set(cls, cache = []);

		for (event in cache) if (event.weak) {
			event.weak = weak;
			return cast event;
		}

		final event = Type.createInstance(cls, []);
		event.weak = weak;

		cache.push(event);
		return event;
	}

	public var callbackName:Null<String>;

	public var cancelled:Bool;
	public var continueCalls:Bool;

	public var weak:Bool;

	public var data:Dynamic;

	public function new() {}

	inline public function put() weak = true;

	public function cancel(c = true) {
		cancelled = true;
		continueCalls = c;
	}

	public function recycleBase() {
		data = null;
		cancelled = false;
		continueCalls = true;
	}

	public function destroy() {
		data = null;
	}

	public function toString():String {
		final name = Type.getClassName(Type.getClass(this)).split('.');
		return '[${name[name.length - 1]}${cancelled ? " (Cancelled)" : ""}]';
	}
}