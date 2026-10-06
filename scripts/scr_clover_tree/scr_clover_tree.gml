/// @description  The clover trees (economy.md 3.3, roadmap 1.7).
///
/// Phase 1 ships ONE branch - Offense - with two nodes in it.  The point of
/// the slice is to prove the *screen* and the *spend route*, not to fill four
/// trees; the other branches are content once the pattern exists (roadmap 1.7).
///
/// The two Offense nodes are deliberately the ones that need no system Phase 2
/// has not built yet.  Critical chance and critical damage would both be nodes
/// that do nothing until crit exists, and this phase's own gate says every
/// currency must be earnable AND spendable (roadmap 5.3).

/// One node: an id, a label, how many ranks it has, what each rank costs, and
/// the effect of one rank (as a fraction: 0.02 is +2%).
function clover_node(_id, _label, _ranks, _costs, _effect, _desc){
	return {
		id     : _id,
		label  : _label,
		ranks  : _ranks,
		costs  : _costs,
		effect : _effect,
		desc   : _desc
	};
}

function clover_nodes() {
	return [
		clover_node("off_damage",   "Tower Damage", 5, [5, 8, 12, 18, 25], 0.02,
		            "+2% damage per rank"),
		clover_node("off_firerate", "Fire Rate",    3, [5, 10, 16],        0.01,
		            "+1% fire rate per rank")
	];
}

function clover_node_find(_id) {
	var _all = clover_nodes();
	for(var _i = 0; _i < array_length(_all); _i++){
		if(_all[_i].id == _id) return _all[_i];
	}
	return undefined;
}

/// How many ranks of a node the player owns (0 when they own none, and 0
/// when the id is unknown - a node that does not exist has no ranks, which
/// is safer than throwing).
function clover_rank(_id) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	var _owned = global.meta[$ "clover_nodes"];
	if(!is_struct(_owned)) return 0;
	if(!variable_struct_exists(_owned, _id)) return 0;
	return _owned[$ _id];
}

/// The cost of the NEXT rank, or -1 when the node is maxed or unknown.
function clover_cost(_id) {
	var _n = clover_node_find(_id);
	if(is_undefined(_n)) return -1;
	var _r = clover_rank(_id);
	if(_r >= _n.ranks) return -1;
	return _n.costs[_r];
}

/// Buy the next rank.  Returns false when maxed or unaffordable, having
/// changed nothing.
function clover_buy(_id) {
	var _cost = clover_cost(_id);
	if(_cost < 0) return false;
	if(!clovers_spend(_cost)) return false;
	if(!is_struct(global.meta[$ "clover_nodes"])) global.meta[$ "clover_nodes"] = {};
	global.meta[$ "clover_nodes"][$ _id] = clover_rank(_id) + 1;
	scr_meta_log("CLOVER", "node ", _id, " rank=", clover_rank(_id), " cost=", _cost);
	return true;
}

/// The total bonus a node is currently giving, as a fraction.
function clover_bonus(_id) {
	var _n = clover_node_find(_id);
	if(is_undefined(_n)) return 0;
	return clover_rank(_id) * _n.effect;
}

/// Convenience readers for the level.
///
/// Phase 1 applies these to a tower's data once, when the tower is built.
/// Phase 2 replaces this with one resolver that folds level, specialization,
/// clovers, candy and auras together in a fixed order (see economy.md 4.3);
/// until then, one multiplication at placement is the whole pipeline, and it
/// is enough to prove that spending a clover changes what happens in a run.
function clover_damage_bonus()   { return clover_bonus("off_damage");   }
function clover_firerate_bonus() { return clover_bonus("off_firerate"); }
