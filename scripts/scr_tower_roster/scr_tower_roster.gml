/// @description Tower content, unlocks, loadouts, and non-numeric traits.
///
/// The roster is all available content; a loadout is the player's four chosen
/// tower names. Unlock gates are enforced before a tower reaches the shop.
/// Sprite trios share the 192x192, feet-at-origin contract (art_descriptions §3.1).

/// One tower.  `unlock` is the seed cost (0 = a free starter) and `gate` is
/// the region that must be fully cleared before it can be bought (0 = none).
function tower_entry(_name, _sprites, _price, _data, _unlock, _gate){
	return {
		name    : _name,
		sprites : _sprites,
		price   : _price,
		data    : _data,
		unlock  : _unlock,
		gate    : _gate
	};
}

/// The four free starters always fill a new save's loadout (goal.md §3.1).
function tower_roster() {
	return [
		/// Starters: cheap DPS, damage over time, multi-target, and area damage.
		tower_entry("Daisy Pusher",
		            [spr_daisy_idle_192x, spr_daisy_attack_192x, spr_daisy_return_192x],
		              5, scr_towerData(100,   4,    3, _eff_puff,   1),  0, 0),
		tower_entry("Burning Ivy",
		            [spr_ivy_idle_192x, spr_ivy_attack_192x, spr_ivy_return_192x],
		             10, scr_towerData( 80,  40,    2, _eff_acid,   1),  0, 0),
		tower_entry("Slender Mandrake",
		            [spr_mandrake_idle_192x, spr_mandrake_attack_192x, spr_mandrake_return_192x],
		             20, scr_towerData(125, 100,    0.35, _eff_spikes, 3),  0, 0),
		tower_entry("Pina Collider",
		            [spr_pina_idle_192x, spr_pina_attack_192x, spr_pina_return_192x],
		             40, scr_towerData( 75, 250,    0.10, _eff_xplod, 10),  0, 0),

		/// Phase 1 unlocks use stats only; no status system is required.
		tower_entry("Cannon Tulip",
		            [spr_tulip_idle_192x, spr_tulip_attack_192x, spr_tulip_return_192x],
		             60, scr_towerData(200,  60,  0.5, _eff_xplod,  5), 25, 1),
		tower_entry("Meat Bulb",
		            [spr_meatbulb_idle_192x, spr_meatbulb_attack_192x, spr_meatbulb_return_192x],
		             80, scr_towerData( 90, 250, 0.75, _eff_spikes, 1), 40, 1),

		/// ---- the Phase 2 tower: a slow, and the first one -----------------
		///      Cheap on purpose ($15, one target, 12 nominal DPS) because a
		///      control tower is bought for what it does to the OTHER towers'
		///      shots: everything on the route gets 1.8x longer to fire at it.
		///      Its numbers are deliberately not a damage ladder - see
		///      tower_trait_table() for the half of the tower that is not in
		///      scr_towerData.
		tower_entry("Chillip",
		            [spr_chillip_idle_192x, spr_chillip_attack_192x, spr_chillip_return_192x],
		             15, scr_towerData( 90,   8,   1.5, _eff_puff,   1), 30, 1),
		tower_entry("Bindweed",
		            [spr_bindweed_idle_192x, spr_bindweed_attack_192x, spr_bindweed_return_192x],
		             40, scr_towerData( 70,   5,   1.0, _eff_puff,   2), 50, 1),
		tower_entry("Belladonna Blitz",
		            [spr_bella_idle_192x, spr_bella_attack_192x, spr_bella_return_192x],
		             55, scr_towerData( 85,  12,   4.0, _eff_acid,   2), 150, 2)
	];
}

/// Find a roster entry by name.  Returns undefined when there is no such
/// tower, so a caller can guard instead of crashing (LL-002).
function tower_entry_find(_name) {
	if(!is_string(_name)) return undefined;
	var _all = tower_roster();
	for(var _i = 0; _i < array_length(_all); _i++){
		if(_all[_i].name == _name) return _all[_i];
	}
	return undefined;
}

/// A fresh copy of a tower's data array.
///
/// Always copied: scr_placeTower duplicates it into the instance, and handing
/// the roster's own array out instead would let one placed tower's upgrade
/// leak into every tower placed afterwards.
function tower_data_copy(_name) {
	var _e = tower_entry_find(_name);
	if(is_undefined(_e)) return undefined;
	return array_duplicate(_e.data);
}

/// Named traits stay outside scr_towerData's five-argument balance contract
/// and are never scaled by upgrades (LL-038). tower_trait_get() supplies
/// defaults for towers without a row.
function tower_trait_table() {
	return [
		{ name : "Chillip",
		  crit : 0.00,
		  statuses : [
			{ kind : STATUS.SLOW, chance : 1.00, mult : 0.55, amount : 0, seconds : 1.5 },
			{ kind : STATUS.STUN, chance : 0.05, mult : 1.00, amount : 0, seconds : 1.0 }
		  ] },
		{ name : "Burning Ivy",
		  crit : 0.00,
		  statuses : [
			{ kind : STATUS.BURN, chance : 0.20, mult : 1.00, amount : 10, seconds : 3.0 }
		  ] },
		{ name : "Bindweed",
		  crit : 0.00,
		  statuses : [
			{ kind : STATUS.ROOT, chance : 0.30, mult : 1.00, amount : 0, seconds : 1.0 }
		  ] },
		{ name : "Belladonna Blitz",
		  crit : 0.00,
		  statuses : [
			{ kind : STATUS.POISON, chance : 0.20, mult : 1.00, amount : 3, seconds : 5.0 }
		  ] }
	];
}


/// One tower's trait row, or undefined - the same contract as
/// tower_entry_find(), so a caller can guard instead of crashing (LL-002).
function tower_trait_find(_name) {
	if(!is_string(_name)) return undefined;
	var _all = tower_trait_table();
	for(var _i = 0; _i < array_length(_all); _i++){
		if(_all[_i].name == _name) return _all[_i];
	}
	return undefined;
}

/// One field of a tower's traits, or a default.  This is the ONLY reader:
/// a struct field that was never written is an error, not an undefined, so
/// no caller touches a raw key (the face of LL-002 that bites hardest).
function tower_trait_get(_name, _key, _default) {
	var _t = tower_trait_find(_name);
	if(!is_struct(_t)) return _default;
	if(!is_string(_key)) return _default;
	if(!variable_struct_exists(_t, _key)) return _default;
	return _t[$ _key];
}

/// Normalized on-hit effects for one tower. Enum kinds are validated by
/// switch, never is_real (LL-083); every numeric field has a safe default.
function tower_trait_statuses(_name) {
	var _raw = tower_trait_get(_name, "statuses", []),
	    _out = [];
	if(!is_array(_raw)) return _out;
	for(var _i = 0; _i < array_length(_raw); _i++){
		var _s = _raw[_i];
		if(!is_struct(_s) || !variable_struct_exists(_s, "kind")) continue;
		var _known = false;
		switch(_s.kind){
			case STATUS.SLOW:   _known = true; break;
			case STATUS.STUN:   _known = true; break;
			case STATUS.BURN:   _known = true; break;
			case STATUS.POISON: _known = true; break;
			case STATUS.ROOT:   _known = true; break;
			case STATUS.BLEED:  _known = true; break;
			case STATUS.VULN:   _known = true; break;
		}
		if(!_known) continue;
		var _chance = variable_struct_exists(_s, "chance") && is_real(_s.chance)
		              ? clamp(_s.chance, 0, 1) : 0,
		    _mult = variable_struct_exists(_s, "mult") && is_real(_s.mult)
		            ? clamp(_s.mult, 0, 4) : 1,
		    _amount = variable_struct_exists(_s, "amount") && is_real(_s.amount)
		              ? max(0, _s.amount) : 0,
		    _seconds = variable_struct_exists(_s, "seconds") && is_real(_s.seconds)
		               ? max(0, _s.seconds) : 0;
		if(_chance <= 0 || _seconds <= 0) continue;
		_out[array_length(_out)] = {
			kind : _s.kind, chance : _chance, mult : _mult,
			amount : _amount, seconds : _seconds
		};
	}
	return _out;
}

/// The roster indices that make up the current loadout, in loadout order.
/// A name that is not in the roster is skipped rather than crashing, because
/// a save written by a future build could name a tower this build lacks.
function tower_roster_of_loadout(_loadout) {
	var _out = [];
	if(!is_array(_loadout)) return _out;
	for(var _i = 0; _i < array_length(_loadout); _i++){
		var _e = tower_entry_find(_loadout[_i]);
		if(is_struct(_e)){
			_out[array_length(_out)] = _e;
		}
	}
	return _out;
}
