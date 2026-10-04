/// @description  scr_resetSoundVolume
function scr_resetSoundVolume() {
	audio_emitter_gain(global.SEemitter, global.SEVolume);
	audio_emitter_gain(global.MUSemitter, global.MUSVolume);
	audio_channel_num((global.clutterDensity+0.1)*50);



}
