/// @description  Garden Badges - the non-economic collectible (goal.md 25,
/// roadmap 1.8).
///
/// Badges buy nothing.  They exist so a completionist has something to chase
/// that does not touch the economy at all - which is the whole reason they
/// are not a fifth currency.
///
/// Phase 1 ships three of the seven.  The other four (Frugal, Botanist,
/// Purist, Speed Grower) are a data row and a flag each once this pattern
/// exists - Frugal and Speed Grower need the stage's `par_spend` / `par_time`,
/// which stage_data() already carries for exactly that reason.

enum BADGE { UNTOUCHED = 0, EXTERMINATOR, BRUTALIST };

function badge_count() { return 3; }

function badge_name(_b) {
	switch(_b){
		case BADGE.UNTOUCHED:    return "Untouched";
		case BADGE.EXTERMINATOR: return "Exterminator";
		case BADGE.BRUTALIST:    return "Brutalist";
	}
	return "Badge " + string(_b);
}

function badge_desc(_b) {
	switch(_b){
		case BADGE.UNTOUCHED:    return "Clear without losing a life";
		case BADGE.EXTERMINATOR: return "Let nothing reach the exit";
		case BADGE.BRUTALIST:    return "Clear the stage on Brutal";
	}
	return "";
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
