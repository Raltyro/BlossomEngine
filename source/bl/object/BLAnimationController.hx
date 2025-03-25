package bl.object;

import flixel.animation.FlxAnimationController;

class BLAnimationController extends FlxAnimationController {
	var _blSprite:BLSprite;

	var _pendingAnimations:Map<String, BLAnimData>;

	public function new(sprite:BLSprite) {
		super(_blSprite = sprite);
	}

	public function addBLAnim(anim:BLAnimData, preloadMulti = false) {
		if (anim.asset != null) {
			if (preloadMulti /*|| !(anim.asset is String)*/) {

			}
			else {
				_pendingAnimations.set(anim.name, anim);
			}
		}
	}
}