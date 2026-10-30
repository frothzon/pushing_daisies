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
	    _spec_key = variable_instance_exists(id,"specialization") && is_string(specialization) ? specialization : "",
	    _level = _data[TOWER.level],
	    _dmg = _data[TOWER.damage],
	    _range = _data[TOWER.range],
	    _targets = _data[TOWER.targets],
	    _base = variable_instance_exists(id, "base_data") ? base_data : undefined,
	    _base_price = variable_instance_exists(id, "base_price") && is_real(base_price) ? base_price : 0,
	    _stagger = variable_instance_exists(id, "time_offset") && is_real(time_offset) ? max(0, time_offset) : 4.5,
	    _return_seconds = 0.25,
	    _crit_base = 0.05,
	    _crit_multiplier_base = 1.50;

	if(array_length(_data) > TOWER.crit_chance){
		if(is_real(_data[TOWER.crit_chance])) _crit_base = _data[TOWER.crit_chance];
	}
	if(array_length(_data) > TOWER.crit_damage){
		if(is_real(_data[TOWER.crit_damage])) _crit_multiplier_base = _data[TOWER.crit_damage];
	}
	var _spec_mods = tower_spec_modifiers(_name,_spec_key,_level),
	    _crit_chance = clamp(_crit_base + tower_trait_get(_name, "crit", 0) + _spec_mods.crit, 0, 1),
	    _crit_multiplier = max(1, _crit_multiplier_base + tower_trait_get(_name, "crit_damage", 0) + _spec_mods.crit_damage),
	    _crit_factor = 1 + _crit_chance * (_crit_multiplier - 1);

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
			_next_data = tower_spec_apply_data(_name,_spec_key,_level+1,_candidate);
		} else {
			_can_upgrade = false;
		}
	}

	var _next_crit_base = _crit_base,
	    _next_crit_multiplier_base = _crit_multiplier_base;
	if(array_length(_next_data) > TOWER.crit_chance){
		if(is_real(_next_data[TOWER.crit_chance])) _next_crit_base = _next_data[TOWER.crit_chance];
	}
	if(array_length(_next_data) > TOWER.crit_damage){
		if(is_real(_next_data[TOWER.crit_damage])) _next_crit_multiplier_base = _next_data[TOWER.crit_damage];
	}
	var _next_spec_mods = tower_spec_modifiers(_name,_spec_key,_can_upgrade ? _level+1 : _level),
	    _next_eff_rate = _fps / max(1, tower_cycle_frames(_next_data[TOWER.fire_rate], _return_seconds) + _stagger),
	    _next_crit_chance = clamp(_next_crit_base + tower_trait_get(_name, "crit", 0) + _next_spec_mods.crit, 0, 1),
	    _next_crit_multiplier = max(1, _next_crit_multiplier_base + tower_trait_get(_name, "crit_damage", 0) + _next_spec_mods.crit_damage),
	    _current_dps = _dmg * _current_eff_rate * _crit_factor,
	    _next_dps = _next_data[TOWER.damage] * _next_eff_rate
	                * (1 + _next_crit_chance * (_next_crit_multiplier - 1));

	/// The card frame and heading.
	draw9slice(spr_towerUpgrade, _x, _y, _w, _h, c_white, 1);
	draw_set_font(fnt_size20);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_text_outline(_x+12, _y+8,
	    ui_text_format("tower_card_level",{name:_name,level:string(_level),max_level:string(_max_level)}), c_lime, c_black, 2);

	var _ring = tower_level_outline(_level);
	if(_ring != -1){
		draw_set_colour(_ring);
		draw_rectangle(_x+_w-26, _y+10, _x+_w-14, _y+22, false);
		draw_set_colour(c_white);
	}

	var _is_passive = tower_trait_get(_name,"passive",false);
	draw_set_font(fnt_size16);
	if(_is_passive){
		var _income_now = tower_wave_income(_name,_level,_spec_key),
		    _income_next = tower_wave_income(_name,_can_upgrade ? _level+1 : _level,_spec_key);
		draw_text_outline(_x+12,_y+40,
		    ui_text_format("tower_card_income",{income:string_format(_income_now,1,2)}),
		    c_yellow,c_black,1);
		var _next_income_text = (_can_upgrade && _income_next != _income_now)
		    ? ui_text_format("tower_card_next_income_from",{income:string_format(_income_next,1,2),previous:string_format(_income_now,1,2)})
		    : ui_text_format("tower_card_next_income",{income:string_format(_income_next,1,2)});
		draw_text_outline(_x+12,_y+60,_next_income_text,c_white,c_black,1);
		draw_set_font(fnt_size12);
		draw_text_outline(_x+12,_y+82,ui_text("tower_card_passive_note"),
		                  c_silver,c_black,1);
	} else {
		draw_text_outline(_x+12, _y+40,
		    ui_text_format("tower_card_damage",{current:string(round(_dmg)),change:_can_upgrade ? " -> "+string(round(_next_data[TOWER.damage])) : ""}),
		    c_white, c_black, 1);
		draw_text_outline(_x+12, _y+60,
		    ui_text_format("tower_card_range",{current:string(round(_range)),change:_can_upgrade ? " -> "+string(round(_next_data[TOWER.range])) : ""}),
		    c_white, c_black, 1);
		draw_set_font(fnt_size12);
		draw_text_outline(_x+176, _y+40,
		    ui_text_format("tower_card_rate",{current:string_format(_current_eff_rate,1,2),change:_can_upgrade ? " -> "+string_format(_next_eff_rate,1,2) : ""}),
		    c_white, c_black, 1);
		draw_set_font(fnt_size16);
		draw_text_outline(_x+176, _y+60,
		    ui_text_format("tower_card_targets",{
		        current:string(_targets),
		        change:_can_upgrade && _next_data[TOWER.targets] != _targets
		              ? " -> "+string(_next_data[TOWER.targets]) : ""
		    }),
		    c_white, c_black, 1);
		draw_text_outline(_x+12, _y+80,
		    ui_text_format("tower_card_dps",{current:string(round(_current_dps)),change:_can_upgrade ? " -> "+string(round(_next_dps)) : ""}),
		    c_yellow, c_black, 1);
		draw_text_outline(_x+176, _y+80,
		    ui_text_format("tower_card_crit",{
		        chance:string(round(_crit_chance*100)),
		        change:_can_upgrade && _next_crit_chance != _crit_chance
		              ? " -> "+string(round(_next_crit_chance*100))+"%" : ""
		    }),
		    c_white, c_black, 1);
	}

	if(_can_upgrade){
		draw_text_outline(_x+12, _y+100,
		    ui_text_format("tower_card_next_rung",{price:string(_price)}), c_lime, c_black, 1);
	} else if(_level >= _max_level){
		draw_text_outline(_x+12, _y+100, ui_text("tower_card_max_level"), c_gray, c_black, 1);
	} else {
		draw_text_outline(_x+12, _y+100, ui_text("tower_card_unavailable"), c_gray, c_black, 1);
	}
	if(!_is_passive){
		draw_text_outline(_x+176, _y+100,
		    ui_text_format("tower_card_crit_multiplier",{
		        multiplier:string_format(_crit_multiplier,1,2),
		        change:_can_upgrade && _next_crit_multiplier != _crit_multiplier
		              ? " -> x"+string_format(_next_crit_multiplier,1,2) : ""
		    }),
		    c_white, c_black, 1);
	}

	var _spec_path = tower_spec_find(_name,_spec_key),
	    _preview_level = _can_upgrade ? _level+1 : _level;
	draw_set_font(fnt_size12);
	if(is_struct(_spec_path)){
		var _tier_now = tower_spec_tier_limit(_level),
		    _tier_preview = tower_spec_tier_limit(_preview_level),
		    _spec_summary = tower_spec_signature_summary(
		        _name,_spec_key,_preview_level,
		        tower_spec_choice_effect_summary(_name,_spec_key,_preview_level)),
		    _spec_text = concat(_spec_path.label," T",_tier_now,
		                        _tier_preview > _tier_now ? concat("->T",_tier_preview) : "",
		                        " ",_spec_summary);
		draw_text_outline(_x+12, _y+120, ui_clip_text(_spec_text,_w-24),
		                   c_aqua,c_black,1);
	} else if(_level >= 3 || (_can_upgrade && _level+1 >= 3)){
		draw_text_outline(_x+12,_y+120,
		                  _level >= 3 ? ui_text("tower_card_choose_path") : ui_text("tower_card_choose_path_l3"),
		                  c_aqua,c_black,1);
	} else {
		var _trait = tower_stat_note(_name);
		if(_trait != "") draw_text_outline(_x+12, _y+120, ui_text_format("tower_card_trait",{trait:_trait}),c_white,c_black,1);
	}
	draw_set_font(fnt_size16);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}
