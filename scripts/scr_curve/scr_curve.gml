/// @description  The curve diagnostic - what the wave ramp actually costs
/// (card curve-diagnostic, economy.md 4.5/4.6, roadmap 2.6).
///
/// WHY THIS EXISTS.  The curve is now data - a per-biome `m(w)` in
/// region_data() - and the ladder that answers it is data too
/// (tower_levels.gml).  Two tables that only mean something TOGETHER is
/// exactly the LL-022 trap, and there was no way to see either one without
/// playing sixty waves.  This prints both, once, on the way into a stage.
///
/// WHAT IT PRINTS - and the same lines are DRAWN ON SCREEN, top-left, by
/// scr_curve_draw(), because the Output window is not visible while playing:
///
///   META  [CURVE] R1 Grass   15..60w   m 1.00 -> 13.00    hp 7 -> 91
///       one line per biome.  `m` must be 1.00 on wave 1 in EVERY row (wave 1
///       of any stage is the same fight) and must equal the region's
///       curve_end on that region's last wave.  Route-independent, so all six
///       print even though only region 1 has stages today.
///
///   META  [CURVE] 1-1   route 1496px z 6.2   slots 14   best 168.0 dps
///   META  [CURVE] dps per $ : place 2.4  rung 0.166   <- rung is dominated
///       the current stage only, because the route is a property of THIS room.
///       `slots` is how many cells can actually shoot that route - the ceiling
///       money alone does not capture (scr_curve_slots).
///
///   META  [CURVE] 1-1 Normal  w1   5x 7hp    req 1.8  bite 0.03  LOW
///   META  [CURVE] 1-1 Normal  w10 BOSS  1x 714hp  req 18.5  bite 0.11  ok
///   META  [CURVE] 1-1 Normal  w15  8x 91hp   req 38.7  bite 0.23  ok
///       a row for the first wave, the first mid-stage BOSS wave, and the last
///       wave, per difficulty.  `req` is the DPS that must be sustained so
///       nothing walks the route; `bite = req / avail`, where avail is what
///       that wave's earnings can field.  LOW / HIGH / ok is the band below.
///
/// THE TARGETS (the card's): floor bite >= 0.35 (wave 1 must not be trivial),
/// ceiling bite <= 0.90 (the last wave must be survivable).  A row outside
/// that band is the finding, not a bug in the diagnostic - it is the whole
/// reason the line exists.
///
/// THE MODEL, stated so it can be argued with:
///   req(w)   = count(w) * hp(w) / walk_seconds(w)
///              count = spawn_count + w div 5 + difficulty_count_bonus()
///                      (the scr_level_spawn rule)
///              hp    = base_life * region_life_mult(w) * difficulty hp
///              walk  = route_len / path_speed, terrain sampled from
///                      LEVEL.ground_map the same way scr_zomb_pathSpeed
///                      samples it (x>>5, y>>5) - route_len is the spawn
///                      -> despawn path over the CURRENT grid.
///   avail(w) = min(money_through(w) / price, slots) * best_place_dps
///              money buys towers, but only `slots` cells can reach the route,
///              so the smaller of the two is what the income can field.
///   bite     = req / avail
///
/// A BOSS wave is projected from `spawn_boss`, not the ordinary pool, and
/// sends exactly one creature - see scr_curve_wave_demand.
///
/// A diagnostic must never be able to throw (LL-002) - a log line that
/// errors aborts the rest of the event - so every read below is guarded and
/// the whole thing is gated on devMode.

/// ---- the walk, reusing the game's own arithmetic ---------------------------
///
/// One monster crossing `_len` pixels, at the terrain height `_z_climb`, in
/// wave `_wave`, on a difficulty whose speed column is `_speed_mult`.  This is
/// scr_zomb_pathSpeed's formula, evaluated for a projection instead of a live
/// monster; if that function changes, change it here too (one source per
/// number would be better, but it is instance-bound and this is not).
function scr_curve_walk_seconds(_len, _z_climb, _monster_speed, _wave, _speed_mult) {
	if(!is_real(_len) || _len <= 0) return 0;

	var _fps = max(game_get_speed(gamespeed_fps), 1),
	    _z   = clamp(is_real(_z_climb) ? _z_climb : 0, 0, 12);

	var _spd = ((12 - _z) / 12) * 1.5 + 0.5;   /// terrain: hills are slow
	if(_z < 2) _spd = 0.25;                     /// water is slower still
	/// The ramp pulls a speed TOWARD 1, and scr_zomb_pathSpeed only applies it
	/// when the ground is SLOW (`if(_spd < 1)`).  Applying it unconditionally -
	/// which this did - slows the projection where the game does not, so the
	/// panel was optimistic exactly where the player is most exposed (card
	/// balance-speed-ramp-divergence).
	if(_spd < 1){
	    var _weight = 1 - power(2, -(_wave / 30));
	    _spd = _spd * (1 - _weight) + _weight;
	}
	_spd += 0.01 * _wave;

	var _px = _spd * (is_real(_monster_speed) ? _monster_speed : 1) * _speed_mult;
	if(_px <= 0) return 0;
	return (_len / _px) / _fps;
}

/// How many of a wave's creature there are - the scr_level_spawn rule, with
/// the difficulty column's extra (Brutal sends one more).
function scr_curve_wave_count(_spawn_count, _wave, _count_bonus) {
	if(!is_real(_spawn_count)) _spawn_count = 5;
	if(!is_real(_count_bonus))  _count_bonus  = 0;
	var _n = _spawn_count + (_wave div 5) + _count_bonus;
	return (_n < 1) ? 1 : _n;
}

/// The mean of one numeric field over a list of pool indices - so the stage's
/// own creature mix sets the projection, rather than a hand-picked monster.
/// Returns `_fallback` when nothing can be read (LL-002).
function scr_curve_pool_mean(_bank, _pool, _field, _fallback) {
	if(!is_array(_bank) || !is_array(_pool)) return _fallback;
	var _sum = 0, _n = 0;
	for(var _i = 0; _i < array_length(_pool); _i++){
		var _idx = _pool[_i];
		if(!is_real(_idx)) continue;
		if(_idx < 0 || _idx >= array_length(_bank)) continue;
		var _row = _bank[_idx];
		if(!is_array(_row)) continue;
		if(_field < 0 || _field >= array_length(_row)) continue;
		var _v = _row[_field];
		if(!is_real(_v)) continue;
		_sum += _v; _n++;
	}
	if(_n == 0) return _fallback;
	return _sum / _n;
}

/// The best placement DPS a dollar buys in the current loadout
/// (`dps / price`), and the same figure for taking a tower to its cap.
///
/// This is economy.md 4.6's inequality as two numbers: when rung < place,
/// upgrading is dominated by simply placing another tower, and the rung price
/// is wrong.  Both come from the SAME tower_array the level armed itself with,
/// so a ladder or price change is reflected here the moment it lands.
///
/// Returns { place, rung, dps, price, range } - the winning tower's own
/// numbers ride along so the caller can price what the money can field
/// without re-deriving them.  A STRUCT, not out-parameters: GML passes a
/// scalar argument BY VALUE, so writing `_out = x` inside a function would
/// never reach the caller.
function scr_curve_dps_per_money() {
	var _best_place = 0, _best_rung = 0, _best_dps = 0,
	    _best_price = 0, _best_range = 0;
	if(variable_instance_exists(id, "tower_array") && is_array(tower_array)){

		var _cap   = tower_cap(),
		    _dmgb  = clover_damage_bonus(),
		    _rateb = clover_firerate_bonus();

		for(var _t = 0; _t < array_length(tower_array); _t++){
			var _ent = tower_array[_t];
			if(!is_array(_ent) || array_length(_ent) < 5) continue;
			var _price = _ent[2], _floor_data = _ent[3], _base = _ent[4];
			if(!is_real(_price) || _price <= 0) continue;
			if(!is_array(_floor_data) || !is_array(_base)) continue;

			var _dps_floor = _floor_data[TOWER.damage] * _floor_data[TOWER.fire_rate]
			                 * _floor_data[TOWER.targets];
			var _place = _dps_floor / _price;
			if(_place > _best_place){
				_best_place = _place;
				_best_dps   = _dps_floor;
				_best_price = _price;
				_best_range = _floor_data[TOWER.range];
			}

			/// the four rungs cost 0.50+0.75+1.00+1.50 = 3.75 base prices
			var _cap_data = tower_data_at_level(_base, _cap, _dmgb, _rateb);
			if(is_array(_cap_data)){
				var _dps_cap = _cap_data[TOWER.damage] * _cap_data[TOWER.fire_rate]
				               * _cap_data[TOWER.targets];
				var _rung = (_dps_cap - _dps_floor) / (_price * 3.75);
				if(_rung > _best_rung) _best_rung = _rung;
			}
		}
	}
	return { place : _best_place, rung : _best_rung,
	         dps   : _best_dps,   price: _best_price, range: _best_range };
}

/// The mean of one field over a WHOLE bank - used for the boss pool, whose
/// members (Tusk-A-Lot life 55, Sub-Zero life 110) are very different and
/// whose selection is random (scr_level_pick_spawn).
function scr_curve_bank_mean(_bank, _field, _fallback) {
	if(!is_array(_bank) || array_length(_bank) == 0) return _fallback;
	var _all = [];
	for(var _i = 0; _i < array_length(_bank); _i++) _all[_i] = _i;
	return scr_curve_pool_mean(_bank, _all, _field, _fallback);
}

/// Is `_w` a boss wave for this stage?  The rule is scr_level_pick_spawn's,
/// not a copy of a magic number: the stage's MID wave, and its last wave
/// (LL-060).  Both read the SAME number (GameLevelData.boss_wave), so the
/// read-out can no longer project a boss on a wave play does not send one.
function scr_curve_is_boss_wave(_w, _waves, _boss_wave) {
	if(_boss_wave > 1 && _w == _boss_wave) return true;
	if(_w >= _waves) return true;
	return false;
}

/// Money earned by the time wave `_w` STARTS (economy.md 4.1): the starting
/// purse plus every kill payout up to and including that wave.  A boss pays
/// `wave + 1` (scr_level_spawn rewrites the payout); a normal wave pays its
/// count times the creature's kill money.
function scr_curve_money_through(_w, _spawn_count, _kill_money, _drow,
                                 _waves, _boss_wave) {
	var _money = 25 * _drow.life;   /// the starting purse is difficulty-scaled
	for(var _k = 1; _k <= _w; _k++){
		if(scr_curve_is_boss_wave(_k, _waves, _boss_wave)){
			_money += (_k + 1) * _drow.money;
		} else {
			_money += scr_curve_wave_count(_spawn_count, _k, _drow.count)
			          * _kill_money * _drow.money;
		}
	}
	return _money;
}

/// One wave's demand: what `_w` sends, and the DPS needed to stop it.
/// Returns { count, hp, boss, req }.
///
/// The boss branch is not a detail.  Every stage sends a boss on its MID wave
/// (waves div 2) and on its last one - ONE creature (scr_level_spawn: MAX = 1)
/// drawn from
/// spawn_boss, where Tusk-A-Lot is life 55 and Sub-Zero life 110 against
/// Grumble-Mulch's 7.  Projecting wave 10 from the ordinary pool understates
/// it by roughly an order of magnitude, which is exactly the wave this
/// diagnostic exists to explain.
function scr_curve_wave_demand(_w, _is_boss, _drow, _waves, _region_row,
                               _spawn_mon, _spawn_boss, _pool,
                               _spawn_count, _route_len, _route_z) {
	var _count = _is_boss ? 1
	                      : scr_curve_wave_count(_spawn_count, _w, _drow.count),
	    _life  = _is_boss ? scr_curve_bank_mean(_spawn_boss, MON.life, 55)
	                      : scr_curve_pool_mean(_spawn_mon, _pool, MON.life, 7),
	    _speed = _is_boss ? scr_curve_bank_mean(_spawn_boss, MON.speed, 0.5)
	                      : scr_curve_pool_mean(_spawn_mon, _pool, MON.speed, 1);

	var _hp   = _life * region_life_mult(_region_row, _w, _waves) * _drow.hp,
	    _walk = scr_curve_walk_seconds(_route_len, _route_z, _speed,
	                                   _w, _drow.speed);

	return {
		count : _count,
		hp    : _hp,
		boss  : _is_boss,
		req   : (_walk > 0) ? (_count * _hp) / _walk : 0
	};
}

/// How many towers can actually REACH the route: grid cells whose centre is
/// inside the chosen tower's range of the path and that are not already
/// blocked (walls, spawns, other towers).
///
/// This is the ceiling the model was missing.  Without it `available` says
/// "every dollar you ever earned is a tower that shoots the path", which is
/// how a diagnostic can report `ok` while a full wrap leaks: money is not the
/// only constraint, reachable ground is.  Sampled ALONG the route rather than
/// only at its corners, so a long straight leg counts.
function scr_curve_slots(_path, _len, _range, _cell) {
	if(!path_exists(_path) || _len <= 0 || _range <= 0) return 0;
	if(!is_real(_cell) || _cell <= 0) _cell = 32;

	var _half  = ceil(_range / _cell),
	    _seen  = ds_map_create(),
	    _n     = max(2, ceil(_len / 16)),   /// a sample every 16px
	    _slots = 0;

	for(var _i = 0; _i <= _n; _i++){
		var _t  = _i / _n,
		    _px = path_get_x(_path, _t),
		    _py = path_get_y(_path, _t),
		    /// cell (c,r) covers the rect that starts at (c*cell-cell, r*cell-cell)
		    _cx = (_px + _cell) div _cell,
		    _cy = (_py + _cell) div _cell;

		for(var _dx = -_half; _dx <= _half; _dx++){
			for(var _dy = -_half; _dy <= _half; _dy++){
				var _gx = _cx + _dx,
				    _gy = _cy + _dy,
				    _key = string(_gx) + "," + string(_gy);
				if(ds_map_exists(_seen, _key)) continue;
				/// out of range of THIS sample - do not mark it, a later
				/// sample may be the closer one
				if(point_distance(_px, _py, _gx*_cell - _cell*0.5,
				                  _gy*_cell - _cell*0.5) > _range) continue;
				ds_map_add(_seen, _key, 1);
				/// 0 = free; anything else (wall, tower, off-grid -1) is not
				if(!variable_instance_exists(id, "path_grid")) continue;
				if(mp_grid_get_cell(path_grid, _gx, _gy) != 0) continue;
				_slots++;
			}
		}
	}

	ds_map_destroy(_seen);
	return _slots;
}

/// Draw the lines the report stored, as an on-screen panel (Draw GUI).
///
/// A log is only useful if you can see it, and the Output window is not
/// visible while playing - hence this.  It draws what was computed ONCE at
/// stage entry, so the per-frame cost is a few strings and nothing else; no
/// path-finding and no grid work happens here.
function scr_curve_draw() {
	if(!variable_global_exists("devMode")) return;
	if(!global.devMode) return;
	if(!variable_instance_exists(id, "curve_lines")) return;
	if(!is_array(curve_lines) || array_length(curve_lines) == 0) return;

	/// set the font FIRST - the measurements below must be of the font the
	/// lines are actually drawn in, and Draw GUI leaves fnt_size16 in place
	/// whenever a tower is selected
	draw_set_font(fnt_debug);

	var _x  = 8,
	    _y  = 8,
	    _fh = string_height(string_hash_to_newline("H")) + 2,
	    _h  = array_length(curve_lines) * _fh + 8,
	    _w  = 0;

	for(var _i = 0; _i < array_length(curve_lines); _i++){
		_w = max(_w, string_width(curve_lines[_i]));
	}

	/// a translucent plate, so the panel reads over grass and over water
	draw_set_alpha(0.65);
	draw_set_colour(c_black);
	draw_rectangle(_x - 4, _y - 4, _x + _w + 4, _y + _h, false);
	draw_set_alpha(1);
	draw_set_colour(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);

	for(var _i = 0; _i < array_length(curve_lines); _i++){
		draw_text_outline(_x, _y + _i * _fh, curve_lines[_i], c_white, c_black, 1);
	}

	draw_set_colour(c_white);
	draw_set_alpha(1);
}

/// The whole diagnostic.  Call it once, when a level enters START (in
/// _levelControl's scope, so spawn_mon / tower_array / ground_map are its own).
/// Prints and returns nothing; gated on devMode.
function scr_curve_report() {
	if(!variable_global_exists("devMode")) return;
	if(!global.devMode) return;

	var _row = stage_current();
	if(!is_struct(_row)){ scr_meta_log("CURVE", "no stage data"); return; }

	/// Collected so the Draw GUI event can put the SAME lines on screen -
	/// the panel is the point; the log is a transcript of it.
	var _lines = [];

	/// ---- (a) every biome, both ends - route-independent, so all six print
	var _ref_life = 7;   /// a fallback; the real bank is read just below
	if(variable_instance_exists(id, "spawn_mon") && is_array(spawn_mon)
	   && array_length(spawn_mon) > 0 && is_array(spawn_mon[0])){
		var _l0 = spawn_mon[0][MON.life];
		if(is_real(_l0) && _l0 > 0) _ref_life = _l0;
	}

	var _regions = region_data();
	for(var _i = 0; _i < array_length(_regions); _i++){
		var _r = _regions[_i];
		if(!is_struct(_r)) continue;
		var _last = _r.wave_first + _r.wave_step * 9;   /// stage 10 = longest
		var _m1   = region_life_mult(_r, 1, _last),
		    _mN   = region_life_mult(_r, _last, _last);
		_lines[array_length(_lines)] = scr_meta_log("CURVE",
		    "R", _r.region, " ", _r.name, "   ", _r.wave_first, "..", _last, "w",
		    "   m ", round(_m1 * 100) / 100, " -> ", round(_mN * 100) / 100,
		    "    hp ", _ref_life, " -> ", round(_ref_life * _mN));
	}

	/// ---- (b) the current stage - supply, demand, bite ----------------------
	var _region_row = region_get(_row.region);
	if(!is_struct(_region_row)){
		_lines[array_length(_lines)] = scr_meta_log("CURVE", "no region row");
		curve_lines = _lines;
		return;
	}

	var _waves = _row.waves;
	if(!is_real(_waves) || _waves < 2) _waves = 2;

	/// the stage's own creature mix
	var _pool = _row.spawns;
	if(!is_array(_pool) || array_length(_pool) == 0) _pool = [0];

	var _has_bank = variable_instance_exists(id, "spawn_mon") && is_array(spawn_mon);
	var _spawn_count = _has_bank
		? scr_curve_pool_mean(spawn_mon, _pool, MON.spawn_count, 5) : 5;
	var _kill_money  = _has_bank
		? scr_curve_pool_mean(spawn_mon, _pool, MON.kill_money, 1) : 1;

	/// the boss waves: the stage's own MID wave (derived in GameLevelData as
	/// waves div 2) and its last.  The region's `boss_every` cadence is no
	/// longer what the game sends, so reading it here projected a boss on a
	/// wave play never sends one (LL-060).
	var _boss_wave = 0;
	if(variable_struct_exists(_row, "boss_wave") && is_real(_row.boss_wave)){
		_boss_wave = _row.boss_wave;
	}

	/// ---- what a dollar buys (economy.md 4.6), computed once ---------------
	var _dpm = scr_curve_dps_per_money(),
	    _dps_place = is_struct(_dpm) ? _dpm.dps   : 0,
	    _price     = is_struct(_dpm) ? _dpm.price : 0,
	    _range     = is_struct(_dpm) ? _dpm.range : 0,
	    _place     = is_struct(_dpm) ? _dpm.place : 0,
	    _best_rung = is_struct(_dpm) ? _dpm.rung  : 0;

	/// the route, over the CURRENT grid (walls block their own cell - LL-027)
	var _route_len = 0, _route_z = 0, _slots = 0, _path = -1;
	if(variable_instance_exists(id, "path_grid")
	   && instance_exists(obj_spawn) && instance_exists(obj_despawn)){
		_path = path_add();
		scr_grid_block_instances(path_grid, obj_wall);
		scr_grid_block_instances(path_grid, obj_tower);
		var _sp = instance_find(obj_spawn, 0);
		if(instance_exists(_sp)
		   && scr_path_try(path_grid, _sp.x, _sp.y,
		                   obj_despawn.x, obj_despawn.y, _path)){
			_route_len = path_get_length(_path);
			/// the mean terrain height along the route, sampled exactly the
			/// way scr_zomb_pathSpeed samples it (x>>5, y>>5)
			if(variable_instance_exists(id, "ground_map")
			   && ds_exists(ground_map, ds_type_grid)){
				var _pts = path_get_number(_path), _sum = 0, _n = 0;
				for(var _p = 0; _p < _pts; _p++){
					var _tgx = clamp((path_get_point_x(_path, _p)) >> 5, 0,
					                 ds_grid_width(ground_map) - 1);
					var _tgy = clamp((path_get_point_y(_path, _p)) >> 5, 0,
					                 ds_grid_height(ground_map) - 1);
					var _h = ground_map[# _tgx, _tgy];
					if(is_real(_h)){ _sum += _h; _n++; }
				}
				if(_n > 0) _route_z = _sum / _n;
				if(instance_exists(_mainControl)){
					if(_route_z == _mainControl.load_max) _route_z *= 0.5;
				}
			}
			/// how much ground can actually shoot the route - the ceiling
			/// that money alone does not capture
			var _cell = variable_instance_exists(id, "cell_w") ? cell_w : 32;
			_slots = scr_curve_slots(_path, _route_len, _range, _cell);
		}
		path_delete(_path);
	}
	if(_route_len <= 0){
		_lines[array_length(_lines)] = scr_meta_log("CURVE",
		    "no route from spawn to despawn - bite not projected");
		curve_lines = _lines;
		return;
	}

	/// ---- (b2) the stage's own numbers, and what a dollar buys ------------
	_lines[array_length(_lines)] = scr_meta_log("CURVE",
	    _row.region, "-", _row.stage,
	    "   route ", round(_route_len), "px z ", round(_route_z * 10) / 10,
	    "   slots ", _slots,
	    "   best ", round(_slots * _dps_place * 10) / 10, " dps");
	_lines[array_length(_lines)] = scr_meta_log("CURVE",
	    "dps per $ : place ", round(_place * 1000) / 1000,
	    "  rung ", round(_best_rung * 1000) / 1000,
	    (_best_rung < _place ? "   <- rung is dominated (economy 4.6)"
	                         : "   (a rung pays for itself)"));

	/// ---- (c) demand, supply and the bite, per difficulty ------------------
	/// The card's band: floor (wave 1) >= 0.35, ceiling (last wave) <= 0.90.
	///
	/// A BOSS wave gets its own row, because it is a different fight: ONE
	/// creature (scr_level_spawn: MAX = 1) drawn from spawn_boss, life 55-110
	/// against Grumble-Mulch's 7.
	var _bank_mon  = (variable_instance_exists(id, "spawn_mon")
	                  && is_array(spawn_mon))  ? spawn_mon  : [];
	var _bank_boss = (variable_instance_exists(id, "spawn_boss")
	                  && is_array(spawn_boss)) ? spawn_boss : [];

	/// ALL THREE.  This projected NORMAL and BRUTAL only, so HARD - a fully
	/// wired column (hp 1.5, speed 1.05, money 1.25, life 1.10) and the middle
	/// case the feel targets are written against - was never projected at all
	/// (card balance-hard-not-projected).
	var _diffs = [DIFFICULTY.NORMAL, DIFFICULTY.HARD, DIFFICULTY.BRUTAL],
	    _drows = difficulty_data();

	for(var _di = 0; _di < array_length(_diffs); _di++){
		var _drow = _drows[_diffs[_di]];
		if(!is_struct(_drow)) continue;

		/// which waves to project: the first, the stage's MID boss wave, and
		/// the last
		var _show = [1];
		for(var _w = 2; _w < _waves; _w++){
			if(scr_curve_is_boss_wave(_w, _waves, _boss_wave)){
				_show[array_length(_show)] = _w;
				break;
			}
		}
		_show[array_length(_show)] = _waves;

		var _prev = -1;
		for(var _ei = 0; _ei < array_length(_show); _ei++){
			var _w = _show[_ei];
			if(_w == _prev) continue;   /// the boss may BE the last wave
			_prev = _w;

			var _is_boss = scr_curve_is_boss_wave(_w, _waves, _boss_wave),
			    _dem = scr_curve_wave_demand(_w, _is_boss, _drow, _waves,
			                                 _region_row, _bank_mon, _bank_boss,
			                                 _pool, _spawn_count,
			                                 _route_len, _route_z),
			    _money = scr_curve_money_through(_w, _spawn_count, _kill_money,
			                                     _drow, _waves, _boss_wave),
			    /// what the money can field: the smaller of "as many towers
			    /// as it buys" and "as many towers as can reach the route"
			    _placeable = min(floor(_money / max(_price, 1)), _slots),
			    _avail = _placeable * _dps_place,
			    _bite  = (_avail > 0) ? _dem.req / _avail : -1;

			var _verdict = "?";
			if(_bite >= 0){
				/// wave 1 is the FLOOR: it must not be trivial.  Everything
				/// else is the ceiling test: it must be survivable.
				if(_w <= 1) _verdict = (_bite >= 0.35) ? "ok" : "LOW";
				else        _verdict = (_bite <= 0.90) ? "ok" : "HIGH";
			}

			_lines[array_length(_lines)] = scr_meta_log("CURVE",
			    _row.region, "-", _row.stage, " ", _drow.name,
			    "  w", _w, (_is_boss ? " BOSS" : ""),
			    "  ", _dem.count, "x ", round(_dem.hp), "hp",
			    "  req ", round(_dem.req * 10) / 10,
			    "  bite ", round(_bite * 100) / 100, "  ", _verdict);
		}
	}

	/// hand the same lines to the Draw GUI event (scr_curve_draw)
	curve_lines = _lines;
}
