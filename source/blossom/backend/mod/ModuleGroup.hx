package blossom.backend.mod;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxSignal.FlxTypedSignal;

typedef ModuleGroup = TypedModuleGroup<Module>;

@:build(blossom.backend.macro.ModuleMacro.buildModuleGroup())
class TypedModuleGroup<T:Module> implements IFlxDestroyable {
	public static var global:ModuleGroup = new ModuleGroup();

	public var members(default, null):Array<T>; // Fewer priorities, last indices
	public var length(default, null):Int = 0;

	public var active(default, set):Bool = true;
	@:noCompletion function set_active(v) return active = v;

	public var memberAdded(get, never):FlxTypedSignal<T->Void>;
	public var memberRemoved(get, never):FlxTypedSignal<T->Void>;

	var _memberAdded:FlxTypedSignal<T->Void>;
	var _memberRemoved:FlxTypedSignal<T->Void>;

	public function new()
		members = [];

	public function destroy() {
		if (members != null) {
			var count = length;
			while (count-- > 0) {
				final module = members.shift();
				if (module != null) module.destroy();
			}

			members = null;
		}
	}

	// for optimization reason, it wont return anything if results is not passed
	public function call(func:String, ?parameters:Array<Dynamic>, ?results:Array<Dynamic>):Array<Dynamic> {
		if (global != cast this) results = global.call(func, parameters, results);

		if (results == null) {
			for (module in members) if (module.active) module.call(func, parameters);
		}
		else {
			var r:Dynamic;
			for (module in members) if (module.active) {
				if ((r = module.call(func, parameters)) != null)
					results.push(r);
			}
		}
		return results;
	}

	public function event<T:ModuleEvent>(event:T, ?func:String, ?prefix:String, ?suffix:String):T {
		if ((func = func ?? event.callbackName) == null) return event;
		if (prefix != null) func = prefix + func;
		if (suffix != null) func += suffix;

		if (global != cast this) {
			global.event(event, func);
			if (event.cancelled && !event.continueCalls) return event;
		}

		for (module in members) if (module.active) {
			module.call1(func, event);
			if (event.cancelled && !event.continueCalls) break;
		}

		return event;
	}

	inline public function eventPost<T:ModuleEvent>(event:T, ?func:String):T
		return this.event(event, null, null, "Post");

	public function add(module:T):T {
		if (module == null || !module.exists || members == null || members.indexOf(module) >= 0) return module;

		var idx = 0;
		for (other in members) if (module.priority > other.priority) break; else idx++;
		members.insert(idx, module);

		length++;
		onMemberAdd(module);

		return module;
	}

	public function remove(module:T):T {
		if (module == null || members == null) return module;

		final idx = members.indexOf(module);
		if (idx < 0) return module;

		members.splice(idx, 1);
		onMemberRemove(module);

		return module;
	}

	public function removeAtIndex(idx:Int):Null<T> {
		if (idx < 0 || idx >= length) return null;

		final module = members.splice(idx, 1)[0];
		onMemberRemove(module);

		return module;
	}

	public function clear() {
		length = 0;

		if (_memberRemoved != null) for (member in members) onMemberRemove(member);
		members.clearArray();
	}

	function onMemberAdd(member:T) {
		member.groups.push(cast this);
		if (_memberAdded != null) _memberAdded.dispatch(cast member);
	}

	function onMemberRemove(member:T) {
		member.groups.remove(cast this);
		if (_memberRemoved != null) _memberRemoved.dispatch(cast member);
	}

	@:noCompletion
	function get_memberAdded():FlxTypedSignal<T->Void> {
		if (_memberAdded == null) _memberAdded = new FlxTypedSignal<T->Void>();
		return _memberAdded;
	}

	@:noCompletion
	function get_memberRemoved():FlxTypedSignal<T->Void> {
		if (_memberRemoved == null) _memberRemoved = new FlxTypedSignal<T->Void>();
		return _memberRemoved;
	}
}