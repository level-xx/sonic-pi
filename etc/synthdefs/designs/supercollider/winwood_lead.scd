// Adapted for Sonic Pi from
//   https://raw.githubusercontent.com/supercollider/supercollider/develop/examples/demonstrations/stealthissound.scd
// Published there under GPL v3, so re-published under the same terms, see:
//   https://www.gnu.org/licenses/gpl-3.0.en.html
// Date of modification: 10.01.2021

(
SynthDef('sonic-pi-winwood_lead', {|
	note = 69, note_slide = 0, note_slide_shape = 1, note_slide_curve = 0,
	amp = 1, amp_slide = 0, amp_slide_shape = 1, amp_slide_curve = 0,
	pan = 0, pan_slide = 0, pan_slide_shape = 1, pan_slide_curve = 0,
	attack = 0.01, decay = 0, sustain = 0.9, release = 0.05,
	attack_level = 1, decay_level = 0.5, sustain_level = 0.5,
	cutoff = 119, cutoff_slide = 0, cutoff_slide_shape = 1, cutoff_slide_curve = 0,
	lfo_width = 0.01, lfo_width_slide = 0, lfo_width_slide_shape = 1, lfo_width_slide_curve = 0,
	lfo_rate = 8, lfo_rate_slide = 0, lfo_rate_slide_shape = 1, lfo_rate_slide_curve = 0,
	res = 0.8, res_slide = 0, res_slide_shape = 1, res_slide_curve = 0,
	seed = 0, rand_buf = 0,
	out_bus = 0|

	var snd, pulse, env, lfo;
	var rand_val;

	note = note.midicps;
	note = note.varlag(note_slide, note_slide_curve, note_slide_shape);
	decay_level = Select.kr(decay_level < 0, [decay_level, sustain_level]);
	amp = amp.varlag(amp_slide, amp_slide_curve, amp_slide_shape);
	pan = pan.varlag(pan_slide, pan_slide_curve, pan_slide_shape);

	cutoff = cutoff.midicps;
	cutoff = cutoff.varlag(cutoff_slide, cutoff_slide_curve, cutoff_slide_shape);

	lfo_width = lfo_width.varlag(lfo_width_slide, lfo_width_slide_curve, lfo_width_slide_shape);
	lfo_rate = lfo_rate.varlag(lfo_rate_slide, lfo_rate_slide_curve, lfo_rate_slide_shape);

	res = res.varlag(res_slide, res_slide_curve, res_slide_shape);

	rand_val = BufRd.kr(1, rand_buf, seed, 1);

	lfo = LFTri.kr(lfo_rate,(rand_val*2.0)!2);

	pulse = Mix(Pulse.ar(note*[1,1.001]*(1.0+(lfo_width*lfo)),[0.2,0.19]))*0.5;

	snd =  RLPF.ar(pulse,cutoff,res);

	snd = BLowShelf.ar(snd,351,1.0,-9);

	env = Env.new(
		[0, attack_level, decay_level, sustain_level, 0],
		[attack,decay,sustain,release],
		\lin
	);

	snd = Pan2.ar(Mix(snd) * EnvGen.kr(env, doneAction: 2), pan);

	Out.ar(out_bus, snd * amp);
}).writeDefFile("/Users/sam/Development/RPi/sonic-pi/etc/synthdefs/compiled/");
)