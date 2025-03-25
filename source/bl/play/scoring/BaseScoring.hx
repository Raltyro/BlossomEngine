package bl.play.scoring;

import bl.play.Highscore.Judgment;

class BaseScoring {
	public function new() {}

	public function judgeHealth(judge:Judgment):Float {
		return switch (judge) {
			case PERFECT: 2.0 / 100 * 2;
			case SICK: 1.5 / 100 * 2;
			case GOOD: 0.75 / 100 * 2;
			case BAD: 0.0;
			case SHIT: -1.0 / 100 * 2;
			default: -4.0 / 100 * 2;
		}
	}
	public function bonusHoldHealth(duration:Float):Float return 7.5 / 100 * 2 * duration / 1000;
	public function scoreMiss(tap:Bool):Int return tap ? -80 : -100;
	public function scoreNote(timing:Float):Int return 0;
	public function scoreHold(duration:Float):Int return 0;
	public function judgeNote(timing:Float):Judgment return MISS;
}