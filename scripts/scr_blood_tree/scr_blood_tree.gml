/// @description Blood Alchemy's five permanent, sequential nodes (economy.md §5.2).

function blood_tree_nodes() {
	return [
		{ id:"blood_magnet", tier:1, name:"Blood Magnet", label:ui_text("blood_node_blood_magnet_name"), ranks:1, cost:2,
		  desc:ui_text("blood_node_blood_magnet_desc"), pity_fill:0.10 },
		{ id:"hemorrhagic_harvest", tier:2, name:"Hemorrhagic Harvest", label:ui_text("blood_node_hemorrhagic_harvest_name"), ranks:1, cost:4,
		  desc:ui_text("blood_node_hemorrhagic_harvest_desc"), pity_fill:0.25 },
		{ id:"crimson_appetite", tier:3, name:"Crimson Appetite", label:ui_text("blood_node_crimson_appetite_name"), ranks:1, cost:8,
		  desc:ui_text("blood_node_crimson_appetite_desc"), elite_extra:0.10 },
		{ id:"blood_moon", tier:4, name:"Blood Moon", label:ui_text("blood_node_blood_moon_name"), ranks:1, cost:12,
		  desc:ui_text("blood_node_blood_moon_desc"), moon_chance:0.10,
		  moon_fill:1.0 },
		{ id:"crimson_garden", tier:5, name:"Crimson Garden", label:ui_text("blood_node_crimson_garden_name"), ranks:1, cost:20,
		  desc:ui_text("blood_node_crimson_garden_desc"), content:true }
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
	_bonus += candy_active_magnitude("pity_fill");
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

/// Garden Book view state is session-only: Clover, Blood, Candy, then Mastery.
function garden_view_mode() {
	var _mode = 0;
	if(variable_global_exists("garden_view_mode") && is_real(global.garden_view_mode)){
		_mode = clamp(floor(global.garden_view_mode),0,3);
	} else if(variable_global_exists("garden_blood_view")
	&& is_bool(global.garden_blood_view) && global.garden_blood_view){
		_mode = 1;
	}
	if(meta_garden_tab_unlocked(_mode)) return _mode;
	for(var _i = 0; _i < 4; _i++){
		if(meta_garden_tab_unlocked(_i)){
			global.garden_view_mode = _i;
			global.garden_blood_view = (_i == 1);
			return _i;
		}
	}
	return 0;
}

function garden_blood_view() { return garden_view_mode() == 1; }
function garden_candy_view() { return garden_view_mode() == 2; }
function garden_mastery_view() { return garden_view_mode() == 3; }

function garden_candy_page_get() {
	if(!variable_global_exists("garden_candy_page") || !is_real(global.garden_candy_page)) return 0;
	return clamp(floor(global.garden_candy_page),0,1);
}

function garden_visible_nodes() {
	if(garden_candy_view()) return candy_recipe_table();
	if(garden_blood_view()) return blood_tree_nodes();
	if(garden_mastery_view()) return clover_master_nodes();
	return clover_nodes(clover_branch_key());
}

function garden_candy_detail_open() {
	if(!variable_global_exists("garden_candy_detail_open")) return false;
	return is_bool(global.garden_candy_detail_open) && global.garden_candy_detail_open;
}
