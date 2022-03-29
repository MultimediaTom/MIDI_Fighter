// - #1 -
// - Variables -

s.quit;
s.options.memSize = 65536;  // e.g., could be different for you
s.boot;

b = NetAddr.new("127.0.0.1", 8080);
~mode = false;
~vis = [
  [ 0, 0 ],
  [ 0.06, 1 ],
  [ 0.35, 0.75 ],
  [ 0.85, 0.75 ],
  [ 1, 0 ]
];
~atk = 0.2;
~dec = 0.2;
~sus = 0.75;
~rel = 0.3;

~bpms = [
	100,
	100,
	100,
	100,
];

~metros = [nil, nil, nil, nil];

// - Samples -
~bufs = [
	Buffer.read(s, "samples/clap.wav"),
	Buffer.read(s, "samples/kick.wav"),
	Buffer.read(s, "samples/bass_drum.wav"),
	Buffer.read(s, "samples/hi_hat.ogg"),
	Buffer.read(s, "samples/clap_snare.wav"),
	Buffer.read(s, "samples/snap.wav"),
	Buffer.read(s, "samples/chirp.wav"),
	Buffer.read(s, "samples/gong.wav"),
	Buffer.read(s, "samples/click.wav"),
	Buffer.read(s, "samples/space_snare.wav"),
	Buffer.read(s, "samples/metro_up.wav"),
];

// - #2 -
// - Synths -

SynthDef(\sampler, {
	arg out = 0, bufnum, amp = 1;
	Out.ar(out,
		PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), \t_tr.kr(1,0)) * amp;
	)
}).add;

SynthDef(\METRObass, {
	arg out = 0, note = 35, amp = 1, cutoff = 350, decay = 1;
	var env, sig;
	env = EnvGen.kr(Env.new([0,1,0],[0.001,2],[3,-50]));
	sig = RLPF.ar(LFSaw.ar(note.midicps, amp), cutoff)*env;
	sig = CombC.ar(sig, 1, 0.125, decay);
	Out.ar(out, sig);
}).add;

SynthDef(\MIDIbass, {
	arg out = 0, note = 50, amp = 1, cutoff = 350, dec = 0.2, atk = 0.2, sus = 0.75, rel = 0.3, gate = 0;
	var env, sig;
	env = EnvGen.kr(Env.adsr(atk, dec, sus, rel, curve: [3, -50]), gate);
	sig = RLPF.ar(LFCub.ar(note.midicps, amp), cutoff)*env;
	sig = CombC.ar(sig, 1, 0.125, dec);
	Out.ar(out, sig);
}).add;

SynthDef.new(\MIDIpiano, {
	arg out = 0, note = 50, amp = 1, dec = 0.2, atk = 0.2, sus = 0.75, rel = 0.3, gate = 0;
	var env, sig;
	env = EnvGen.kr(Env.adsr(atk, dec, sus, rel), gate);
	sig = SinOsc.ar(note.midicps, amp)*env;
	sig = CombC.ar(sig, 1, 0.125, dec);
	Out.ar(out, sig);
}).add;

//OSC Reciever Funcs

OSCdef(\button1, {Synth(\sampler, [\bufnum, ~bufs[0].bufnum])}, 'Clap');
OSCdef(\button2, {Synth(\sampler, [\bufnum, ~bufs[1].bufnum])}, 'Kick');
OSCdef(\button3, {Synth(\sampler, [\bufnum, ~bufs[2].bufnum])}, 'Bass');
OSCdef(\button4, {Synth(\sampler, [\bufnum, ~bufs[3].bufnum])}, 'HiHat');
OSCdef(\button5, {Synth(\sampler, [\bufnum, ~bufs[4].bufnum])}, 'Clap Snare');
OSCdef(\button6, {Synth(\sampler, [\bufnum, ~bufs[5].bufnum])}, 'Snap');
OSCdef(\button7, {Synth(\sampler, [\bufnum, ~bufs[6].bufnum])}, 'Chirp');
OSCdef(\button8, {Synth(\sampler, [\bufnum, ~bufs[7].bufnum])}, 'Gong');
OSCdef(\button9, {Synth(\sampler, [\bufnum, ~bufs[8].bufnum])}, 'Click');
OSCdef(\button10, {Synth(\sampler, [\bufnum, ~bufs[9].bufnum])}, 'Space Snare');

OSCdef(\keyboard, {
	arg msg;
	if(~mode == false){
		if(msg[2] == 1.0) {
			p.set(\note, msg[1]);
			p.set(\gate, 1);
			b.sendMsg("/gate_led", 1);
		} {
			p.set(\gate, 0);
			b.sendMsg("/gate_led", 0);
		}
	} //else
	{
		if(msg[2] == 1.0) {
			q.set(\note, msg[1] - 16);
			q.set(\gate, 1);
			b.sendMsg("/gate_led", 1);
		} {
			q.set(\gate, 0);
			b.sendMsg("/gate_led", 0);
		}
	}
}, 'keyboard');

OSCdef(\A, {
	arg msg;
	~atk = msg[1];
	p.set(\atk, msg[1]);
	q.set(\atk, msg[1]);
	~vis[1][0] = ~atk * 0.3;
	b.sendMsg("/ADSRvis", ("" + ~vis));
	//post('atk set to: ' + msg[1].postln);
}, 'knob_1');

OSCdef(\D, {
	arg msg;
	p.set(\dec, msg[1]);
	q.set(\dec, msg[1]);
	~dec = msg[1];
	~vis[2][0] = 0.3 + (~dec * 0.2);
	b.sendMsg("/ADSRvis", ("" + ~vis));
	//post('dec set to: ' + msg[1].postln);
}, 'knob_2');

OSCdef(\S, {
	arg msg;
	p.set(\sus, msg[1]);
	q.set(\sus, msg[1]);
	~sus = msg[1];
	~vis[2][1] = ~sus;
	~vis[3][1] = ~sus;
	b.sendMsg("/ADSRvis", ("" + ~vis));
	//post('sus set to: ' + msg[1].postln);
}, 'knob_3');

OSCdef(\R, {
	arg msg;
	p.set(\rel, msg[1]);
	q.set(\rel, msg[1]);
	~rel = msg[1];
	~vis[3][0] = 0.8 + (~rel * 0.2);
	b.sendMsg("/ADSRvis", ("" + ~vis));
	//post('rel set to: ' + msg[1].postln);
}, 'knob_4');

OSCdef(\Vol, {
	arg msg;
	p.set(\amp, msg[1]);
	post('Volume set to: ' + msg[1].postln);
	p.get(\amp).postln;
}, 'knob_5');

OSCdef(\Mode, {
	arg msg;
	if(msg[1] == 1.0){~mode = false;}{~mode = true;};
	//~mode.postln;
}, 'switch_1');

OSCdef(\bpm1, {arg msg; ~bpms[0] = msg[1]}, 'dropdown_1');
OSCdef(\bpm2, {arg msg; ~bpms[1] = msg[1]}, 'dropdown_2');
OSCdef(\bpm3, {arg msg; ~bpms[2] = msg[1]}, 'dropdown_3');
OSCdef(\bpm4, {arg msg; ~bpms[3] = msg[1]}, 'dropdown_4');

OSCdef(\metro1, {
	arg msg;
	if(msg[1] == 1.0) {
		~metros[0] = Pseq([Pfunc({ Synth(\sampler, [\bufnum, ~bufs[10].bufnum]); 60/~bpms[0]})], inf).play;
		b.sendMsg("/metro_led_1", 1);
	} {
		~metros[0].stop;
		b.sendMsg("/metro_led_1", 0);
		~metros[0].free;
	}
}, 'metro_1');

OSCdef(\metro2, {
	arg msg;
	if(msg[1] == 1.0) {
		~metros[1] = Pseq([Pfunc({ Synth(\sampler, [\bufnum, ~bufs[0].bufnum]); 60/~bpms[1] })], inf).play;
		b.sendMsg("/metro_led_2", 1);
	} {
		~metros[1].stop;
		b.sendMsg("/metro_led_2", 0);
		~metros[1].free;
	}
}, 'metro_2');

OSCdef(\metro3, {
	arg msg;
	if(msg[1] == 1.0) {
		~metros[1] = Pseq([Pfunc({ Synth(\sampler, [\bufnum, ~bufs[3].bufnum]); 60/~bpms[1] })], inf).play;
		b.sendMsg("/metro_led_2", 1);
	} {
		~metros[1].stop;
		b.sendMsg("/metro_led_2", 0);
		~metros[1].free;
	}
}, 'metro_3');

OSCdef(\metro4, {
	arg msg;
	if(msg[1] == 1.0) {
		~metros[3] = Pseq([Pfunc({ Synth(\METRObass); 60/~bpms[3] })], inf).play;
		b.sendMsg("/metro_led_4", 1);
	} {
		~metros[3].stop;
		b.sendMsg("/metro_led_4", 0);
		~metros[3].free;
	}
}, 'metro_4');


// - #3 -

o = Synth(\METRObass);
p = Synth(\MIDIpiano);
q = Synth(\MIDIbass);
b.sendMsg("/power_led", 1);








//Sequencer

s = Pbind(*[
	\instrument: \MIDIbass,
	\note: Pseq([
		    Pseq([35,47,35,45,47],6),
		    Pseq([38,50,38,38,49,37,49,37,49,30],1),
		    Pseq([35,47,35,45,47]-5,3)
	       ], 4),
	\dur: Pseq([0.375,0.25,0.125,0.125,0.125],inf),
	\amp: 1.4,
	\cutoff: Pseq([450,300,550,450,300],inf),
	\decay: Pseq([2,1,0.75,0.75,0.75],inf),
]).play;

s.stop;



//Enable OSC Trace without Connectivity Checks
OSCFunc.trace(true, true);
//Disable OSC Trace
OSCFunc.trace(false, false);

o.free;

//Sample-Sources
//https://freesound.org/people/DWSD/sounds/183102/
//https://freesound.org/people/DWSD/sounds/183097/
//https://freesound.org/people/TheFlakesMaster/sounds/399897/
//https://freesound.org/people/eryps/sounds/355065/
//https://freesound.org/people/adammusic18/sounds/208871/
//https://freesound.org/people/LudwigMueller/sounds/548519/
//https://freesound.org/people/Druminfected/sounds/250551/
//https://freesound.org/people/Horn/sounds/9744/
//https://freesound.org/people/Snapper4298/sounds/177494/
//https://freesound.org/people/FreqMan/sounds/24550/
//https://freesound.org/people/GowlerMusic/sounds/266566/
//https://freesound.org/people/altemark/sounds/207919/

