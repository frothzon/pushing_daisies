/// @description Four permanent clover trees: ten nodes, five ranks per node.
/// Costs and effect assumptions are recorded in economy.md §3.2.

function clover_node(_branch, _id, _label, _cost, _effects, _desc) {
	return {
		branch : _branch,
		id     : _id,
		label  : _label,
		ranks  : 5,
		costs  : [_cost,_cost,_cost,_cost,_cost],
		effects: _effects,
		desc   : _desc
	};
}

function clover_branch_table() {
	return [
		{ id:"vitality", label:"Vitality", icon:BRANCH.VITALITY },
		{ id:"offense",  label:"Offense",  icon:BRANCH.OFFENSE  },
		{ id:"growth",   label:"Growth",   icon:BRANCH.GROWTH   },
		{ id:"harvest",  label:"Harvest",  icon:BRANCH.HARVEST  }
	];
}

function clover_branch_index() {
	if(variable_global_exists("garden_clover_branch") && is_real(global.garden_clover_branch)){
		return clamp(floor(global.garden_clover_branch),0,3);
	}
	return 1;
}

function clover_branch_key() {
	var _branches=clover_branch_table();
	return _branches[clover_branch_index()].id;
}

function clover_branch_name() {
	var _branches=clover_branch_table();
	return _branches[clover_branch_index()].label;
}

function clover_branch_icon() {
	var _branches=clover_branch_table();
	return _branches[clover_branch_index()].icon;
}

function clover_branch_cycle() {
	global.garden_clover_branch=(clover_branch_index()+1) mod 4;
	global.garden_clover_page=0;
	return clover_branch_key();
}

function clover_page_get() {
	if(!variable_global_exists("garden_clover_page") || !is_real(global.garden_clover_page)) return 0;
	return clamp(floor(global.garden_clover_page),0,1);
}

function clover_page_cycle() {
	global.garden_clover_page=1-clover_page_get();
	return clover_page_get();
}

function clover_nodes(_branch) {
	switch(_branch){
		case "vitality": return [
			clover_node("vitality","vit_life_1","Life I",5,{max_life:1},"+1 maximum life per rank"),
			clover_node("vitality","vit_life_2","Life II",8,{max_life:1},"+1 maximum life per rank"),
			clover_node("vitality","vit_life_3","Life III",12,{max_life:1},"+1 maximum life per rank"),
			clover_node("vitality","vit_life_4","Life IV",18,{max_life:1},"+1 maximum life per rank"),
			clover_node("vitality","vit_life_5","Life V",25,{max_life:1},"+1 maximum life per rank"),
			clover_node("vitality","vit_fortitude","Fortitude",35,{life_loss_reduction:0.05},"Prevent 5% of leak life loss per rank"),
			clover_node("vitality","vit_regen","Regeneration",50,{regen_per_five_waves:1},"Restore 1 life per 5 waves per rank"),
			clover_node("vitality","vit_boss_ward","Boss Ward",70,{boss_saves:1},"Prevent 1 boss leak per stage per rank"),
			clover_node("vitality","vit_last_stand","Last Stand",100,{max_life:1},"+1 maximum life per rank"),
			clover_node("vitality","vit_deep_roots","Deep Roots",150,{max_life:2},"+2 maximum life per rank")
		];
		case "offense": return [
			clover_node("offense","off_damage","Tower Damage I",5,{damage:0.004},"+0.4% tower damage per rank"),
			clover_node("offense","off_damage_2","Tower Damage II",8,{damage:0.004},"+0.4% tower damage per rank"),
			clover_node("offense","off_damage_3","Tower Damage III",12,{damage:0.004},"+0.4% tower damage per rank"),
			clover_node("offense","off_damage_4","Tower Damage IV",18,{damage:0.004},"+0.4% tower damage per rank"),
			clover_node("offense","off_damage_5","Tower Damage V",25,{damage:0.004},"+0.4% tower damage per rank"),
			clover_node("offense","off_firerate","Fire Rate",35,{fire_rate:0.01},"+1% fire rate per rank"),
			clover_node("offense","off_crit_chance","Critical Chance",50,{crit_chance:0.01},"+1% critical chance per rank"),
			clover_node("offense","off_crit_damage","Critical Damage",70,{crit_damage:0.05},"+5% critical damage per rank"),
			clover_node("offense","off_damage_9","Focused Force",100,{damage:0.02},"+2% tower damage per rank"),
			clover_node("offense","off_damage_10","Final Flourish",150,{damage:0.03},"+3% tower damage per rank")
		];
		case "growth": return [
			clover_node("growth","growth_discount_1","Economy I",5,{upgrade_discount:0.01},"-1% upgrade cost per rank"),
			clover_node("growth","growth_discount_2","Economy II",8,{upgrade_discount:0.01},"-1% upgrade cost per rank"),
			clover_node("growth","growth_discount_3","Economy III",12,{upgrade_discount:0.01},"-1% upgrade cost per rank"),
			clover_node("growth","growth_discount_4","Economy IV",18,{upgrade_discount:0.01},"-1% upgrade cost per rank"),
			clover_node("growth","growth_discount_5","Economy V",25,{upgrade_discount:0.01},"-1% upgrade cost per rank"),
			clover_node("growth","growth_kill_money","Green Returns",35,{kill_money:0.03},"+3% kill money per rank"),
			clover_node("growth","growth_spec_tier","Master Gardener",50,{spec_tier:1,specialization_bonus:0.01},"Unlock tier 3 at L4; +1% spec strength per rank"),
			clover_node("growth","growth_master_discount_1","Mastery Bargain I",70,{master_discount:0.02},"-2% master node cost per rank"),
			clover_node("growth","growth_master_discount_2","Mastery Bargain II",100,{master_discount:0.04},"-4% master node cost per rank"),
			clover_node("growth","growth_start_money","Early Bloom",150,{starting_money:2},"+2 starting money per rank")
		];
		case "harvest": return [
			clover_node("harvest","harvest_money_1","Bounty I",5,{kill_money:0.01},"+1% zombie money per rank"),
			clover_node("harvest","harvest_money_2","Bounty II",8,{kill_money:0.01},"+1% zombie money per rank"),
			clover_node("harvest","harvest_money_3","Bounty III",12,{kill_money:0.01},"+1% zombie money per rank"),
			clover_node("harvest","harvest_money_4","Bounty IV",18,{kill_money:0.01},"+1% zombie money per rank"),
			clover_node("harvest","harvest_money_5","Bounty V",25,{kill_money:0.01},"+1% zombie money per rank"),
			clover_node("harvest","harvest_start_money","Full Purse",35,{starting_money:1},"+1 starting money per rank"),
			clover_node("harvest","harvest_boss_money","Boss Bounty",50,{boss_reward:0.05},"+5% boss reward per rank"),
			clover_node("harvest","harvest_seeds_1","Seed Finder I",70,{seed_reward:0.01},"+1% seed rewards per rank"),
			clover_node("harvest","harvest_seeds_2","Seed Finder II",100,{seed_reward:0.02},"+2% seed rewards per rank"),
			clover_node("harvest","harvest_seeds_3","Seed Finder III",150,{seed_reward:0.03},"+3% seed rewards per rank")
		];
	}
	return [];
}

function clover_all_nodes() {
	var _out=[], _branches=clover_branch_table();
	for(var _b=0; _b<array_length(_branches); _b++){
		var _nodes=clover_nodes(_branches[_b].id);
		for(var _i=0; _i<array_length(_nodes); _i++) _out[array_length(_out)]=_nodes[_i];
	}
	return _out;
}

function clover_node_find(_id) {
	if(!is_string(_id)) return undefined;
	var _all=clover_all_nodes();
	for(var _i=0; _i<array_length(_all); _i++) if(_all[_i].id == _id) return _all[_i];
	return undefined;
}

function clover_rank(_id) {
	if(!is_string(_id) || !variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	if(!variable_struct_exists(global.meta,"clover_nodes") || !is_struct(global.meta[$ "clover_nodes"])) return 0;
	var _owned=global.meta[$ "clover_nodes"];
	if(!variable_struct_exists(_owned,_id)) return 0;
	var _rank=_owned[$ _id];
	if(!is_real(_rank)) return 0;
	var _node=clover_node_find(_id);
	if(!is_struct(_node)) return 0;
	return clamp(floor(_rank),0,_node.ranks);
}

function clover_cost(_id) {
	var _node=clover_node_find(_id);
	if(!is_struct(_node)) return -1;
	var _rank=clover_rank(_id);
	if(_rank >= _node.ranks) return -1;
	return _node.costs[_rank];
}

function clover_buy(_id) {
	var _cost=clover_cost(_id);
	if(_cost < 0 || !clovers_spend(_cost)) return false;
	if(!is_struct(global.meta[$ "clover_nodes"])) global.meta[$ "clover_nodes"]={};
	global.meta[$ "clover_nodes"][$ _id]=clover_rank(_id)+1;
	scr_meta_log("CLOVER","node ",_id," rank=",clover_rank(_id)," cost=",_cost);
	return true;
}

function clover_effect_bonus(_field) {
	if(!is_string(_field)) return 0;
	var _sum=0, _all=clover_all_nodes();
	for(var _i=0; _i<array_length(_all); _i++){
		var _node=_all[_i], _rank=clover_rank(_node.id);
		if(_rank <= 0 || !is_struct(_node.effects)) continue;
		if(!variable_struct_exists(_node.effects,_field)) continue;
		var _value=_node.effects[$ _field];
		if(is_real(_value)) _sum += _value*_rank;
	}
	return _sum;
}

function clover_bonus(_id) {
	var _node=clover_node_find(_id);
	if(!is_struct(_node) || !is_struct(_node.effects)) return 0;
	var _keys=variable_struct_get_names(_node.effects);
	if(array_length(_keys) == 0) return 0;
	var _value=_node.effects[$ _keys[0]];
	return is_real(_value) ? _value*clover_rank(_id) : 0;
}

function clover_damage_bonus() { return clover_effect_bonus("damage"); }
function clover_firerate_bonus() { return clover_effect_bonus("fire_rate"); }
function clover_crit_chance_bonus() { return clover_effect_bonus("crit_chance"); }
function clover_crit_damage_bonus() { return clover_effect_bonus("crit_damage"); }
function clover_upgrade_discount() { return clamp(clover_effect_bonus("upgrade_discount"),0,0.25); }
function clover_kill_money_bonus() { return clover_effect_bonus("kill_money"); }
function clover_starting_money_bonus() { return clover_effect_bonus("starting_money"); }
function clover_boss_reward_bonus() { return clover_effect_bonus("boss_reward"); }
function clover_seed_reward_bonus() { return clover_effect_bonus("seed_reward"); }
function clover_max_life_bonus() { return max(0,floor(clover_effect_bonus("max_life"))); }
function clover_life_loss_reduction() { return clamp(clover_effect_bonus("life_loss_reduction"),0,0.25); }
function clover_regen_amount() { return max(0,floor(clover_effect_bonus("regen_per_five_waves"))); }
function clover_boss_saves() { return max(0,floor(clover_effect_bonus("boss_saves"))); }
function clover_master_discount() { return clamp(clover_effect_bonus("master_discount"),0,0.30); }
function clover_specialization_bonus() { return clamp(clover_effect_bonus("specialization_bonus"),0,0.05); }

function clover_wave_regen(_wave) {
	if(!is_real(_wave) || _wave < 1 || _wave mod 5 != 0) return 0;
	return clover_regen_amount();
}


/// The five account-wide floor/cap purchases (economy.md §3.3).
function clover_master_nodes() {
	return [
		{ id:"mastery_1", rank:1, label:"Garden Mastery I", region:1, cost:120, desc:"Towers arrive at level 2; cap 6" },
		{ id:"mastery_2", rank:2, label:"Garden Mastery II", region:2, cost:260, desc:"Towers arrive at level 3; cap 7" },
		{ id:"mastery_3", rank:3, label:"Garden Mastery III", region:3, cost:500, desc:"Towers arrive at level 4; cap 8" },
		{ id:"mastery_4", rank:4, label:"Garden Mastery IV", region:4, cost:900, desc:"Towers arrive at level 5; cap 9" },
		{ id:"mastery_5", rank:5, label:"Garden Mastery V", region:5, cost:1500, desc:"Towers arrive at level 6; cap 10" }
	];
}

function clover_master_node_find(_id) {
	if(!is_string(_id)) return undefined;
	var _all=clover_master_nodes();
	for(var _i=0; _i<array_length(_all); _i++){
		if(_all[_i].id == _id) return _all[_i];
	}
	return undefined;
}

function clover_master_node_cost(_id) {
	var _node=clover_master_node_find(_id);
	if(!is_struct(_node) || _node.rank <= tower_mastery()) return -1;
	var _discount=clover_master_discount();
	return max(1,round(_node.cost*(1-clamp(_discount,0,0.30))));
}

function clover_master_node_unlocked(_id) {
	var _node=clover_master_node_find(_id);
	if(!is_struct(_node) || _node.rank != tower_mastery()+1) return false;
	return region_cleared(_node.region);
}

function clover_master_node_buy(_id) {
	var _node=clover_master_node_find(_id),
	    _cost=clover_master_node_cost(_id);
	if(!is_struct(_node) || !clover_master_node_unlocked(_id)
	|| _cost < 1 || !variable_global_exists("meta")
	|| !is_struct(global.meta) || !clovers_spend(_cost)) return false;
	global.meta[$ "mastery"]=_node.rank;
	scr_meta_log("CLOVER","mastery ",_node.rank," cap=",5+_node.rank,
	             " floor=",1+_node.rank," cost=",_cost,
	             " clovers=",clovers_get());
	return true;
}
