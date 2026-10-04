/// @description  scr_playSound(sound, loop);
/// @param sound
/// @param  loop
function scr_playSound(argument0, argument1) {

	var _soundID = argument0;
	var _loops = argument1;

	/*
	if (audio_is_playing(_soundID))
	{
	    audio_stop_sound(_soundID);
	}
	*/

	var _soundPlayed = audio_play_sound_on(global.SEemitter, _soundID, _loops, 10);

	return _soundPlayed;



}
