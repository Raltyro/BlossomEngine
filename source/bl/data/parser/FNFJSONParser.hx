package bl.data.parser;

import hxjson5.Json5;

import bl.data.Song;
import bl.util.SortUtil;
import bl.Conductor.TimeChange;

class FNFJSONParser extends ChartParser {
	override function parseChart(chart:SongChart, data:String):Bool {
		try {
			final json = Json5.parse(data);
			if (json.song is String) return legacy(chart, json);
			else if (Reflect.isObject(json.song)) return legacy(chart, json.song);
			else if (json.version is String) return vslice(chart, json);
		}
		catch(e:haxe.Exception) {trace(e.message, e.previous, e.stack);}
		return false;
	}

	private function vslice(chart:SongChart, data:Dynamic):Bool @:privateAccess {
		if (chart.song == null || !chart.song.isVanilla) throw 'This Chart Song needs to have Vanilla PlayData!';
		final playData:Dynamic = chart.song.vanillaPlayData;
		chart.timeChanges = chart.song.timeChanges.copy();
		chart.stage = playData.stage;

		final speed:Float = Reflect.field(data.scrollSpeed, chart.difficulty);

		var chars:Int = 0;
		var player:ChartPlayfield = {ID: BF, speed: speed, notes: [], skin: playData.noteStyle},
			opponent:ChartPlayfield = {ID: DAD, speed: speed, notes: [], skin: playData.noteStyle},
			gf:ChartPlayfield = {ID: GF, speed: speed, notes: [], skin: playData.noteStyle, visible: false};

		chart.playfields = [player, opponent, gf];
		chart.characters = [
			for (id in Reflect.fields(playData.characters)) {
				if (id == 'instrumental' || id == 'altInstrumentals' || !(Reflect.field(playData.characters, id) is String)) continue;
				final character = Reflect.field(playData.characters, id);

				{
					ID: switch(id) {
						case 'player':
							player.voice = character;
							BF;
						case 'opponent':
							opponent.voice = character;
							DAD;
						case 'girlfriend':
							gf.voice = character;
							GF;
						default: chars++;
					},
					character: character
				}
			}
		];

		final conductor = new Conductor();
		conductor.mapTimeChanges(chart.timeChanges, false);

		chart.events = [for (ev in cast(data.events, Array<Dynamic>)) vEvent(ev, chart, conductor)];

		for (note in cast(Reflect.field(data.notes, chart.difficulty), Array<Dynamic>)) {
			final d:Int = note.d ?? note.data;
			final notefield = d > 7 ? gf : (d > 3 ? opponent : player);

			final k = note.k ?? note.kind;
			notefield.notes.push({
				time: cast(note.t ?? note.time, Float),
				duration: cast(note.l ?? note.length, Float),
				type: k is String ? cast k : null,
				column: Std.int(d % 4)
			});
		}

		return true;
	}

	private function vCharID(value:Int):Int {
		return switch (value) {
			case 0: BF;
			case 1: DAD;
			case 2: GF;
			default: value - 2;
		}
	}

	private function vEvent(data:Dynamic, chart:SongChart, conductor:Conductor):ChartEvent @:privateAccess {
		final t:Float = data.t ?? data.time, e:String = data.e ?? data.eventKind, p:Dynamic = data.v ?? data.value;
		conductor.currentTimeChangeIdx = conductor.getTimeInChangeIdx(t, conductor.currentTimeChangeIdx);

		return switch (e) {
			case 'FocusCamera':
				if (p.ease == 'CLASSIC' || p.ease == null) {time: t, event: 'focus-camera', params: [vCharID(p.char), p.x, p.y]};
				else
					{time: t, event: 'focus-camera', params: [vCharID(p.char), p.x, p.y,
						(conductor.getStepsInTime(p.duration + conductor.getTimeInSteps(t)) - t) * 0.001,
						p.ease
					]};
			case 'ZoomCamera':
				if (p.ease == 'INSTANT' || p.ease == null) {time: t, event: 'zoom-camera', params: [p.zoom, p.mode == 'direct', 0, true]};
				else
					{time: t, event: 'zoom-camera', params: [p.zoom, p.mode == 'direct',
						(conductor.getStepsInTime(p.duration + conductor.getTimeInSteps(t)) - t) * 0.001,
						p.ease
					]};
			default:
				{time: t, event: e, params: Std.isOfType(p, Array) ? p : [p]};
		}
	}

	private function legacy(chart:SongChart, data:Dynamic):Bool {
		chart.characters = [];
		chart.playfields = [];

		var bfchar:String = null, dadchar:String = null, gfchar:String = null;

		if (data.gfVersion is String && data.gfVersion != '') chart.characters.push({ID: GF, character: gfchar = data.gfVersion});
		else if (data.player3 is String && data.player3 != '') chart.characters.push({ID: GF, character: gfchar = data.player3});

		if (data.player1 is String) chart.characters.push({ID: BF, character: bfchar = data.player1});
		if (data.player2 is String) chart.characters.push({ID: DAD, character: dadchar = data.player2});

		var speed:Float = data.speed ?? 1;
		var player:ChartPlayfield = {ID: BF, speed: speed, notes: []}, opponent:ChartPlayfield = {ID: DAD, speed: speed, notes: []}, gf:ChartPlayfield = null;

		// TODO... todo what? the events?
		var sectionTime:Float = 0, bpm:Float = data.bpm, numerator:Float = 4, mustHit:Null<Bool> = null, gfSection:Null<Bool> = null;
		chart.timeChanges = [{bpm: bpm}];
		chart.events = [];

		for (section in cast(data.notes, Array<Dynamic>)) {
			if (mustHit != section.mustHitSection || gfSection != section.gfSection) {
				mustHit = section.mustHitSection;
				gfSection = section.gfSection;
				chart.events.push({
					time: sectionTime,
					event: 'focus-camera',
					params: [gfSection ? GF : (mustHit ? BF : DAD)]
				});
			}
			if (section.sectionNotes != null) for (note in cast(section.sectionNotes, Array<Dynamic>)) {
				final isGFNote = gfSection || (note[3] is String && note[3] == 'GF Sing');
				if (isGFNote && gf == null) gf = {ID: GF, speed: speed, notes: [], visible: false};

				final gottaHit = note[1] > 3 ? !mustHit : mustHit;
				final notefield = gottaHit ? player : (isGFNote ? gf : opponent);

				notefield.notes.push({
					time: cast(note[0], Float),
					duration: cast(note[2], Float),
					type: note[3] is String ? cast note[3] : null,
					column: Std.int(note[1] % 4)
				});
			}

			var newNumerator:Float = 4;
			if (section.lengthInSteps is Int) newNumerator = section.lengthInSteps / 4;
			else if (section.sectionBeats is Int) newNumerator = section.sectionBeats;
			if (section.changeBPM || newNumerator != numerator)
				chart.timeChanges.push({time: sectionTime, bpm: bpm = section.bpm ?? bpm, numerator: numerator = newNumerator});

			sectionTime += 60000 * numerator / bpm;
		}

		SortUtil.sortByTime(player.notes);
		chart.playfields.push(player);
		if (AssetUtil.soundExists(chart.song.getVoicePath(bfchar))) player.voice = bfchar;

		SortUtil.sortByTime(opponent.notes);
		chart.playfields.push(opponent);
		if (AssetUtil.soundExists(chart.song.getVoicePath(dadchar))) opponent.voice = dadchar;

		if (gf != null) {
			SortUtil.sortByTime(gf.notes);
			chart.playfields.push(gf);
			if (AssetUtil.soundExists(chart.song.getVoicePath(gfchar))) gf.voice = gfchar;
		}

		if (data.stage is String) chart.stage = data.stage;
		if (data.offset is Float) chart.stage = data.offset;
		return true;
	}
}