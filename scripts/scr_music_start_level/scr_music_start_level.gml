/// @description  scr_music_start_level();  - the region's theme, looped
///
/// Roadmap 5.8.  Called once, when the level flow enters START, so the theme is
/// up under the deploy countdown instead of arriving with wave 1.
///
/// THE CHORUS LOOP.  GameMaker's Audio Loop Points are applied on the AUDIO
/// THREAD, which is the only accurate way to loop a SECTION of a track: the
/// manual is explicit that doing it by hand with
/// audio_sound_set_track_position "will never be accurate", because audio runs
/// at 44100 or 48000 samples a second and the game only gets 60 chances to look
/// at it.  The points are set on the sound ASSET, so every later play of that
/// track inherits them and setting them again is idempotent.
///
/// loop_in == 0 means "loop the whole track": loop start and loop end are then
/// BOTH 0.0, which is the manual's documented default (0.0 is only legal as a
/// PAIR of zeros - a loop end that is not after the loop start is not allowed).
function scr_music_start_level() {
	var _row   = stage_current(),
	    _music = music_for_region(_row.region);

	if(is_undefined(_music)){
		scr_meta_log("MUSIC", "region ", _row.region, " is not in music_data");
		return -1;
	}

	var _sound = _music.sound;

	/// The two values that mean "there is nothing to play" are tested BY VALUE,
	/// before anything touches the audio API.  audio_exists() cannot be the test:
	/// it throws on an index it has never seen (the manual says so), and a guard
	/// that can throw is not a guard (LL-002).
	///
	///   -1          music_data's "not generated yet" sentinel (music_row())
	///   undefined   the table has no row for this region, or the row was built
	///               without a sound
	///
	/// NOT is_real().  is_real() asks "is this a plain number" and an asset
	/// reference is not one (typeof() documents "ref" for handle references,
	/// and is_real() is itself documented as false for int64s such as enums).
	/// So is_real(mus_world1) is FALSE for a perfectly good sound, and
	/// this line refused EVERY region theme in the game - while the menu theme,
	/// which reaches audio_play_sound_on() without passing through here, played
	/// on.  That is the silence rayu heard (LL-034).  A type test here can only
	/// ever produce a false negative: what a track needs is its own sentinel
	/// checked, and the audio API is the only thing that can judge an asset.
	if(is_undefined(_sound) || _sound == -1){
		scr_meta_log("MUSIC", "region ", _row.region, " \"", _music.title, "\" ",
		             is_undefined(_sound) ? "has no sound (undefined)"
		                                  : "has no track yet (-1)",
		             " - playing nothing");
		return -1;
	}

	if(!audio_sound_is_playable(_sound)){
		scr_meta_log("MUSIC", "region ", _row.region, " \"", _music.title,
		             "\" is not playable - playing nothing");
		return -1;
	}

	/// the loop SECTION, measured (see music_data): the intro plays once, the
	/// body repeats loop_in -> loop_out, and the outro fade is never heard
	/// again.  The helper returns what was ACTUALLY applied, so the log below
	/// cannot claim a section that was not set.
	var _loop    = scr_music_apply_loop(_music),
	    _in      = _loop[0],
	    _out     = _loop[1],
	    _chorus  = _loop[2];

	var _play = scr_playMusic(_sound, true);

	scr_meta_log("MUSIC", "region ", _row.region, " \"", _music.title, "\" ",
	             sound_get_name(_sound), " (", typeof(_sound), ") loop ",
	             _chorus ? _in : 0, " -> ", _out, "s (",
	             _chorus ? "section" : "whole track", ")");

	return _play;
}
