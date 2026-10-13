/// @description  scr_wave_preview(_is_boss, _index);  - the "Up Next..." popup
/// @param _is_boss
/// @param _index
///
/// Show the creature the NEXT wave will send, as a PORTRAIT in the message
/// box, during the between-wave countdown (scr_level_wait).  The popup is
/// closed by scr_level_spawn() the moment the wave starts, so it never
/// overlaps play, and a boss gets its own label so the warning reads as one.
function scr_wave_preview(_is_boss, _index) {
	var _bank = _is_boss ? spawn_boss : spawn_mon;
	if(!is_real(_index) || _index < 0 || _index >= array_length(_bank)) return;

	var _mon   = _bank[_index],
	    _label = _is_boss ? "Up Next...  BOSS!" : "Up Next...",
	    _name  = _mon[MON.name];

	var _box = show_portrait_box(_mon[MON.portrait], c_white,
	                             _label + "#" + _name);

	/// sit BELOW centre: the "Wave N" banner (scr_showWave) is drawn at
	/// the screen centre, so a centred box would have the banner land
	/// on top of it
	var _dy = display_get_gui_height()*0.22;
	_box.m_pos[1] += _dy;
	_box.m_pos[3] += _dy;

	scr_meta_log("LEVEL", "up next: ", _name, " (boss=", _is_boss,
	             ", spawner=", _index, ")");
	return(_box);
}
