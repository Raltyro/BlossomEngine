package bl.mod;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;

class Module implements IFlxDestroyable {
	public var exists(default, set):Bool = true;
	@:noCompletion function set_exists(v) return exists = v;

	public var active(default, set):Bool = true;
	@:noCompletion function set_active(v) return active = v;

	public var priority(default, set):Int;
	function set_priority(v) {
		priority = v;
		for (group in groups) {
			group.members.remove(this);

			var idx = 0;
			for (other in group.members) if (priority > other.priority) break; else idx++;
			group.members.insert(idx, this);
		}
		return v;
	}

	public var groups:Array<ModuleGroup> = [];

	public function new(priority:Int = 0) {
		this.priority = priority;
		call('create');
	}

	public function call(func:String, ?parameters:Array<Dynamic>):Dynamic {
		if (func == 'destroy') FlxG.log.warn('Attempting to destroy a module through calling the module');

		final func = Reflect.field(this, func);
		if (Reflect.isFunction(func)) return (parameters != null && parameters.length > 0) ? Reflect.callMethod(this, func, parameters) : func();

		return null;
	}

	public function destroy() {
		exists = false;
		for (group in groups) group.remove(this);
	}
}