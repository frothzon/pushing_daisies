/// @description  Garden Badges - the non-economic collectible (goal.md 25,
/// roadmap 1.8).
///
/// Badges buy nothing.  They exist so a completionist has something to chase
/// that does not touch the economy at all - which is the whole reason they
/// are not a fifth currency.
///
/// Seven per-stage medals, with the first three numeric keys preserved so
/// existing saves keep their meaning. Frugal and Speed Grower use the
/// stage thresholds in GameLevelData; the other awards read run counters.

enum BADGE { UNTOUCHED = 0, EXTERMINATOR = 1, BRUTALIST = 2, FRUGAL = 3, BOTANIST = 4, PURIST = 5, SPEED_GROWER = 6 };

function badge_count() { return 7; }

function badge_name(_b) {
	switch(_b){
		case BADGE.UNTOUCHED:    return "Untouched";
		case BADGE.FRUGAL:       return "Frugal";
		case BADGE.BOTANIST:     return "Botanist";
		case BADGE.PURIST:       return "Purist";
		case BADGE.EXTERMINATOR: return "Exterminator";
		case BADGE.SPEED_GROWER: return "Speed Grower";
		case BADGE.BRUTALIST:    return "Brutalist";
	}
	return "Badge " + string(_b);
}

function badge_desc(_b) {
	switch(_b){
		case BADGE.UNTOUCHED:    return "Clear without losing a life";
		case BADGE.FRUGAL:       return "Spend under the stage spend par";
		case BADGE.BOTANIST:     return "Place all four tower types";
		case BADGE.PURIST:       return "Use only one tower type";
		case BADGE.EXTERMINATOR: return "Kill every zombie without a forced clear";
		case BADGE.SPEED_GROWER: return "Clear before the stage time par";
		case BADGE.BRUTALIST:    return "Clear the stage on Brutal";
	}
	return "";
}

/// The save keys retain their old enum values; this is only presentation order.
function badge_display_at(_index) {
	switch(_index){
		case 0: return BADGE.UNTOUCHED;
		case 1: return BADGE.FRUGAL;
		case 2: return BADGE.BOTANIST;
		case 3: return BADGE.PURIST;
		case 4: return BADGE.EXTERMINATOR;
		case 5: return BADGE.SPEED_GROWER;
		case 6: return BADGE.BRUTALIST;
	}
	return -1;
}

/// Record gross in-run purchases. Selling never erases this history, so
/// buying and refunding towers cannot manufacture a Frugal badge.
function badge_record_purchase(_level, _amount, _tower_name) {
	if(is_undefined(_level) || !instance_exists(_level) || !is_real(_amount) || _amount <= 0) return false;
	if(!is_string(_tower_name)) _tower_name = "";
	with(_level){
		if(!variable_instance_exists(id,"level_money_spent") || !is_real(level_money_spent)){
			level_money_spent = 0;
		}
		level_money_spent += _amount;
		if(_tower_name != ""){
			if(!variable_instance_exists(id,"level_tower_types") || !is_struct(level_tower_types)){
				level_tower_types = {};
			}
			if(!variable_instance_exists(id,"level_tower_type_count") || !is_real(level_tower_type_count)){
				level_tower_type_count = 0;
			}
			if(!variable_instance_exists(id,"level_towers_placed") || !is_real(level_towers_placed)){
				level_towers_placed = 0;
			}
			level_towers_placed++;
			if(!variable_struct_exists(level_tower_types,_tower_name)){
				level_tower_types[$ _tower_name] = true;
				level_tower_type_count++;
			}
		}
	}
	return true;
}
function badge_key(_region, _stage, _b) {
	return stage_key(_region, _stage) + ":" + string(_b);
}

function badge_has(_region, _stage, _b) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return false;
	var _m = global.meta[$ "badges"];
	if(!is_struct(_m)) return false;
	return variable_struct_exists(_m, badge_key(_region, _stage, _b));
}

/// Award a badge.  Returns true only when it is NEW, so a caller can shout
/// "new badge" once instead of every time the stage is replayed.
function badge_award(_region, _stage, _b) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return false;
	if(badge_has(_region, _stage, _b)) return false;
	if(!is_struct(global.meta[$ "badges"])) global.meta[$ "badges"] = {};
	global.meta[$ "badges"][$ badge_key(_region, _stage, _b)] = true;
	scr_meta_log("BADGE", "earned '", badge_name(_b), "' on ", _region, "-", _stage);
	return true;
}

/// How many badges exist across the whole game, and how many are earned.
/// Used by the world map's collection line.
function badge_total_possible() {
	return badge_count() * stage_count();
}

function badge_total_earned() {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	var _m = global.meta[$ "badges"];
	if(!is_struct(_m)) return 0;
	/// not variable_struct_names_count(): this runtime predates it, and the
	/// length of the name array is the same answer
	return array_length(variable_struct_get_names(_m));
}
