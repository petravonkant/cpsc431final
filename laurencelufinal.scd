(
s.waitForBoot {
	/*
	Me: can we stop and get minecraft?
	Mom: we have minecraft at home
	The minecraft at home:

	At startup, you'll be presented with an 8-by-4 map of biomes.
	Click on the window to start, and use the arrow keys to move around.
	Certain colors are associated with certain biomes.
	Each biome is defined by a Markov model trained on a film soundtrack.
	Around the edges of a biome, you might hear echoes of songs from neighboring biomes.
	*/

	// BEGIN USER INPUT

	// how fast the user moves across the environment (higher is faster)
	// must be an integer greater than zero
	~stepSize = 1;

	// the number of biomes along either axis
	// must be an even number greater than zero
	~x_biomes = 8;
	~y_biomes = 4;

	// the side length of the biomes, in pixels
	// must be an integer greater than zero
	~side_len = 225;

	// the maximum volume to be heard at the center of each biome (100 is pretty loud)
	// must be non-negative
	~max_amp = 100;

	// the width of the border within which echoes might be heard
	// must be a number between zero and ~side_len / 2
	~border = ~side_len / 4;

	// END USER INPUT

	// an mdapiano synthdef that I modified to take an amplitude argument
	// I turned up the decay and release to make it sound less ... terse
	SynthDef(\mdapiano, {arg out=0, freq=440, gate=1, vel=25, amp=50, dec=1.2;
		var son = MdaPiano.ar(freq, gate, vel, decay: dec, release: dec, stereo: 0, sustain: 1, mul: amp);
		DetectSilence.ar(son, 0.01, doneAction:2);
		Out.ar(out, son * 0.1);
	}).add;

	// a bell synthdef, for playing the "echoes" of nearby biomes
	// from http://sccode.org/1-5ay#c835
	SynthDef(\bell, {
		|fs=1, t60=1, pitchy=1, amp=0.25, gate=1|
		var sig, exciter;
		//exciter = Impulse.ar(0);
		exciter = WhiteNoise.ar() * EnvGen.ar(Env.perc(0.001, 0.05), gate) * 0.25;
		sig = Klank.ar(
			`[
				[1, 2, 2.803, 3.871, 5.074, 7.81, 10.948, 14.421],   // freqs
				[1, 0.044, 0.891, 0.0891, 0.794, 0.1, 0.281, 0.079], // amplitudes
				[1, 0.205, 1, 0.196, 0.339, 0.047, 0.058, 0.047]*t60     // ring times
			],
			exciter,
			freqscale:fs*pitchy);
		sig = FreeVerb.ar(sig) * amp;
		DetectSilence.ar(sig, 0.001, 0.5, doneAction:2);
		Out.ar(0, sig!2);
	}).add;

	// a synthdef to play the ambient sound buffers
	SynthDef(\PlayBuf, {| out = 0, bufnum = 0 |
		Out.ar(out, PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), loop: 1.0))
	}).add;

	b = [\desert, \forest, \mountain, \tundra, \plains].collect{|val| Buffer.read(s,(val++".wav").resolveRelative) };

	s.sync;

	// Theme from Lawrence of Arabia
	~p_desert = [\c2, \g, \e, \f, \g, \b2, \c2, \g, \e, \f, \d, \b1, \c1, \g, \f, \b2f, \a, \g, \a, \b2];
	~d_desert = [1, 1.5, 0.5, 0.33, 0.33, 0.33, 1, 1.5, 0.5, 0.33, 0.33, 0.33, 1, 1, 1, 1, 1, 2, 0.5, 0.5];
	// each biome has a short musical fragment or "echo" which has a chance of playing when in the vicinity
	~p_desert_echo = [64, 65, 61, 58, 60];
	~d_desert_echo = [0.5, 0.33, 0.33, 0.33, 1];
	~dict_desert = Dictionary.newFrom(List[\b1, 58, \c1, 60, \d, 61, \e, 64, \f, 65, \g, 67, \a, 68, \b2f, 70, \b2, 71, \c2, 72]);

	// "The Path of the Wind" from My Neighbor Totoro
	~p_forest = [\c1, \e1, \f, \f, \g, \e1, \c1, \e1, \f, \f, \b, \g, \g, \b, \c2, \c2, \c2, \e2, \d2, \c2, \b, \a, \g, \f, \c1, \g];
	~d_forest = [0.5, 0.5, 1, 0.5, 0.5, 1, 0.5, 0.5, 1, 0.5, 0.5, 1, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1, 0.5, 0.5, 1];
	~p_forest_echo = [60, 63, 65, 65, 70, 67];
	~d_forest_echo = [0.5, 0.5, 1, 0.5, 0.5, 1];
	~dict_forest = Dictionary.newFrom(List[\c1, 60, \e1, 63, \f, 65, \g, 67, \a, 68, \b, 70, \c2, 72, \d2, 74, \e2, 75]);

	// "The Wings" from Brokeback Mountain
	~p_mountn = [\b, \c, \d, \f, \e, \c, \c, \b, \b, \c, \b, \a, \g, \g, \g];
	~d_mountn = [1, 1, 1, 3, 2.66, 0.33, 0.33, 2.66, 1, 1, 1, 3, 2.66, 0.33, 3];
	~p_mountn_echo = [71, 72, 74, 77];
	~d_mountn_echo = [1, 1, 1, 3];
	~dict_mountn = Dictionary.newFrom(List[\g, 67, \a, 69, \b, 71, \c, 72, \d, 74, \e, 76, \f, 77]);

	// Theme from The Eternal Sunshine of the Spotless Mind
	~p_tundra = [\g, \g, \g, \b, \g, \b, \g, \g, \b, \g, \d1, \e, \f, \g, \g, \g, \b, \g, \b, \g, \b, \c, \d2, \c, \g];
	~d_tundra = [2.33, 0.33, 0.33, 2.5, 0.5, 2.33, 0.33, 0.33, 2, 1, 1, 1, 1, 2.33, 0.33, 0.33, 2.5, 0.5, 1.5, 0.5, 1, 0.5, 1.5, 1, 3];
	~p_tundra_echo = [72, 74, 72, 67];
	~d_tundra_echo = [0.5, 1.5, 1, 3];
	~dict_tundra = Dictionary.newFrom(List[\d1, 62, \e, 63, \f, 65, \g, 67, \a, 68, \b, 70, \c, 72, \d2, 74]);

	// "One Summer's Day" from Spirited Away
	~p_plains = [\e, \f, \g, \g, \g, \g, \f, \e, \d, \d, \e, \c, \e, \f, \g, \g, \g, \g, \g, \f, \e, \d, \d, \e];
	~d_plains = [1, 1, 0.5, 1, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.25, 2, 0.25, 0.25, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2];
	~p_plains_echo = [72, 72, 74, 72, 71];
	~d_plains_echo = [0.5, 0.5, 0.5, 0.5, 1];
	~dict_plains = Dictionary.newFrom(List[\c, 60, \d, 62, \e, 64, \f, 65, \g, 67]);

	// ~pitches and ~duratns are lists of symbols/numbers that make up the training data
	~pitches = [\a, \b, \b1, \b2, \b2f, \c, \c1, \c2, \d, \d1, \d2, \e, \e1, \e2, \f, \g];
	~duratns = [0.25, 0.33, 0.5, 1, 1.5, 2, 2.33, 2.5, 2.66, 3];

	// ~make_markov makes an list of list representing the Markov model for the given data
	// elems is an list of elements (~pitches)
	// data is the training data (~p_desert)
	// result is an list of n empty list, where n is the number of elements in elems
	~make_markov = {arg elems, data, result;
		elems.do {arg item, i;
			if (data.includes(item)) {
				result.put(i, data.wrapAt(data.indicesOfEqual(item) + 1));
			}
		}
	};

	// make the Markov models, one for each aspect of each biome
	~m_p_desert = Array.fill(~pitches.size, {[]});
	~make_markov.value(~pitches, ~p_desert, ~m_p_desert);
	~m_d_desert= Array.fill(~duratns.size, {[]});
	~make_markov.value(~duratns, ~d_desert, ~m_d_desert);

	~m_p_forest = Array.fill(~pitches.size, {[]});
	~make_markov.value(~pitches, ~p_forest, ~m_p_forest);
	~m_d_forest= Array.fill(~duratns.size, {[]});
	~make_markov.value(~duratns, ~d_forest, ~m_d_forest);

	~m_p_mountn = Array.fill(~pitches.size, {[]});
	~make_markov.value(~pitches, ~p_mountn, ~m_p_mountn);
	~m_d_mountn= Array.fill(~duratns.size, {[]});
	~make_markov.value(~duratns, ~d_mountn, ~m_d_mountn);

	~m_p_tundra = Array.fill(~pitches.size, {[]});
	~make_markov.value(~pitches, ~p_tundra, ~m_p_tundra);
	~m_d_tundra= Array.fill(~duratns.size, {[]});
	~make_markov.value(~duratns, ~d_tundra, ~m_d_tundra);

	~m_p_plains = Array.fill(~pitches.size, {[]});
	~make_markov.value(~pitches, ~p_plains, ~m_p_plains);
	~m_d_plains= Array.fill(~duratns.size, {[]});
	~make_markov.value(~duratns, ~d_plains, ~m_d_plains);

	// each of ~colors_foo is a list of hex values representing possible colors for that biome
	// deserts are brown, forests are green, mountains are grey, tundras are blue and plains are golden
	~colors_desert = [
		"8B4513", "A0522D", "D2691E",
		"B8860B", "CD853F", "BC8F8F",
		"DAA520", "F4A460", "D2B48C"
	];
	~colors_forest = [
		"006400", "008000", "556B2F",
		"228B22", "2E8B57", "808000",
		"6B8E23", "9ACD32", "9ACD32"
	];
	~colors_mountn = [
		"2F4F4F", "696969", "708090",
		"808080", "778899", "A9A9A9",
		"C0C0C0", "D3D3D3", "DCDCDC"
	];
	~colors_tundra = [
		"4682B4", "1E90FF", "00BFFF",
		"6495ED", "87CEEB", "87CEFA",
		"B0C4DE", "ADD8E6", "B0E0E6"
	];
	~colors_plains = [
		"BDB76B", "FFD700", "F0E68C",
		"EEE8AA", "FFE4B5", "FFEFD5",
		"EED202", "FADA5E", "F8DE7E"
	];

	w = Window.new("", Rect(0, 10000, ~x_biomes * ~side_len, ~y_biomes * ~side_len)).front;

	~biomes = Array2D.new(~x_biomes, ~y_biomes);
	~biomes_list = [\d, \f, \m, \t, \p];

	// generate a grid of biomes, each of which is randomly selected from ~biomes_list
	for (0, ~x_biomes - 1, {arg i;
		for (0, ~y_biomes - 1, {arg j;
			~biomes[i,j] = ~biomes_list.choose;
			p = UserView(w, Rect(i * ~side_len, j * ~side_len, ~side_len, ~side_len));
			// pick a random color from the appropriate list of colors
			p.background = switch (~biomes[i,j],
				\d, {Color.fromHexString(~colors_desert.choose)},
				\f, {Color.fromHexString(~colors_forest.choose)},
				\m, {Color.fromHexString(~colors_mountn.choose)},
				\t, {Color.fromHexString(~colors_tundra.choose)},
				\p, {Color.fromHexString(~colors_plains.choose)}
			);
		});
	});

	// set the starting position to (0,0)
	~x_pos = ~xPrev = 0;
	~y_pos = ~yPrev = 0;

	// some helper values
	~x_center = ~x_biomes / 2 * ~side_len;
	~y_center = ~y_biomes / 2 * ~side_len;

    // each time v is refreshed, draw a black line from the previous position to the current one
	// do not clear the lines that have already been drawn
	// ignore the funny math
	v = UserView(w, w.view.bounds).clearOnRefresh_(false);
	v.drawFunc = {
		Pen.strokeColor = Color.black;
		Pen.width = 2;
		Pen.line((~yPrev + ~x_center)@( ~y_center - ~xPrev), (~y_pos + ~x_center)@(~y_center - ~x_pos));
		Pen.stroke;
	};

	v.keyDownAction = {arg view, char, modifiers, unicode, keycode;
		// with each key press, draw a new line representing the most recent move
		v.refresh;
		// update ~x_pos and ~y_pos to reflect keypresses
		switch (keycode,
			65361, {~yPrev = ~y_pos; ~y_pos = ~y_pos - ~stepSize}, // left
			65363, {~yPrev = ~y_pos; ~y_pos = ~y_pos + ~stepSize}, // right
			65362, {~xPrev = ~x_pos; ~x_pos = ~x_pos + ~stepSize}, // up
			65364, {~xPrev = ~x_pos; ~x_pos = ~x_pos - ~stepSize}, // down
		);
		// play the proper ambient effect for the biome
		// this isn't with the markov routine because the change is more immediate here
		switch (~biomes[~getIx_x.value, ~getIx_y.value].value,
			\d, {~play_effect.value(0)},
			\f, {~play_effect.value(1)},
			\m, {~play_effect.value(2)},
			\t, {~play_effect.value(3)},
			\p, {~play_effect.value(4)}
		);
	};

	// ~play_effect checks if the buffer is already playing
	// if not, it frees the buffer that is playing, sets ~active[ix] to true and every other field to false
	~active = [false, false, false, false, false];
	~curr = 0;
	~play_effect = {arg ix;
		if (~active[ix], {}, {
			if (~curr != 0, {~curr.free});
			~curr = Synth(\PlayBuf, [\bufnum, b[ix]]);
			~active[ix] = true;
			for (0, 4, {arg j;
				if (~active[j] && j != ix, {~active[j] = false});
			});
		});
	};

	// ~p_next_foo and ~d_next_foo are starting values for the markov models
	~p_next_desert = ~p_desert.choose; ~d_next_desert = ~d_desert.choose;
	~p_next_forest = ~p_forest.choose; ~d_next_forest = ~d_forest.choose;
	~p_next_mountn = ~p_mountn.choose; ~d_next_mountn = ~d_mountn.choose;
	~p_next_tundra = ~p_tundra.choose; ~d_next_tundra = ~d_tundra.choose;
	~p_next_plains = ~p_plains.choose; ~d_next_plains = ~d_plains.choose;

	// map x_pos and y_pos to indices into ~biomes
	~getIx_x = { floor((~y_pos + ~x_center) / ~side_len) };
	~getIx_y = { floor((~y_center - ~x_pos) / ~side_len) };

	// a routine to perform the proper markov model, one note at a time
	t = Routine {
		var max_displace = sqrt(((~side_len / 2) ** 2) * 2);
		inf.do {
			// scale the amplitude based on the distance from the center of the biome, as the crow flies
			var center = ~side_len / 2;
			var relative_x = (~y_pos + ~x_center) % ~side_len;
			var relative_y = (~y_center - ~x_pos) % ~side_len;
			var x_displace = abs(center - relative_x);
			var y_displace = abs(center - relative_y);
			var displace = sqrt((x_displace ** 2) + (y_displace ** 2));
			var amp = (1 - (displace / max_displace)) * ~max_amp;

			// query the next pitch and duration
			switch (~biomes[~getIx_x.value, ~getIx_y.value],
				\d, {
					Synth(\mdapiano, [\freq, ~dict_desert[~p_next_desert].midicps, \amp, amp]);
					~d_next_desert.wait;
					~p_next_desert = ~m_p_desert[~pitches.indexOf(~p_next_desert)].choose;
					~d_next_desert = ~m_d_desert[~duratns.indexOf(~d_next_desert)].choose;
				},
				\f, {
					Synth(\mdapiano, [\freq, ~dict_forest[~p_next_forest].midicps, \amp, amp]);
					~d_next_forest.wait;
					~p_next_forest = ~m_p_forest[~pitches.indexOf(~p_next_forest)].choose;
					~d_next_forest = ~m_d_forest[~duratns.indexOf(~d_next_forest)].choose;
				},
				\m, {
					Synth(\mdapiano, [\freq, ~dict_mountn[~p_next_mountn].midicps, \amp, amp]);
					~d_next_mountn.wait;
					~p_next_mountn = ~m_p_mountn[~pitches.indexOf(~p_next_mountn)].choose;
					~d_next_mountn = ~m_d_mountn[~duratns.indexOf(~d_next_mountn)].choose;
				},
				\t, {
					Synth(\mdapiano, [\freq, ~dict_tundra[~p_next_tundra].midicps, \amp, amp]);
					~d_next_tundra.wait;
					~p_next_tundra = ~m_p_tundra[~pitches.indexOf(~p_next_tundra)].choose;
					~d_next_tundra = ~m_d_tundra[~duratns.indexOf(~d_next_tundra)].choose;
				},
				\p, {
					Synth(\mdapiano, [\freq, ~dict_plains[~p_next_plains].midicps, \amp, amp]);
					~d_next_plains.wait;
					~p_next_plains = ~m_p_plains[~pitches.indexOf(~p_next_plains)].choose;
					~d_next_plains = ~m_d_plains[~duratns.indexOf(~d_next_plains)].choose;
				}
			);
		};
	};

	// some dictionaries to facilitate the playing of echoes
	~dict_echo_p = Dictionary.newFrom([
		\d, ~p_desert_echo,
		\f, ~p_forest_echo,
		\m, ~p_mountn_echo,
		\t, ~p_tundra_echo,
		\p, ~p_plains_echo
	]);
	~dict_echo_d = Dictionary.newFrom([
		\d, ~d_desert_echo,
		\f, ~d_forest_echo,
		\m, ~d_mountn_echo,
		\t, ~d_tundra_echo,
		\p, ~d_plains_echo
	]);

	// a routine to play echoes of nearby biomes
	u = Routine {
		var nums = Array.fill(10, {arg i; i});
		var period = 2;

		inf.do {
			var center = ~side_len / 2;
			var relative_x = (~y_pos + ~x_center) % ~side_len;
			var relative_y = (~y_center - ~x_pos) % ~side_len;
			// some math so that the sign of the displacement follows the Cartesian plane
			var x_displace = relative_x - center;
			var y_displace = center - relative_y;

			// a flag to prevent two echoes from playing at once
			var stopped = false;

			// every period, there's a 10% chance that an echo will play
			if (nums.choose == 0, {
				// check that your position is within the echo border
				// also check that the biome is not at the edge of the map
				// if the conditions are met, play the echo for the appropriate biome
				case
				{ (x_displace > ~border) && (~getIx_x.value != (~x_biomes - 1)) } {
					var biome = ~biomes[~getIx_x.value + 1, ~getIx_y.value];
					stopped = true;
					~playEcho.value(biome);
				}
				{ (x_displace < 0) && (abs(x_displace) > ~border) && (~getIx_x.value != 0) } {
					var biome = ~biomes[~getIx_x.value - 1, ~getIx_y.value];
					stopped = true;
					~playEcho.value(biome);
				};
				case
				{ stopped } {}
				{ (y_displace > ~border) && (~getIx_y.value != 0) } {
					var biome = ~biomes[~getIx_x.value, ~getIx_y.value - 1];
					~playEcho.value(biome);
				}
				{ (y_displace < 0) && (abs(y_displace) > ~border) && (~getIx_y.value != (~y_biomes - 1)) } {
					var biome = ~biomes[~getIx_x.value, ~getIx_y.value + 1];
					~playEcho.value(biome);
				};
			});

			period.wait;
		};
	};

	// ~playEcho takes a symbol representing a biome and plays the appropriate snippet with a Pbind
	~playEcho = {arg biome;
		var echo_p = ~dict_echo_p.at(biome);
		var echo_d = ~dict_echo_d.at(biome);

		Pbind(
			\instrument, \bell,
			\fs, Pseq(echo_p).midicps,
			\t60, 9,
			\pitchy, 1,
			\dur, Pseq(echo_d),
			\amp, 0.005
		).play;
	};

	t.reset.play;
	u.reset.play;

	w.onClose = ({t.stop; u.stop; ~curr.free});
};
)