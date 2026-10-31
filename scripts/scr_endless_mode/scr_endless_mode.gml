/// @description Endless mode progression, modifiers, and loot boxes (goal.md §§19-22).
///
/// Endless reuses the campaign combat room with a synthetic 500-wave level.
/// Currency choices are persistent and saved immediately when claimed.

enum ENDLESS_MOD { NONE, HP, SPEED, HARDENED, SPLIT_SPAWN, BOSS, RANGE, ELITE, FINAL_BOSS };
#macro ENDLESS_TRICKLE_INTERVAL 10
#macro ENDLESS_TRICKLE_RATE 0.02

function endless_is_active() {
	return variable_global_exists("endless_active")
	    && is_bool(global.endless_active) && global.endless_active;
}

/// The first-region boss is the onboarding gate (goal.md §27.5).
function endless_is_unlocked() { return stage_cleared(1,10); }
function endless_wave_cap() { return 500; }

/// Called when the player confirms the four-tower Endless loadout.
function endless_begin() {
	global.endless_active = true;
	global.endless_setup = false;
	global.endless_wave = 0;
	global.endless_spawn_cursor = 0;
	global.endless_box_count = 0;
	global.endless_box_next_wave = 10;
	global.endless_box_pending = false;
	global.endless_box_rerolls = 0;
	global.endless_box_offers = [];
	global.endless_trickle_last_wave = 0;
	global.endless_trickle_seed_carry = 0;
	global.endless_trickle_clover_carry = 0;
	global.endless_trickle_seeds = 0;
	global.endless_trickle_clovers = 0;
	global.endless_result_written = false;
	scr_meta_log("ENDLESS","start difficulty=",difficulty_name(global.difficulty),
	             " loadout=",string(loadout_stored())," cap=",endless_wave_cap(),
	             " first_box=10");
	return true;
}

/// A synthetic row lets the normal state machine own spawn/wait/lose flow.
function endless_level_data() {
	return {
		region:1, stage:1, key:"endless", index:-1, biome:BIOME.GRASS,
		biome_name:"Endless", seeds:0, spawns:[0], bosses:[0,1],
		par_spend:0, par_time:0, waves:endless_wave_cap(), boss_wave:0,
		boss_every:0, endless:true,
		label:function() { return ui_text("endless_name"); },
		life_mult:function(_wave) { return 1; }
	};
}

function endless_wave_region(_wave) {
	if(!is_real(_wave)) _wave = 1;
	return clamp(1 + floor(max(0,_wave-1)/60),1,6);
}

/// Region spawn mixes are introduced across ten six-wave bands.
function endless_wave_stage(_wave) {
	if(!is_real(_wave)) _wave = 1;
	var _within = max(0,_wave-1) mod 60;
	return clamp(1+floor(_within/6),1,10);
}

/// Pay a small, banked Seeds/Clovers share every ten cleared Endless waves.
/// The stage baseline follows the region/stage currently represented by this
/// wave. Fractional shares carry through this run so floor() cannot erase them
/// (LL-042). Forced path-safety clears do not earn a milestone payout.
function endless_currency_trickle(_wave, _wave_forced) {
	if(!endless_is_active() || !is_real(_wave) || _wave < ENDLESS_TRICKLE_INTERVAL
	|| _wave mod ENDLESS_TRICKLE_INTERVAL != 0) return false;
	if(!is_bool(_wave_forced)) _wave_forced = true;
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return false;

	var _last = variable_global_exists("endless_trickle_last_wave")
	           && is_real(global.endless_trickle_last_wave)
	           ? global.endless_trickle_last_wave : 0;
	if(_wave <= _last) return false;
	global.endless_trickle_last_wave = _wave;
	if(_wave_forced){
		scr_meta_log("ENDLESS","milestone skipped wave=",_wave," reason=forced");
		return false;
	}

	var _region = endless_wave_region(_wave),
	    _stage = endless_wave_stage(_wave),
	    _row = stage_get(_region,_stage),
	    _difficulty = variable_global_exists("difficulty") && is_real(global.difficulty)
	                  ? clamp(floor(global.difficulty),0,DIFFICULTY.BRUTAL)
	                  : DIFFICULTY.NORMAL;
	if(!is_struct(_row)){
		scr_meta_log("ENDLESS","milestone skipped wave=",_wave,
		             " region=",_region," stage=",_stage," reason=no-stage-data");
		return false;
	}

	var _lives = get_item_value(STATINV.life);
	if(!is_real(_lives)) _lives = 0;
	var _seed_base = stage_seed_reward(_row,_difficulty,true),
	    _clover_base = clovers_award(_lives,_difficulty,0),
	    _seed_carry = variable_global_exists("endless_trickle_seed_carry")
	                  && is_real(global.endless_trickle_seed_carry)
	                  ? global.endless_trickle_seed_carry : 0,
	    _clover_carry = variable_global_exists("endless_trickle_clover_carry")
	                    && is_real(global.endless_trickle_clover_carry)
	                    ? global.endless_trickle_clover_carry : 0,
	    _seed_total = _seed_base*ENDLESS_TRICKLE_RATE+_seed_carry,
	    _clover_total = _clover_base*ENDLESS_TRICKLE_RATE+_clover_carry,
	    _seed_paid = floor(_seed_total),
	    _clover_paid = floor(_clover_total);
	global.endless_trickle_seed_carry = _seed_total-_seed_paid;
	global.endless_trickle_clover_carry = _clover_total-_clover_paid;

	if(_seed_paid > 0) seeds_add(_seed_paid);
	if(_clover_paid > 0) clovers_add(_clover_paid);
	global.endless_trickle_seeds = (variable_global_exists("endless_trickle_seeds")
	                               && is_real(global.endless_trickle_seeds)
	                               ? max(0,floor(global.endless_trickle_seeds)) : 0)
	                              + _seed_paid;
	global.endless_trickle_clovers = (variable_global_exists("endless_trickle_clovers")
	                                 && is_real(global.endless_trickle_clovers)
	                                 ? max(0,floor(global.endless_trickle_clovers)) : 0)
	                                + _clover_paid;
	var _saved = false;
	if(_seed_paid > 0 || _clover_paid > 0) _saved = scr_save_meta();
	scr_meta_log("ENDLESS","milestone wave=",_wave,
	             " region=",_region," stage=",_stage," lives=",floor(_lives),
	             " seeds=+",_seed_paid," clovers=+",_clover_paid,
	             " carry=",string_format(global.endless_trickle_seed_carry,1,2),"/",
	             string_format(global.endless_trickle_clover_carry,1,2),
	             " totals=",global.endless_trickle_seeds,"/",
	             global.endless_trickle_clovers," saved=",_saved);
	return true;
}

function endless_enemy_pool(_wave) {
	var _row = stage_get(endless_wave_region(_wave),endless_wave_stage(_wave));
	if(is_struct(_row) && is_array(_row.spawns) && array_length(_row.spawns) > 0){
		return _row.spawns;
	}
	return [0];
}

/// Modifier bands repeat every 90 waves: 20-29 HP, 30-39 speed,
/// 40-49 hardened, 50-59 split spawns, 60 boss, 70-79 range,
/// 80-89 elite horde, 90-99 recovery, 100 boss.
function endless_modifier(_wave) {
	if(!is_real(_wave) || _wave < 20) return ENDLESS_MOD.NONE;
	var _phase = (_wave-20) mod 90;
	if(_phase < 10) return ENDLESS_MOD.HP;
	if(_phase < 20) return ENDLESS_MOD.SPEED;
	if(_phase < 30) return ENDLESS_MOD.HARDENED;
	if(_phase < 40) return ENDLESS_MOD.SPLIT_SPAWN;
	if(_phase < 50) return ENDLESS_MOD.BOSS;
	if(_phase < 60) return ENDLESS_MOD.RANGE;
	if(_phase < 70) return ENDLESS_MOD.ELITE;
	if(_phase < 80) return ENDLESS_MOD.NONE;
	return ENDLESS_MOD.FINAL_BOSS;
}

function endless_modifier_name(_modifier) {
	switch(_modifier){
		case ENDLESS_MOD.HP: return ui_text("endless_mod_heavy_growth");
		case ENDLESS_MOD.SPEED: return ui_text("endless_mod_rush");
		case ENDLESS_MOD.HARDENED: return ui_text("endless_mod_hardened");
		case ENDLESS_MOD.SPLIT_SPAWN: return ui_text("endless_mod_two_spawn_points");
		case ENDLESS_MOD.BOSS: return ui_text("endless_mod_boss");
		case ENDLESS_MOD.RANGE: return ui_text("endless_mod_nightfall");
		case ENDLESS_MOD.ELITE: return ui_text("endless_mod_elite_horde");
		case ENDLESS_MOD.FINAL_BOSS: return ui_text("endless_mod_boss_final");
	}
	return ui_text("endless_mod_none");
}

function endless_cycle(_wave) {
	if(!is_real(_wave) || _wave < 20) return 0;
	return floor((_wave-20)/90);
}

function endless_hp_multiplier(_wave) {
	var _mod = endless_modifier(_wave),
	    _mult = power(1.5,endless_cycle(_wave));
	if(_mod == ENDLESS_MOD.HP) _mult *= 1.25;
	/// Armor is cut from the v1 combat contract; Hardened uses HP instead.
	if(_mod == ENDLESS_MOD.HARDENED) _mult *= 1.35;
	return _mult;
}

function endless_speed_multiplier(_wave) {
	var _mult = power(1.05,endless_cycle(_wave));
	if(endless_modifier(_wave) == ENDLESS_MOD.SPEED) _mult *= 1.20;
	return _mult;
}

function endless_tower_range_multiplier(_wave) {
	return endless_modifier(_wave) == ENDLESS_MOD.RANGE ? 0.80 : 1;
}

function endless_forced_elites(_wave) {
	return endless_modifier(_wave) == ENDLESS_MOD.ELITE;
}

function endless_is_boss_wave(_wave) {
	var _mod = endless_modifier(_wave);
	return _mod == ENDLESS_MOD.BOSS || _mod == ENDLESS_MOD.FINAL_BOSS;
}

function endless_boss_index(_wave, _final, _boss_count) {
	var _row = stage_get(endless_wave_region(_wave),10);
	if(is_struct(_row) && is_array(_row.bosses) && array_length(_row.bosses) > 0){
		var _slot = _final ? min(1,array_length(_row.bosses)-1) : 0,
		    _candidate = _row.bosses[_slot];
		if(is_real(_candidate) && _candidate >= 0) return _candidate;
	}
	return _final ? max(0,_boss_count-1) : 0;
}

function endless_spawn_split_active(_wave) {
	return endless_modifier(_wave) == ENDLESS_MOD.SPLIT_SPAWN;
}

/// Called by obj_mon/Create; only the two outer room spawners alternate.
function endless_spawn_index(_count) {
	if(!is_real(_count) || _count <= 1) return 0;
	if(!variable_global_exists("endless_spawn_cursor")
	|| !is_real(global.endless_spawn_cursor)) global.endless_spawn_cursor = 0;
	var _slot = (floor(global.endless_spawn_cursor) mod 2) == 0 ? 0 : _count-1;
	global.endless_spawn_cursor++;
	return _slot;
}

/// Tier 0..4: Common through Legendary.
function endless_tier_weights(_box_number) {
	if(_box_number >= 15) return [20,30,28,16,6];
	if(_box_number >= 6) return [35,30,22,10,3];
	return [50,28,14,6,2];
}

function endless_pick_tier(_box_number) {
	var _weights = endless_tier_weights(_box_number),
	    _roll = irandom(9999)/100,
	    _sum = 0;
	for(var _i = 0; _i < array_length(_weights); _i++){
		_sum += _weights[_i];
		if(_roll < _sum) return _i;
	}
	return array_length(_weights)-1;
}

function endless_tier_name(_tier) {
	switch(_tier){
		case 0: return ui_text("endless_tier_common");
		case 1: return ui_text("endless_tier_uncommon");
		case 2: return ui_text("endless_tier_rare");
		case 3: return ui_text("endless_tier_epic");
		case 4: return ui_text("endless_tier_legendary");
	}
	return ui_text("endless_tier_unknown");
}

function endless_array_has(_array, _value) {
	if(!is_array(_array)) return false;
	for(var _i = 0; _i < array_length(_array); _i++){
		if(_array[_i] == _value) return true;
	}
	return false;
}

function endless_towers_capped() {
	return tower_owned_count() >= array_length(tower_roster());
}

function endless_meta_capped() {
	if(!endless_towers_capped() || tower_mastery() < 5 || candy_duration_rank() < 10) return false;
	var _clover = clover_all_nodes();
	for(var _i = 0; _i < array_length(_clover); _i++){
		if(clover_rank(_clover[_i].id) < 5) return false;
	}
	var _blood = blood_tree_nodes();
	for(var _b = 0; _b < array_length(_blood); _b++){
		if(blood_node_rank(_blood[_b].id) < 1) return false;
	}
	var _recipes = candy_recipe_table();
	for(var _c = 0; _c < array_length(_recipes); _c++){
		var _id = _recipes[_c].id;
		if(!candy_recipe_unlocked(_id) || candy_level_get(_id) < 10) return false;
	}
	return true;
}

/// One offer from economy.md §7.3. Different reward kinds are preferred;
/// candy only appears when the player has an unlocked recipe to spend it on.
function endless_offer_make(_tier, _box_number, _used_kinds) {
	var _kinds = ["seeds","clovers"],
	    _candy = candy_pause_ids();
	if(_tier >= 1) _kinds[array_length(_kinds)] = "shards";
	if(array_length(_candy) > 0) _kinds[array_length(_kinds)] = "candy";
	var _available = [];
	for(var _i = 0; _i < array_length(_kinds); _i++){
		if(!endless_array_has(_used_kinds,_kinds[_i])){
			_available[array_length(_available)] = _kinds[_i];
		}
	}
	if(array_length(_available) == 0) _available = _kinds;
	var _kind = _available[irandom(array_length(_available)-1)],
	    _lo = 0, _hi = 0, _candy_id = "", _label = "", _convert = false;

	switch(_tier){
		case 0: _lo=5; _hi=10; break;
		case 1: _lo=10; _hi=20; break;
		case 2: _lo=25; _hi=45; break;
		case 3: _lo=50; _hi=80; break;
		default: _lo=100; _hi=100; break;
	}
	if(_kind == "clovers"){
		switch(_tier){
			case 0: _lo=10; _hi=20; break;
			case 1: _lo=20; _hi=35; break;
			case 2: _lo=40; _hi=70; break;
			case 3: _lo=80; _hi=120; break;
			default: _lo=150; _hi=150; break;
		}
	} else if(_kind == "shards"){
		switch(_tier){
			case 1: _lo=1; _hi=1; break;
			case 2: _lo=1; _hi=2; break;
			case 3: _lo=2; _hi=3; break;
			default: _lo=5; _hi=5; break;
		}
	} else if(_kind == "candy"){
		switch(_tier){
			case 0: _lo=1; _hi=2; break;
			case 1: _lo=2; _hi=4; break;
			case 2: _lo=3; _hi=6; break;
			case 3: _lo=5; _hi=8; break;
			default: _lo=10; _hi=10; break;
		}
		_candy_id = _candy[irandom(array_length(_candy)-1)];
		var _recipe = candy_recipe_find(_candy_id);
		_label = is_struct(_recipe) ? ui_text_format("endless_candy_stock",{name:_recipe.label}) : ui_text("endless_label_candy_stock");
	}
	var _amount = max(1,round(irandom_range(_lo,_hi)*(1+0.15*_box_number)));

	/// Preserve value after permanent sinks are all capped.
	if(_kind == "seeds" && endless_towers_capped()){
		_convert = true;
		_label = ui_text("endless_label_seeds_to_clovers");
	} else if(_kind == "clovers" && endless_meta_capped()){
		_convert = true;
		_label = ui_text("endless_label_clovers_to_shards");
	} else if(_kind != "candy" && _label == ""){
		_label = _kind == "seeds" ? ui_text("endless_label_seeds")
		        : (_kind == "clovers" ? ui_text("endless_label_clovers") : ui_text("endless_label_shards"));
	}
	return { tier:_tier, tier_name:endless_tier_name(_tier), kind:_kind,
	         candy_id:_candy_id, amount:_amount, label:_label, convert:_convert };
}

function endless_offer_generate(_box_number) {
	var _tiers = [], _seen_tiers = [], _offers = [], _used_kinds = [];
	for(var _i = 0; _i < 3; _i++){
		var _tier = endless_pick_tier(_box_number),
		    _tries = 0;
		while(endless_array_has(_seen_tiers,_tier) && _tries < 12){
			_tier = endless_pick_tier(_box_number);
			_tries++;
		}
		if(endless_array_has(_seen_tiers,_tier)){
			for(var _t = 0; _t < 5; _t++){
				if(!endless_array_has(_seen_tiers,_t)){ _tier=_t; break; }
			}
		}
		_tiers[_i] = _tier;
		_seen_tiers[array_length(_seen_tiers)] = _tier;
	}
	for(var _n = 0; _n < 3; _n++){
		var _offer = endless_offer_make(_tiers[_n],_box_number,_used_kinds);
		_offers[_n] = _offer;
		_used_kinds[array_length(_used_kinds)] = _offer.kind;
	}
	return _offers;
}

/// Called after a cleared milestone wave; one free reroll per box.
function endless_box_due(_wave) {
	if(!endless_is_active() || !is_real(_wave)) return false;
	if(!variable_global_exists("endless_box_next_wave")
	|| !is_real(global.endless_box_next_wave)) global.endless_box_next_wave = 10;
	return _wave >= global.endless_box_next_wave;
}

function endless_box_begin(_wave) {
	if(!endless_box_due(_wave)) return false;
	var _number = variable_global_exists("endless_box_count")
	             && is_real(global.endless_box_count)
	             ? global.endless_box_count+1 : 1;
	global.endless_box_offers = endless_offer_generate(_number);
	global.endless_box_pending = true;
	global.endless_box_rerolls = 1;
	scr_meta_log("ENDLESS","loot box #",_number," at wave ",_wave,
	             " tiers=",global.endless_box_offers[0].tier_name,",",
	             global.endless_box_offers[1].tier_name,",",
	             global.endless_box_offers[2].tier_name);
	return true;
}

function endless_box_option_rect(_index) {
	var _w = display_get_gui_width(), _h = display_get_gui_height(),
	    _margin = max(20,_w*0.045), _gap = max(10,_w*0.018),
	    _card_w = min(240,(_w-2*_margin-2*_gap)/3),
	    _card_h = min(190,_h*0.30),
	    _row_w = _card_w*3+_gap*2,
	    _x0 = (_w-_row_w)*0.5,
	    _y0 = (_h-_card_h)*0.5+12;
	return [_x0+_index*(_card_w+_gap),_y0,
	        _x0+_index*(_card_w+_gap)+_card_w,_y0+_card_h];
}

function endless_box_reroll_rect() {
	var _w = display_get_gui_width(), _h = display_get_gui_height(),
	    _bw = min(220,_w*0.30), _bh = 42,
	    _x = (_w-_bw)*0.5, _y = _h*0.5+min(118,_h*0.20);
	return [_x,_y,_x+_bw,_y+_bh];
}

function endless_box_hit() {
	var _m = points_to_gui(mouse_x,mouse_y,0),
	    _offers = variable_global_exists("endless_box_offers")
	               && is_array(global.endless_box_offers)
	               ? global.endless_box_offers : [];
	for(var _i = 0; _i < array_length(_offers); _i++){
		if(meta_in_rect(endless_box_option_rect(_i),_m[0],_m[1])) return _i;
	}
	return -1;
}

function endless_box_step() {
	if(!endless_is_active() || !global.endless_box_pending) return;
	if(!mouse_check_button_pressed(mb_left)) return;
	var _m = points_to_gui(mouse_x,mouse_y,0),
	    _reroll = endless_box_reroll_rect();
	if(meta_in_rect(_reroll,_m[0],_m[1]) && global.endless_box_rerolls > 0){
		global.endless_box_rerolls--;
		global.endless_box_offers = endless_offer_generate(global.endless_box_count+1);
		scr_meta_log("ENDLESS","loot box reroll remaining=",global.endless_box_rerolls);
		return;
	}
	var _pick = endless_box_hit(),
	    _offers = global.endless_box_offers;
	if(_pick < 0 || _pick >= array_length(_offers)) return;
	var _offer = _offers[_pick],
	    _amount = _offer.amount,
	    _kind = _offer.kind;
	if(_kind == "seeds"){
		if(_offer.convert) clovers_add(_amount*2); else seeds_add(_amount);
	} else if(_kind == "clovers"){
		if(_offer.convert){
			var _carry = variable_global_exists("meta") && is_struct(global.meta)
			             && variable_struct_exists(global.meta,"endless_clover_shard_carry")
			             && is_real(global.meta[$ "endless_clover_shard_carry"])
			             ? global.meta[$ "endless_clover_shard_carry"] : 0,
			    _total = _carry + _amount,
			    _whole = floor(_total/100);
			global.meta[$ "endless_clover_shard_carry"] = _total mod 100;
			if(_whole > 0) shards_add(_whole);
		} else clovers_add(_amount);
	} else if(_kind == "shards"){
		shards_add(_amount);
	} else if(_kind == "candy"){
		candy_stock_add(_offer.candy_id,_amount);
	}
	global.endless_box_count++;
	global.endless_box_next_wave = ceil(global.endless_box_next_wave*1.20);
	global.endless_box_pending = false;
	global.endless_box_offers = [];
	scr_save_meta();
	scr_meta_log("ENDLESS","box claimed kind=",_kind," amount=",_amount,
	             " box=",global.endless_box_count,
	             " next_wave=",global.endless_box_next_wave);
	scr_level_request(LEVEL_STATE.SPAWN);
}

/// Modal reward choice, painted in GUI space and registered for layout dumps.
function endless_box_draw() {
	if(!variable_global_exists("endless_box_pending") || !global.endless_box_pending) return;
	var _w = display_get_gui_width(), _h = display_get_gui_height(),
	    _offers = global.endless_box_offers,
	    _m = points_to_gui(mouse_x,mouse_y,0);
	draw_set_alpha(0.84);
	draw_set_colour(c_black);
	draw_rectangle(0,0,_w,_h,false);
	draw_set_alpha(1);
	draw_set_font(fnt_size32);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(c_white);
	var _head = ui_text_format("endless_box_heading",{box:string(global.endless_box_count+1),wave:string(get_item_value(STATINV.waves))});
	draw_text(_w*0.5,_h*0.17,_head);
	ui_reg_text("lootbox","heading",_w*0.5,_h*0.17,_head,fa_center,fa_middle);
	for(var _i = 0; _i < array_length(_offers); _i++){
		var _r = endless_box_option_rect(_i),
		    _offer = _offers[_i],
		    _hover = meta_in_rect(_r,_m[0],_m[1]);
		draw_set_colour(_hover ? make_colour_rgb(66,82,54) : make_colour_rgb(38,42,48));
		draw_rectangle(_r[0],_r[1],_r[2],_r[3],false);
		draw_set_colour(_hover ? c_lime : c_silver);
		draw_rectangle(_r[0],_r[1],_r[2],_r[3],true);
		draw_set_font(fnt_size16);
		draw_set_colour(c_yellow);
		draw_text((_r[0]+_r[2])*0.5,_r[1]+24,_offer.tier_name);
		var _kind = _offer.kind,
		    _icon = (_kind == "seeds") ? icon_currency(CURRENCY.SEEDS)
		          : (_kind == "clovers") ? icon_currency(CURRENCY.CLOVERS)
		          : (_kind == "shards") ? icon_currency(CURRENCY.SHARDS)
		          : icon_candy(_offer.candy_id),
		    _cy = _r[1]+(_r[3]-_r[1])*0.48;
		if(sprite_exists(_icon)) icon_draw(_icon,(_r[0]+_r[2])*0.5,_cy,48,"endless_reward");
		draw_set_font(fnt_size20);
		draw_set_colour(c_white);
		var _value = ui_text_format("endless_offer_amount",{amount:string(_offer.amount),label:_offer.label});
		if(_offer.convert && _kind == "seeds"){
			_value = ui_text_format("endless_seeds_to_clovers",{amount:string(_offer.amount),converted:string(_offer.amount*2)});
		} else if(_offer.convert && _kind == "clovers"){
			var _carry = variable_global_exists("meta") && is_struct(global.meta)
			             && variable_struct_exists(global.meta,"endless_clover_shard_carry")
			             && is_real(global.meta[$ "endless_clover_shard_carry"])
			             ? global.meta[$ "endless_clover_shard_carry"] : 0,
			    _total = _carry + _offer.amount,
			    _whole = floor(_total/100),
			    _remainder = _total mod 100;
			_value = _whole > 0
			         ? ui_text_format("endless_shards_meter_gain",{amount:string(_whole),remainder:string(_remainder)})
			         : ui_text_format("endless_shards_meter",{amount:string(_total)});
		}
		draw_text((_r[0]+_r[2])*0.5,_r[3]-32,ui_clip_text(_value,_r[2]-_r[0]-12));
		ui_reg_box("lootbox","offer."+string(_i),_r[0],_r[1],_r[2],_r[3]);
		ui_reg_text("lootbox","offer",(_r[0]+_r[2])*0.5,_r[3]-32,_value,fa_center,fa_middle);
	}
	var _rr = endless_box_reroll_rect(),
	    _enabled = global.endless_box_rerolls > 0,
	    _rlabel = _enabled ? ui_text("endless_reroll_ready") : ui_text("endless_reroll_used");
	draw_set_colour(_enabled ? make_colour_rgb(50,58,75) : make_colour_rgb(36,36,40));
	draw_rectangle(_rr[0],_rr[1],_rr[2],_rr[3],false);
	draw_set_colour(_enabled ? c_white : c_dkgray);
	draw_rectangle(_rr[0],_rr[1],_rr[2],_rr[3],true);
	draw_set_font(fnt_size16);
	draw_text((_rr[0]+_rr[2])*0.5,(_rr[1]+_rr[3])*0.5,_rlabel);
	ui_reg_box("lootbox","reroll",_rr[0],_rr[1],_rr[2],_rr[3]);
	ui_reg_text("lootbox","reroll",(_rr[0]+_rr[2])*0.5,(_rr[1]+_rr[3])*0.5,_rlabel,fa_center,fa_middle);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(fnt_size16);
	draw_set_colour(c_white);
	draw_set_alpha(1);
}

/// Finish a run and bank its local leaderboard record. Box choices were saved
/// when claimed, so ending never grants or removes unchosen rewards.
function endless_finish(_reason,_leaked) {
	if(variable_global_exists("endless_result_written")
	&& is_bool(global.endless_result_written) && global.endless_result_written) return false;
	var _wave = max(0,get_item_value(STATINV.waves)),
	    _score = max(0,get_item_value(STATINV.points)),
	    _lives = max(0,get_item_value(STATINV.life)),
	    _boxes = variable_global_exists("endless_box_count")
	             && is_real(global.endless_box_count) ? global.endless_box_count : 0,
	    _trickle_seeds = variable_global_exists("endless_trickle_seeds")
	                     && is_real(global.endless_trickle_seeds)
	                     ? max(0,floor(global.endless_trickle_seeds)) : 0,
	    _trickle_clovers = variable_global_exists("endless_trickle_clovers")
	                       && is_real(global.endless_trickle_clovers)
	                       ? max(0,floor(global.endless_trickle_clovers)) : 0,
	    _best_wave = 0, _best_score = 0;
	if(variable_global_exists("meta") && is_struct(global.meta)){
		if(variable_struct_exists(global.meta,"endless_best_wave")
		&& is_real(global.meta[$ "endless_best_wave"])) _best_wave=global.meta[$ "endless_best_wave"];
		if(variable_struct_exists(global.meta,"endless_best_score")
		&& is_real(global.meta[$ "endless_best_score"])) _best_score=global.meta[$ "endless_best_score"];
		global.meta[$ "endless_best_wave"] = max(_best_wave,_wave);
		global.meta[$ "endless_best_score"] = max(_best_score,_score);
	}
	var _new_best = (_wave > _best_wave),
	    _new_score = (_score > _best_score),
	    _final_best = max(_best_wave,_wave),
	    _difficulty = variable_global_exists("difficulty") && is_real(global.difficulty)
	                  ? global.difficulty : DIFFICULTY.NORMAL;
	global.level_result = {
		outcome:"ENDLESS", mode:"ENDLESS", reason:_reason,
		region:0, stage:0, difficulty:_difficulty, lives:_lives,
		leaked:is_real(_leaked) ? _leaked : 0,
		seeds:_trickle_seeds, clovers:_trickle_clovers, badges:"",
		waves:_wave, score:_score, best_wave:_final_best, boxes:_boxes
	};
	global.endless_result_written = true;
	global.endless_active = false;
	global.endless_setup = false;
	global.menu_entry = MENU_STATE.RESULTS;
	scr_music_stop();
	scr_save_meta();
	scr_meta_log("ENDLESS","ended reason=",_reason," wave=",_wave,
	             " score=",_score," boxes=",_boxes," best_wave=",_final_best,
	             " new_wave_best=",_new_best," new_score_best=",_new_score,
	             " milestone seeds=",_trickle_seeds," clovers=",_trickle_clovers);
	return true;
}

/// Current Endless wave and pressure, visible during play.
function endless_hud_draw() {
	if(!endless_is_active()) return;
	var _wave = get_item_value(STATINV.waves),
	    _mod = endless_modifier(_wave),
	    _region = endless_wave_region(_wave),
	    _best = (variable_global_exists("meta") && is_struct(global.meta)
	             && variable_struct_exists(global.meta,"endless_best_wave")
	             && is_real(global.meta[$ "endless_best_wave"]))
	            ? global.meta[$ "endless_best_wave"] : 0,
	    _text = ui_text_format("endless_hud",{wave:string(_wave),region:string(_region),modifier:endless_modifier_name(_mod),best:string(_best)});
	draw_set_font(fnt_size12);
	draw_set_halign(fa_right);
	draw_set_valign(fa_top);
	draw_text(display_get_gui_width()-12,34,_text);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}
