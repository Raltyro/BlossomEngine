package bl.play.scoring;

import bl.play.Highscore.Judgment;

class PBOT1Scoring extends BaseScoring {
	public static final MAX_SCORE:Int = 500;
	public static final MIN_SCORE:Int = 9;
	public static final HOLD_SCORE:Int = 250;
	public static final SCORING_OFFSET:Float = 54.99;
	public static final SCORING_SLOPE:Float = 0.080;
	public static final HIT_WINDOW:Float = 160.0;
	public static final PERFECT_THRESHOLD:Float = 16.0;
	public static final SICK_THRESHOLD:Float = 45.0;
	public static final GOOD_THRESHOLD:Float = 90.0;
	public static final BAD_THRESHOLD:Float = 135.0;

	override function scoreNote(timing:Float):Int {
		final absTiming = Math.abs(timing);

		if (absTiming > HIT_WINDOW) return scoreMiss(false);
		else if (absTiming <= PERFECT_THRESHOLD) return MAX_SCORE;

		final factor:Float = 1.0 - (1.0 / (1.0 + Math.exp(-SCORING_SLOPE * (absTiming - SCORING_OFFSET))));

		return Math.floor(MAX_SCORE * factor + MIN_SCORE);
	}

	override function scoreHold(duration:Float):Int return Math.floor(HOLD_SCORE * duration * 0.001);

	override function judgeNote(timing:Float):Judgment {
		return switch (Math.abs(timing)) {
			case (_ < PERFECT_THRESHOLD) => true: PERFECT;
			case (_ < SICK_THRESHOLD) => true: SICK;
			case (_ < GOOD_THRESHOLD) => true: GOOD;
			case (_ < BAD_THRESHOLD) => true: BAD;
			case (_ < HIT_WINDOW) => true: SHIT;
			default: MISS;
		}
	}
}