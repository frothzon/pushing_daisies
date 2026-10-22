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
/// WHY SIX UNTIL NOW: Phase 1 shipped the four starters plus two unlocks
/// that need no new mechanic.  Chillip (slow), Bindweed (root), Belladonna
/// Blitz (poison) and Thornamental (crit) each need the status system, so
/// building them first would have meant building them twice (roadmap 5.2).
/// That system is scr_status, and the four arrive one at a time on top of
/// it - Chillip first, because a slow is the one status a player can SEE
/// without being told what it is: the monster is still walking, and it is
/// visibly late.  Their art already existed (spr_chillip_*, spr_bella_*,
/// spr_bindweed_*, spr_thornamental_*).
///
/// NO TOWER IS A PLACEHOLDER ANY MORE (2026-10-21).  The last two - Cannon
/// Tulip and Meat Bulb - borrowed another tower's trio at half size, and the
/// art drop replaced them with spr_tulip_*_192x and spr_meatbulb_*_192x, which
/// are 192x192 with their art bottom 20px below the origin.  That 20 is the
/// number that makes a tower stand on its row: Daisy is 21, Mandrake 22,
/// Belladonna 24, Pina 16 - see the feet check in art_descriptions 3.1.  So
/// these two now draw at the same size as every other tower instead of at
/// two-thirds of it, which is the only visible change the swap makes.

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
		/// ---- REPRICED 2026-10-13 (economy-prices-rebalance) ------------------
		/// The ladder was 5 / 15 / 45 / 100 - a 3x-then-3x-then-2.2x climb against
		/// an income that starts at $30 a wave, so the $45 and $100 towers arrived
		/// on waves 9 and 12 of 15.  The second half of the roster was a one-wave
		/// decision, which is why the measurable ladder was really "Daisy, then
		/// Ivy".  At 5 / 10 / 20 / 40 all four starters are affordable by wave 6 and
		/// every rung is a decision the player can actually make.
		///
		/// This compresses the roster against the wave curve on purpose: the curve
		/// that goes with it is FITTED by the sim, not guessed (economy.md 4.1,
		/// balance-fit-from-sim).
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

		/// ---- the two Phase 1 unlocks: pure stat changes, no status effect,
		///      so they do not need Phase 2 (roadmap 5.2)
		///
		///      ART: their own trios since 2026-10-21 (spr_tulip_*_192x,
		///      spr_meatbulb_*_192x).  The cost/rate/range numbers below are
		///      unchanged by that - only the picture moved.
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
		             15, scr_towerData( 90,   8,   1.5, _eff_puff,   1), 30, 1)
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

/// ---- TRAITS: the half of a tower that is NOT a number ------------------
/// scr_towerData holds what every tower has (range, damage, rate, targets),
/// so a rung of the ladder can be computed from it.  A trait is what only
/// some towers have - a status on hit, a crit chance - and it is kept in its
/// own table for two reasons:
///
///   1. the balance tester parses scr_towerData calls out of this file and
///      knows they take exactly five arguments (LL-038: the tables are the
///      thing that must not drift), and
///   2. a trait belongs to a NAMED tower, not to a data array, so an
///      upgrade rung cannot accidentally multiply it (a crit chance that
///      scales with the damage ladder is how every tower becomes the same
///      tower).
///
/// A tower with no row here simply has no trait; every reader asks through
/// tower_trait_get() and gets the default, so silence is the normal case.
function tower_trait_table() {
	return [
		/// name          crit   status         mult   seconds
		{ name : "Chillip",
		  crit : 0.00,
		  status : STATUS.SLOW,     /// scr_status: one instance per monster
		  mult : 0.55,              /// 55% of the monster's own speed
		  seconds : 1.5 }           /// longer than its 0.67s period, so a
		                            /// Chillip that keeps its target keeps it
		                            /// slowed; a lapse is 0.15s of full speed
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
