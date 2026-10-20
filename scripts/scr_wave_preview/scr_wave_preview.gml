/// @description  scr_wave_preview(_pick);  - the "Up Next..." popup
/// @param _pick  a decision from scr_level_pick_store
///
/// Show the creature the NEXT wave will send, as a PORTRAIT in the message
/// box, during the between-wave countdown (scr_level_wait).  The popup is
/// closed by scr_level_spawn() the moment the wave starts, so it never
/// overlaps play, and a boss gets its own label so the warning reads as one.
///
/// IT TAKES THE DECISION, NOT AN `is_boss, index` PAIR (LL-058).  The popup
/// and the wave are two readers of ONE struct, so there is no second chance
/// to get the pair wrong - and the same index means a different creature in
/// the other bank, so a disagreement about `is_boss` used to swap the monster
/// silently.  The WAVE NUMBER goes in the text as well, so a player can
/// compare the popup with the "Wave N" banner instead of with a picture.
function scr_wave_preview(_pick) {
	if(!is_struct(_pick)) return;
	if(!is_real(_pick.index) || _pick.index < 0) return;

	var _bank = _pick.is_boss ? spawn_boss : spawn_mon;
	if(!is_array(_bank) || _pick.index >= array_length(_bank)) return;

	var _mon   = _bank[_pick.index],
	    _name  = is_array(_mon) ? _mon[MON.name] : "?",
	    _label = _pick.is_boss ? "Up Next...  BOSS!" : "Up Next...",
	    _portrait = is_array(_mon) ? _mon[MON.portrait] : -1,
	    _portrait_name = "none";
	if(sprite_exists(_portrait)) _portrait_name = sprite_get_name(_portrait);

	var _box = show_portrait_box(_portrait, c_white,
	                             _label + "  wave " + string(_pick.wave)
	                             + "#" + _name);

	/// sit BELOW centre from a BASE, never with `+=` (LL-058): the box can be
	/// reused, and a cumulative shift would walk it down the screen one wave
	/// at a time.  m_pos[5] is the box height, set in obj_textbox/Create_0.
	var _dy = display_get_gui_height()*0.22;
	_box.m_pos[1] = display_get_gui_height()*0.5 - _box.m_pos[5]*0.5 + _dy;
	_box.m_pos[3] = _box.m_pos[1] + _box.m_pos[5];

	scr_meta_log("LEVEL", "up next: wave ", _pick.wave, " = ", _name,
	             " (boss=", _pick.is_boss, ", spawner=", _pick.index,
	             ", portrait=", _portrait_name, ")");
	return(_box);
}
