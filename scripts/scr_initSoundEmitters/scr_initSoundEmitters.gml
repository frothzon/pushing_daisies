/// @description  scr_initSoundEmitters();
function scr_initSoundEmitters() {
	global.SEemitter = audio_emitter_create();
	global.SEVolume = 1.0;
	audio_emitter_gain(global.SEemitter, global.SEVolume);

	global.MUSemitter = audio_emitter_create();
	global.MUSVolume = 1.0;
	audio_emitter_gain(global.MUSemitter, global.MUSVolume);

	/// the music instance that is playing right now, so scr_playMusic() can
	/// stop the PREVIOUS track before starting the next one.  -1 is the
	/// "nothing playing" sentinel (the convention a sprite uses for none),
	/// never a real audio index.
	global.music_playing = -1;



}
