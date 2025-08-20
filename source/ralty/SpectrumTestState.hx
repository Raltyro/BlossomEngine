package ralty;

import blossom.backend.util.AudioAnalyzer;
import blossom.backend.util.BitmapDataUtil;

class SpectrumTestState extends BLState {
	var voices:FlxSound;

	override function create() {
		super.create();

		//SoundUtil.playMusic(Paths.music('suspended'));
		FlxG.sound.playMusic(AssetUtil.getMusic(Paths.inst('aquatemp')));
		//voices = FlxG.sound.play(AssetUtil.getMusic(Paths.voices('the uprising')), 1.0, true, false);

		//FlxG.sound.music.onComplete = () -> voices.play(true, 0);

		var spectrum = new Spectrum([FlxG.sound.music]);
		spectrum.screenCenter();
		add(spectrum);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.justPressed.ACCEPT)
			FlxG.sound.play(Paths.sound('locked'));

		if (controls.justPressed.BACK) {
			trace(FlxG.sound.music.time);
			AssetUtil.gc();
			FlxG.autoPause = !FlxG.autoPause;
		}
	}
}

class Spectrum extends FlxSprite {
	public var sounds:Array<FlxSound>;
	public var bars(default, null):Int;
	var _bars3:Int; // value to r, g, b

	var _analyzers:Array<AudioAnalyzer> = [];
	var _cache:Array<Float>;
	var _frequencies:Array<Float>;
	var _samples:Array<Float> = [];
	var _fftN:Int = 2048;

	public function new(sounds:Array<FlxSound>, width = 1200, height = 320, bars = 400) {
		super();
		makeGraphic(_bars3 = Math.ceil((this.bars = bars) / 3), 1, FlxColor.BLACK, false);
		graphic.persist = true;
		graphic.destroyOnNoUse = false;

		setGraphicSize(width, height);
		updateHitbox();

		shader = new SpectrumShader(bars);

		this.sounds = sounds;
		for (sound in sounds) _analyzers.push(new AudioAnalyzer(sound));
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (sounds.length == 0) return;

		var analyzer:AudioAnalyzer;
		for (i => sound in sounds) {
			if ((analyzer = _analyzers[i]) != null) analyzer.sound = sound;
			else _analyzers[i] = analyzer = new AudioAnalyzer(sound);

			analyzer.getSamples(sound.time, _fftN, true, sound.getActualVolume(), _samples, i != 0);
		}

		_frequencies = AudioAnalyzer.getFrequenciesFromSamples(_samples, _fftN, false, _frequencies);
		_cache = AudioAnalyzer.getLevelsFromFrequencies(_frequencies, sounds[0].buffer.sampleRate, bars, _cache, FlxMath.getElapsedLerp(0.52, elapsed), -64, -10, 20, 20000);

		var k = 0, i = bars;
		while (i > 0) graphic.bitmap.setPixel(k++, 0, FlxColor.fromRGBFloat(_cache[i--], _cache[i--], _cache[i--]));
	}
}

class SpectrumShader extends blossom.graphic.shaders.BlossomShader {
	@:glFragmentSource("
#pragma header
uniform float bars;

float getRealAmp(float x) {
	vec4 p = texture2D(bitmap, vec2((x + 0.5) / openfl_TextureSize.x, 0.5));
	int idx = int(mod(x, 3.0));
	if (idx == 0) return p.r;
	else if (idx == 1) return p.g;
	else if (idx == 2) return p.b;
	return 0.0;
}

float getAmp(float x) {
	float i = floor(x);
	float a0 = getRealAmp(i);
	float a1 = getRealAmp(ceil(x));
	return a0 + (a1 - a0) * (x - i);
}

void main(void) {
	float amp = getAmp(openfl_TextureCoordv.x * openfl_TextureSize.x) * 0.992 + 0.008;

	float v = pow(amp * 0.5 - abs(openfl_TextureCoordv.y - 0.5), 0.05) * 2.0 * pow(abs(mod(openfl_TextureCoordv.x * bars, 2.0) - 1.0) - 0.5, 0.4);
	float b = pow((amp + 0.01) * 0.5 - abs(openfl_TextureCoordv.y - 0.5), 0.05) * 2.0;
	v = max(min(v, 1.0), 0.0);

	vec4 color = vec4(vec3(v), b - v);
	ofl_FragColor = apply_flixel_transform(color);
}
	")

	public function new(bars:Int) {
		super();
		this.bars.value = [bars];
		bitmap.filter = openfl.display3D.Context3DTextureFilter.NEAREST;
	}
}