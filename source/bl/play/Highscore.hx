package bl.play;

enum abstract Judgment(UInt) from UInt to UInt {
	var MISS = 0;
	var SHIT = 1;
	var BAD = 2;
	var GOOD = 3;
	var SICK = 4;
	var PERFECT = 5;

	@:to
	public inline function toString():String return switch(this) {
		case 5: 'perfect';
		case 4: 'sick';
		case 3: 'good';
		case 2: 'bad';
		case 1: 'shit';
		default: 'miss';
	}

	public inline function checkSplash():Bool return this >= 4;
}

class Highscore {
	public static function combineTallies(dst:Tallies, src:Tallies):Tallies {
		return {
			score: dst.score + src.score,
			combo: dst.combo,
			maxCombo: Math.floor(Math.max(dst.maxCombo, src.maxCombo)),
			misses: dst.misses + src.misses,
			shit: dst.shit + src.shit,
			bad: dst.bad + src.bad,
			good: dst.good + src.good,
			sick: dst.sick + src.sick,
			perfect: dst.perfect + src.perfect,
			lastDeaths: dst.lastDeaths + src.lastDeaths,
			lastHealth: dst.lastHealth
		};
	}

	public static function getTotalNotes(tallies:Tallies):UInt
		return tallies.shit + tallies.bad + tallies.good + tallies.sick + tallies.perfect;
}

@:forward
abstract Tallies(RawTallies) from RawTallies from Dynamic to RawTallies to Dynamic {
	public function new() this = {};

	public function getJudgmentCount(judge:Judgment):UInt {
		switch (judge) {
			case MISS: return this.misses;
			case SHIT: return this.shit;
			case BAD: return this.bad;
			case GOOD: return this.good;
			case SICK: return this.sick;
			case PERFECT: return this.perfect;
		}
	}

	public function setJudgmentCount(judge:Judgment, value:UInt):UInt {
		switch (judge) {
			case MISS: return this.misses = value;
			case SHIT: return this.shit = value;
			case BAD: return this.bad = value;
			case GOOD: return this.good = value;
			case SICK: return this.sick = value;
			case PERFECT: return this.perfect = value;
		}
	}

	public function incrementJudgmentCount(judge:Judgment, comboPersist = false):UInt {
		if (!comboPersist) {
			if (judge == MISS) this.combo = (this.combo > 0 ? 0 : this.combo) - 1;
			else if ((this.combo = (this.combo < 0 ? 0 : this.combo) + 1) > this.maxCombo) this.maxCombo = this.combo;
		}
		switch (judge) {
			case MISS: return ++this.misses;
			case SHIT: return ++this.shit;
			case BAD: return ++this.bad;
			case GOOD: return ++this.good;
			case SICK: return ++this.sick;
			case PERFECT: return ++this.perfect;
		}
	}
}

@:structInit
class RawTallies {
	public var score:UInt = 0;

	public var combo:Int = 0;
	public var maxCombo:UInt = 0;
	public var misses:UInt = 0;

	public var shit:UInt = 0;
	public var bad:UInt = 0;
	public var good:UInt = 0;
	public var sick:UInt = 0;
	public var perfect:UInt = 0;

	public var lastDeaths:UInt = 0;
	public var lastHealth:Float = 0;
}