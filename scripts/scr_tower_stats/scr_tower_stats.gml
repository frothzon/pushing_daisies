/// @description  What a tower's card says: its numbers, its trait, and the one
///               line that says whether it can be bought.
///
/// THE GARDEN BOOK'S INFO BAR WAS THE SHOP'S LINE, NOT THE TOWER'S
/// ---------------------------------------------------------------
/// A single 30-unit bar under the wall said "Cannon Tulip - 25 seeds (click to
/// buy)", which answers "what does this cost" and nothing else.  A player
/// choosing between two cells needs the numbers those towers fire, and those
/// numbers already have exactly one source: tower_data_at_level() folds the
/// roster's base stats, the garden's clover bonuses and the level ladder
/// together (tower_levels).  This file FORMATS that output.  It never
/// re-derives it, and it never reads scr_towerData's arguments.

/// The label/value pairs the card shows, in reading order: two columns of
/// three.  An empty array means "no such tower" - the card then draws its
/// "nothing selected" line instead of six blanks (LL-002).
///
/// THE NUMBERS ARE LEVEL 1 WITH THE GARDEN'S CLOVERS APPLIED.  That is what a
/// freshly placed tower will actually do, which is the decision the card is
/// helping with; a level-6 figure would be a promise about money the player has
/// not spent.  clover_damage_bonus()/clover_firerate_bonus() are the same two
/// numbers scr_placeTower hands to tower_data_at_level, so the card and the
/// tower cannot quote different figures.
function tower_stat_lines(_name) {
	var _out = [];
	if(!is_string(_name)) return _out;

	var _e = tower_entry_find(_name);
	if(is_undefined(_e)) return _out;
	if(!is_array(_e.data)) return _out;

	if(tower_trait_get(_name,"passive",false)){
		var _income = tower_wave_income(_name,1,tower_spec_saved(_name));
		_out[0] = { label : ui_text("meta_tower_stat_income"), value : ui_text_format("meta_tower_stat_income_value",{income:string_format(_income,1,2)}) };
		_out[1] = { label : ui_text("meta_tower_stat_level_1_2"), value : "$1/wave" };
		_out[2] = { label : ui_text("meta_tower_stat_level_3_4"), value : "$2/wave" };
		_out[3] = { label : ui_text("meta_tower_stat_level_5"), value : "$3/wave" };
		_out[4] = { label : ui_text("meta_tower_stat_level_6_10"), value : ui_text("meta_tower_stat_mastery_bonus") };
		_out[5] = { label : ui_text("meta_tower_stat_price"), value : "$"+string(_e.price) };
		return _out;
	}

	var _d = tower_data_at_level(_e.data, 1,
	                             clover_damage_bonus(), clover_firerate_bonus());
	if(!is_array(_d)) return _out;

	var _dmg  = _d[TOWER.damage],
	    _rate = _d[TOWER.fire_rate],
	    _tgt  = _d[TOWER.targets],
	    _projectiles = array_length(_d) > TOWER.projectiles && is_real(_d[TOWER.projectiles])
	                   ? max(1,round(_d[TOWER.projectiles])) : 1,
	    _dps  = _dmg * _rate * _projectiles;

	_out[0] = { label : ui_text("meta_tower_stat_damage"), value : string(round(_dmg)) };
	_out[1] = { label : ui_text("meta_tower_stat_rate"), value : ui_text_format("meta_tower_stat_rate_value",{rate:string(_rate)}) };
	_out[2] = { label : ui_text("meta_tower_stat_dps"), value : string(round(_dps)) };
	_out[3] = { label : ui_text("meta_tower_stat_range"), value : string(round(_d[TOWER.range])) };
	_out[4] = { label : ui_text("meta_tower_stat_targets_projectiles"), value : string(_tgt)+" / "+string(_projectiles) };
	_out[5] = { label : ui_text("meta_tower_stat_price"), value : "$" + string(_e.price) };
	return _out;
}

/// The one-line trait note under the grid, or "" when the tower has no trait.
///
/// The trait half of a tower lives in scr_tower_roster's table, keyed by NAME,
/// and tower_trait_get() is its only reader - so a tower with no row (silence)
/// costs no note and no error.  A SLOW is spelled out in the player's terms
/// ("55% speed for 1.5s") rather than as a status id, because a name the game
/// has not shown anywhere yet is not an explanation.
function tower_stat_note(_name) {
	if(tower_trait_get(_name,"passive",false)){
		return ui_text("tower_trait_passive_note");
	}
	var _effects = tower_trait_statuses(_name),
	    _out = "";
	for(var _i = 0; _i < array_length(_effects); _i++){
		var _e = _effects[_i],
		    _part = "";
		switch(_e.kind){
			case STATUS.SLOW:
				_part = ui_text_format("tower_trait_slow",{speed:string(round(_e.mult*100)),seconds:string(_e.seconds)});
				break;
			case STATUS.STUN:
				_part = ui_text_format("tower_trait_stun",{chance:string(round(_e.chance*100)),seconds:string(_e.seconds)});
				break;
			case STATUS.BURN:
				_part = ui_text_format("tower_trait_burn",{chance:string(round(_e.chance*100)),amount:string(_e.amount),seconds:string(_e.seconds)});
				break;
			case STATUS.POISON:
				_part = ui_text_format("tower_trait_poison",{chance:string(round(_e.chance*100)),amount:string(_e.amount),seconds:string(_e.seconds)});
				break;
			case STATUS.ROOT:
				_part = ui_text_format("tower_trait_root",{chance:string(round(_e.chance*100)),seconds:string(_e.seconds)});
				break;
			case STATUS.BLEED:
				_part = ui_text_format("tower_trait_bleed",{chance:string(round(_e.chance*100)),amount:string(_e.amount),seconds:string(_e.seconds)});
				break;
			case STATUS.VULN:
				_part = ui_text_format("tower_trait_vulnerable",{chance:string(round(_e.chance*100)),amount:string(round(_e.amount*100)),seconds:string(_e.seconds)});
				break;
		}
		if(_part != "") _out += (_out == "" ? "" : "; ") + _part;
	}
	if(_out != "") return _out;

	var _crit = tower_trait_get(_name, "crit", 0);
	if(is_real(_crit) && _crit > 0){
		return ui_text_format("tower_trait_crit",{chance:string(round(_crit*100))});
	}
	return "";
}


/// The buy line: what the shop cell's click would do, in the same words the
/// old info bar used, so nothing the player could read before was lost.
///
/// "" for a name that is not in the roster - the card then draws nothing,
/// rather than " - 0 seeds".
function tower_stat_state(_name) {
	if(!is_string(_name)) return "";

	var _e = tower_entry_find(_name);
	if(is_undefined(_e)) return "";

	if(tower_owned(_name))       return ui_text("meta_tower_owned");
	if(!tower_gate_met(_name))   return ui_text_format("meta_tower_locked_region",{region:string(tower_unlock_gate(_name))});

	var _cost = string(_e.unlock);
	return tower_can_unlock(_name)
	       ? ui_text_format("meta_tower_seed_buy",{cost:_cost})
	       : ui_text_format("meta_tower_seed_cost",{cost:_cost});
}

/// Is the buy line good news?  Owned and affordable are lime; everything else
/// is silver, which is how the old bar coloured itself (lime when owned or
/// buyable).  Kept here rather than in the draw so the two screens that will
/// eventually show this card cannot disagree about what "good" looks like.
function tower_stat_state_ok(_name) {
	if(!is_string(_name)) return false;
	return tower_owned(_name) || tower_can_unlock(_name);
}
