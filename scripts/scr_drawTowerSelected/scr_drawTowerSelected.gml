/// @description  scr_drawTowerSelected();
///
/// The tower card (roadmap 4.4.3).
///
/// ONE fixed card, docked bottom-left, never under the mouse.
///
/// What it replaced: a 256x256 panel centred on the screen showing only
/// Range and Damage, with the Upgrade and Sell buttons floating in their own
/// grid over the same area, while the range circle drew at full strength
/// beside them.  Three elements competing for the middle of the screen - and
/// the two numbers a purchase decision actually needs, Fire-Rate and Targets,
/// were not displayed at all.
function scr_drawTowerSelected() {
	if(!scr_isValidInstance(tower_selection)) return;

	/// Read the selected tower only inside with() (LL-003). The geometry is
	/// copied from the controller before drawing the card in that instance.
	with(tower_selection) {
		tower_card_draw_selected(other.tower_card_x, other.tower_card_y,
		                         other.tower_card_w, other.tower_card_h,
		                         other.tower_max_level);
	}
}

/// Draw the selected tower's in-run card. Called with the tower instance in
/// scope so the current values, base stats, and stagger cannot come from a
/// different instance (LL-003).
function tower_card_draw_selected(_x, _y, _w, _h, _max_level) {
	if(!variable_instance_exists(id, "data") || !is_array(data)) return;
	if(array_length(data) <= TOWER.targets) return;

	var _data = data,
	    _name = variable_instance_exists(id, "name") && is_string(name) ? name : "Tower",
	    _level = _data[TOWER.level],
	    _dmg = _data[TOWER.damage],
	    _range = _data[TOWER.range],
	    _targets = _data[TOWER.targets],
	    _base = variable_instance_exists(id, "base_data") ? base_data : undefined,
	    _base_price = variable_instance_exists(id, "base_price") && is_real(base_price) ? base_price : 0,
	    _stagger = variable_instance_exists(id, "time_offset") && is_real(time_offset) ? max(0, time_offset) : 4.5,
	    _return_seconds = 0.25;

	if(variable_instance_exists(id, "anim_seconds") && is_array(anim_seconds)
	&& array_length(anim_seconds) > TOWER_ANIM.return
	&& is_real(anim_seconds[TOWER_ANIM.return])){
		_return_seconds = max(0, anim_seconds[TOWER_ANIM.return]);
	}

	var _fps = max(1, game_get_speed(gamespeed_fps)),
	    _current_eff_rate = _fps / max(1, tower_cycle_frames(_data[TOWER.fire_rate], _return_seconds) + _stagger),
	    _next_data = _data,
	    _price = tower_upgrade_price(_base_price, _level),
	    _can_upgrade = is_array(_base) && array_length(_base) > TOWER.targets
	                  && _level < _max_level && _price >= 0;

	if(_can_upgrade){
		var _candidate = tower_data_at_level(_base, _level + 1,
		                                     clover_damage_bonus(),
		                                     clover_firerate_bonus());
		if(is_array(_candidate) && array_length(_candidate) > TOWER.targets){
			_next_data = _candidate;
		} else {
			_can_upgrade = false;
		}
	}

	var _next_eff_rate = _fps / max(1, tower_cycle_frames(_next_data[TOWER.fire_rate], _return_seconds) + _stagger),
	    _current_dps = _dmg * _current_eff_rate,
	    _next_dps = _next_data[TOWER.damage] * _next_eff_rate;

	/// The card frame and heading.
	draw9slice(spr_towerUpgrade, _x, _y, _w, _h, c_white, 1);
	draw_set_font(fnt_size20);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_text_outline(_x+12, _y+8,
	    concat(_name, "   Level ", _level, "/", _max_level), c_lime, c_black, 2);

	var _ring = tower_level_outline(_level);
	if(_ring != -1){
		draw_set_colour(_ring);
		draw_rectangle(_x+_w-26, _y+10, _x+_w-14, _y+22, false);
		draw_set_colour(c_white);
	}

	draw_set_font(fnt_size16);
	draw_text_outline(_x+12, _y+40,
	    concat("DMG  ", round(_dmg), _can_upgrade ? concat(" -> ", round(_next_data[TOWER.damage])) : ""),
	    c_white, c_black, 1);
	draw_text_outline(_x+12, _y+60,
	    concat("RNG  ", round(_range), _can_upgrade ? concat(" -> ", round(_next_data[TOWER.range])) : ""),
	    c_white, c_black, 1);
	draw_text_outline(_x+176, _y+40,
	    concat("RATE ", string_format(_current_eff_rate,1,2), "/s",
	           _can_upgrade ? concat(" -> ", string_format(_next_eff_rate,1,2), "/s") : ""),
	    c_white, c_black, 1);
	draw_text_outline(_x+176, _y+60,
	    concat("TGT  ", _targets), c_white, c_black, 1);
	draw_text_outline(_x+176, _y+80,
	    concat("DPS  ", round(_current_dps),
	           _can_upgrade ? concat(" -> ", round(_next_dps)) : ""),
	    c_yellow, c_black, 1);

	if(_can_upgrade){
		draw_text_outline(_x+12, _y+100,
		    concat("NEXT RUNG  $", _price), c_lime, c_black, 1);
	} else if(_level >= _max_level){
		draw_text_outline(_x+12, _y+100, "MAX LEVEL", c_gray, c_black, 1);
	} else {
		draw_text_outline(_x+12, _y+100, "NEXT RUNG UNAVAILABLE", c_gray, c_black, 1);
	}

	var _trait = tower_stat_note(_name);
	if(_trait != ""){
		draw_text_outline(_x+12, _y+120, concat("TRAIT  ", _trait),
		                   c_white, c_black, 1);
	}

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}
