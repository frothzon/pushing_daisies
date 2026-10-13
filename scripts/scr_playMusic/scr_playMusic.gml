/// @description  scr_playMusic(sound, loop);
/// @param sound
/// @param  loop
function scr_playMusic(argument0, argument1) {

	var _soundID = argument0;
	var _loops = argument1;

	/// Stop WHATEVER music is playing, not just a second copy of this same
	/// track.  The check that used to be here was "is this one sound already
	/// playing", so the moment the game had more than one piece of music a
	/// level theme left on the emitter simply played ON TOP of the next one
	/// (roadmap 5.8).  global.music_playing is the instance this script
	/// handed out last; a stale one reports audio_is_playing() false (LL-002).
	if(variable_global_exists("music_playing")){
	    var _was = global.music_playing;
	    if(is_real(_was) && _was >= 0 && audio_is_playing(_was)){
	        audio_stop_sound(_was);
	    }
	}
	if (audio_is_playing(_soundID))
	{
	    audio_stop_sound(_soundID);
	}
	var _soundPlayed = audio_play_sound_on(global.MUSemitter, _soundID, _loops, 50);

	/// remember it, so the NEXT track can stop this one
	global.music_playing = _soundPlayed;

	print(sound_get_name(_soundID)," set to play");
	return _soundPlayed;



}
