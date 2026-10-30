/// @description Blood Alchemy's five permanent, sequential nodes (economy.md §5.2).

function blood_tree_nodes() {
	return [
		{ id:"blood_magnet", tier:1, name:"Blood Magnet", label:"Blood Magnet", ranks:1, cost:2,
		  desc:"Pity progress fills 10% faster", pity_fill:0.10 },
		{ id:"hemorrhagic_harvest", tier:2, name:"Hemorrhagic Harvest", label:"Hemorrhagic Harvest", ranks:1, cost:4,
		  desc:"Pity progress fills 25% faster", pity_fill:0.25 },
		{ id:"crimson_appetite", tier:3, name:"Crimson Appetite", label:"Crimson Appetite", ranks:1, cost:8,
		  desc:"Elites have a 10% extra-shard chance", elite_extra:0.10 },
		{ id:"blood_moon", tier:4, name:"Blood Moon", label:"Blood Moon", ranks:1, cost:12,
		  desc:"10% chance per wave to double pity fill", moon_chance:0.10,
		  moon_fill:1.0 },
		{ id:"crimson_garden", tier:5, name:"Crimson Garden", label:"Crimson Garden", ranks:1, cost:20,
		  desc:"Unlocks special Blood Shard content", content:true }
	];
}

function blood_node_find(_id) {
	if(!is_string(_id)) return undefined;
	var _nodes = blood_tree_nodes();
	for(var _i = 0; _i < array_length(_nodes); _i++){
		if(_nodes[_i].id == _id) return _nodes[_i];
	}
	return undefined;
}

function blood_node_rank(_id) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	if(!variable_struct_exists(global.meta,"blood_nodes")
	|| !is_struct(global.meta.blood_nodes)) return 0;
	if(!variable_struct_exists(global.meta.blood_nodes,_id)) return 0;
	var _rank = global.meta.blood_nodes[$ _id];
	if(!is_real(_rank)) return 0;
	return clamp(floor(_rank),0,1);
}

function blood_node_unlocked(_id) {
	var _node = blood_node_find(_id);
	if(!is_struct(_node)) return false;
	if(_node.tier <= 1) return true;
	var _nodes = blood_tree_nodes(),
	    _previous = _nodes[_node.tier-2];
	return blood_node_rank(_previous.id) > 0;
}

function blood_node_cost(_id) {
	var _node = blood_node_find(_id);
	if(!is_struct(_node) || blood_node_rank(_id) > 0) return -1;
	return _node.cost;
}

function blood_node_buy(_id) {
	var _node = blood_node_find(_id);
	if(!is_struct(_node) || !blood_node_unlocked(_id)) return false;
	var _cost = blood_node_cost(_id);
	if(_cost < 1 || !shards_spend(_cost)) return false;
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return false;
	if(!is_struct(global.meta[$ "blood_nodes"])) global.meta[$ "blood_nodes"] = {};
	global.meta[$ "blood_nodes"][$ _id] = 1;
	scr_meta_log("SHARD","blood node ",_node.name," unlocked cost=",_cost,
	             " shards=",shards_get());
	return true;
}

/// The two pity nodes share one additive axis with Blood Orange once candy is
/// implemented. They advance effective pity progress, not the tiny base rate.
function blood_pity_fill_bonus() {
	var _bonus = 0;
	if(blood_node_rank("blood_magnet") > 0) _bonus += 0.10;
	if(blood_node_rank("hemorrhagic_harvest") > 0) _bonus += 0.25;
	return _bonus;
}

function blood_elite_bonus_chance() {
	if(blood_node_rank("crimson_appetite") <= 0) return 0;
	return 0.10;
}

function blood_moon_chance() {
	if(blood_node_rank("blood_moon") <= 0) return 0;
	return 0.10;
}

function blood_moon_fill_bonus() {
	if(blood_node_rank("blood_moon") <= 0) return 0;
	return 1.0;
}

function blood_content_unlocked() {
	return blood_node_rank("crimson_garden") > 0;
}

/// The Garden Book shares its existing node wall between the clover branch and
/// Blood Alchemy. This UI-only state is not part of account progression.
function garden_blood_view() {
	if(!variable_global_exists("garden_blood_view")) return false;
	return is_bool(global.garden_blood_view) && global.garden_blood_view;
}

function garden_visible_nodes() {
	if(garden_blood_view()) return blood_tree_nodes();
	return clover_nodes();
}
