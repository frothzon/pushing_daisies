/// @description  The tower roster - every tower the game knows about, in one
/// place (roadmap 1.10).
///
/// Before this, the four towers were a literal array inside
/// objects/_levelControl/Create_0.gml, so "which towers exist" and "which
/// towers are in this run" were the same question.  They are not: the roster
/// is content (twelve towers by the end of Phase 5) and a *loadout* is the
/// four the player brought (goal.md 3.1).
///
/// So the level asks the roster for the loadout by name, and the shop draws
/// exactly that.  A tower the player has not unlocked cannot be in a loadout,
/// so it cannot reach the shop at all.
///
/// WHY ONLY SIX: Phase 1 ships the four starters plus two unlocks that need
/// no new mechanic.  Chillip (slow), Bindweed (root), Belladonna Blitz
/// (poison) and Thornamental (crit) each need a status system that does not
/// exist until Phase 2, so building them now would mean building them twice
/// (roadmap 5.2).

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

/// The roster.
///
/// The four starters are the towers the game already had, so "four free
/// towers" costs no new art, and it is what lets the Deploy screen always
/// fill all four slots on a brand new save (goal.md 3.1).
function tower_roster() {
	return [
		/// ---- the four starters: free, and between them they cover cheap DPS,
		///      damage over time, multi-target and area damage
		tower_entry("Daisy Pusher",
		            [spr_t1_idle, spr_t1_attack, spr_t1_return],
		              5, scr_towerData(100,   4,    3, _eff_puff,   1),  0, 0),
		tower_entry("Burning Ivy",
		            [spr_t2_idle, spr_t2_attack, spr_t2_return],
		             15, scr_towerData( 80,  40,    2, _eff_acid,   1),  0, 0),
		tower_entry("Slender Mandrake",
		            [spr_t4_idle, spr_t4_attack, spr_t4_return],
		             45, scr_towerData(125, 125,    1, _eff_spikes, 3),  0, 0),
		tower_entry("Pina Collider",
		            [spr_t3_idle, spr_t3_attack, spr_t3_return],
		            100, scr_towerData( 75, 200,    1, _eff_xplod, 10),  0, 0),

		/// ---- the two Phase 1 unlocks: pure stat changes, no status effect,
		///      so they do not need Phase 2 (roadmap 5.2)
		///
		///      ART: these borrow an existing sprite trio until roadmap 1.11
		///      draws spr_t5_* / spr_t6_*.  A placeholder is honest; a tower
		///      with no sprite at all is a fatal error (LL-012).
		tower_entry("Cannon Tulip",
		            [spr_t3_idle, spr_t3_attack, spr_t3_return],
		             60, scr_towerData(200,  60,  0.5, _eff_xplod,  5), 25, 1),
		tower_entry("Meat Bulb",
		            [spr_t4_idle, spr_t4_attack, spr_t4_return],
		             80, scr_towerData( 90, 250, 0.75, _eff_spikes, 1), 40, 1)
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
