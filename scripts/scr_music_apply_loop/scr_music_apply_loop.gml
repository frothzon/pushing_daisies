/// @description  scr_music_apply_loop(music_row);  - set a row's loop section
///
/// Roadmap 5.8.  ONE place that turns a music_data row's loop_in / loop_out
/// into audio_sound_loop_start() / audio_sound_loop_end(), so the region theme
/// (scr_music_start_level) and the menu theme (scr_music_start_menu) cannot
/// drift apart - and they already had: the region path set loop points, the
/// menu path set none, so the menu replayed the outro fade and a stage did not.
///
/// THE POINTS GO ON THE ASSET, NOT THE PLAYING INSTANCE.  GameMaker applies
/// them on the audio thread, which is the only accurate way to loop a section
/// (the manual is explicit that doing it with audio_sound_set_track_position
/// "will never be accurate"); they are inherited by every later play of that
/// track, and setting them twice is idempotent.
///
/// Returns [loop_in, loop_out, is_section] - what was ACTUALLY applied, in
/// seconds - so the caller can log the truth rather than the request.
///
/// Never throws (LL-002).  No type test on the asset: is_real() is FALSE for a
/// sound reference and that guard once silenced every stage theme (LL-034), so
/// the two documented "no track" values are tested by value instead.  A stream
/// that cannot report its length yet is left alone rather than handed a loop
/// end of -1.
function scr_music_apply_loop(_music) {
	if(!is_struct(_music)) return [0, 0, false];
	if(!variable_struct_exists(_music, "sound")) return [0, 0, false];

	var _sound = _music.sound;
	if(is_undefined(_sound) || _sound == -1) return [0, 0, false];

	var _len = audio_sound_length(_sound);
	if(_len <= 0) return [0, 0, false];

	/// -1 is the table's "no point at this end" sentinel; 0 is a real START
	/// (mus_world5 has no intro), so the two cannot share a value.
	///
	/// The key is tested BEFORE the read, in its own if, rather than as
	/// `exists() && _music.key`: GML gives no guarantee that the right-hand
	/// side of a logical operator is skipped, and a guard that can throw is
	/// not a guard (LL-002).
	var _in  = -1,
	    _out = -1;

	if(variable_struct_exists(_music, "loop_in")){
		if(is_real(_music.loop_in)) _in = _music.loop_in;
	}
	if(variable_struct_exists(_music, "loop_out")){
		if(is_real(_music.loop_out)) _out = _music.loop_out;
	}

	/// A row that names NEITHER end asks for no section at all: `loop = true`
	/// already repeats the whole file, and a 0 -> length pair would only
	/// restate it - one less thing to get wrong (LL-034).
	if(_in < 0 && _out < 0) return [0, _len, false];

	if(_in  < 0) _in  = 0;
	if(_out < 0) _out = _len;
	if(_out > _len) _out = _len;
	_in = clamp(_in, 0, _len);

	/// A section needs an END AFTER its start.  With the two equal there is no
	/// section, and setting the 0.0/0.0 pair would leave playback depending on
	/// the runtime reading "loop end 0" as "end of file" - so nothing is set
	/// and `loop = true` repeats the whole track (LL-034).
	var _section = (_out > _in);
	if(_section){
		audio_sound_loop_start(_sound, _in);
		audio_sound_loop_end(_sound, _out);
	}

	return [_in, _out, _section];
}
