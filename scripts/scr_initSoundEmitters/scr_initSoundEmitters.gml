/// @description  scr_initSoundEmitters();
function scr_initSoundEmitters() {
	global.SEemitter = audio_emitter_create();
	global.SEVolume = 1.0;
	audio_emitter_gain(global.SEemitter, global.SEVolume);

	global.MUSemitter = audio_emitter_create();
	global.MUSVolume = 1.0;
	audio_emitter_gain(global.MUSemitter, global.MUSVolume);



}
