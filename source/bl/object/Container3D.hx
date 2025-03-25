package bl.object;

import flixel.group.FlxContainer;
import flixel.util.FlxDestroyUtil;
import flixel.FlxBasic;

import bl.math.Perspective;

typedef Container3D = TypedContainer3D<FlxBasic>;

class TypedContainer3D<T:FlxBasic> extends FlxTypedContainer<T> {
	@:allow(bl.object.Object3D)
	var parentObject:Object3D;	

	public function new(maxSize = 0, ?parent:Object3D) {
		parentObject = parent;
		super(maxSize);
	}

	override function get_container() {
		return parentObject != null ? parentObject.container : this.container;
	}

	override function getCamerasLegacy()
		return parentObject != null ? parentObject.getCamerasLegacy() : super.getCamerasLegacy();
	
	override function getCameras()
		return parentObject != null ? parentObject.getCameras() : super.getCameras();
}