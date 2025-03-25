package funkin.state;

class TitleState extends BLState {
	override function create() {
		super.create();

		#if BASE_GAME_ASSETS
		PlayState.playSong('satin panties erect', 'nightmare');
		#else
		PlayState.playSong('tutorial');
		#end
	}
}