
// - Samples -

~clapBuffer = Buffer.read(s, "C:/Users/Tom/Desktop/samples/clap.wav");
~kickBuffer = Buffer.read(s, "C:/Users/Tom/Desktop/samples/kick.wav");
~bassDrumBuffer = Buffer.read(s, "C:/Users/Tom/Desktop/samples/bass_drum.wav");
~hiHatBuffer = Buffer.read(s, "C:/Users/Tom/Desktop/samples/hi_hat.ogg");
~clapSnareBuffer = Buffer.read(s, "C:/Users/Tom/Desktop/samples/clap_snare.wav");


// - Synths -

SynthDef(\sampler, {
	arg out = 0, bufnum, amp = 1;
	Out.ar(out,
		PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), \t_tr.kr(1,0)) * amp;
	)
}).add;

SynthDef(\MIDIbass, {
	arg out = 0, note = 35, amp = 1, cutoff = 350, decay = 1;
	var env, sig;
	env = EnvGen.kr(Env.new([0,1,0],[0.001,2],[3,-50]),doneAction: 2);
	sig = RLPF.ar(Saw.ar(note.midicps, amp), cutoff)*env;
	sig = CombC.ar(sig, 1, 0.125, decay);
	Out.ar(out, sig);
}).add;

p = Pbind(*[
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

p.stop;

//OSC Reciever Funcs


OSCdef(\keyboard, {
	arg msg;
	if(msg[2] == 1.0){
		Synth(\MIDIbass, [\note, msg[1]]);
	};
	//Synth(\bass, [\bufnum, ~clapBuffer.bufnum]);
}, 'keyboard');

OSCdef(\button1, {
	Synth(\sampler, [\bufnum, ~clapBuffer.bufnum]);
}, 'Clap');

OSCdef(\button2, {
	Synth(\sampler, [\bufnum, ~kickBuffer.bufnum]);
}, 'Kick');


OSCdef(\button3, {
	Synth(\sampler, [\bufnum, ~bassDrumBuffer.bufnum]);
}, 'Bass');


OSCdef(\button4, {
	Synth(\sampler, [\bufnum, ~hiHatBuffer.bufnum]);
}, 'HiHat');


OSCdef(\button5, {
	Synth(\sampler, [\bufnum, ~clapSnareBuffer.bufnum]);
}, 'ClapSnare');


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
