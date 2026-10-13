/// @description  scr_music_stop();  - silence, without touching the SE emitter
///
/// Roadmap 5.8.  Called when a stage ends.  Game over, quit and deploy all
/// already call audio_stop_all(), but the stage CLEAR fade goes straight to
/// rm_menu - so without this the region theme would follow the player onto the
/// world map and loop there forever.
///
/// The instance to stop is remembered by scr_playMusic in global.music_playing.
/// A stale id (an instance audio_stop_all() has already killed) is harmless:
/// audio_is_playing() reports false for it, and the guard means it is never
/// handed to the audio API in the first place (LL-002).
function scr_music_stop() {
	if(!variable_global_exists("music_playing")) return;

	var _was = global.music_playing;
	if(is_real(_was) && _was >= 0 && audio_is_playing(_was)){
		audio_stop_sound(_was);
	}
	global.music_playing = -1;
}
