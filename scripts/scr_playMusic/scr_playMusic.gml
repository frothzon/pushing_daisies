/// @description  scr_playMusic(sound, loop);
/// @param sound
/// @param  loop
function scr_playMusic(argument0, argument1) {

	var _soundID = argument0;
	var _loops = argument1;

	if (audio_is_playing(_soundID))
	{
	    audio_stop_sound(_soundID);
	}
	var _soundPlayed = audio_play_sound_on(global.MUSemitter, _soundID, _loops, 50);

	print(sound_get_name(_soundID)," set to play");
	return _soundPlayed;



}
