/// @description Monster animation slots, timing, and shared helpers.
///
/// Spawn rows use [walk, idle, attack, die]. scr_mon_roster owns named rig
/// lookup; never index sprite_array directly (LL-079, LL-081). Missing art
/// returns -1 and keeps the current sprite; missing die art logs a warning.
/// Sprite origins already place feet on the ground, so helpers never move art.

/// The four slots of a rig, in the order scr_setupSpawning writes them.
enum ZOMB_ANIM { walk, idle, attack, die }

/// How long one cycle of the walking / idling animation takes, in seconds.
/// A duration, not an image_speed: scr_animSpeedForSeconds turns it into a
/// speed from the sprite's OWN frame count, so re-drawing a rig cannot change
/// how fast it plays (LL-030).
#macro ZOMB_CYCLE_SECS 1.0

/// How long a monster grows from the ground before it can walk. Kept as
/// one real second at normal and fast-forward speeds (LL-055).
#macro ZOMB_EMERGE_SECS 1.0

/// How long the corpse lies on the ground.  The die sprite is played at
/// exactly this duration, and the destroy is this same number - so the
/// monster disappears when its animation ends rather than after a delay
/// that was tuned beside it (LL-040's shape: one number, one reader).
#macro ZOMB_DIE_SECS   0.8

/// Is this instance a corpse that has not finished dying?  True for anything
/// that is not a live monster instance, so a caller can `continue` on it.
///
/// Read inside with(), because `dying` is ANOTHER instance's variable
/// (AGENTS.md 1 rule 6) - and guarded with variable_instance_exists, because
/// a monster built before this flag existed is exactly the kind of thing a
/// save/reload or a second build can produce.
function zomb_is_dying(_inst) {
	if(!scr_isValidInstance(_inst)) return true;

	var _out = false;
	with(_inst){
		if(variable_instance_exists(id, "dying")) _out = dying;
	}
	return _out;
}

/// Log every slot through the same named lookup used by monsters. Missing
/// sprites are guarded because sprite_get_name(-1) is fatal (LL-012).
function zomb_bank_report(_bank, _tag) {
	if(!is_array(_bank)) return "";
	if(!is_string(_tag)) _tag = "bank";

	var _txt = "";
	for(var _b = 0; _b < array_length(_bank); _b++){
		var _row = _bank[_b],
		    _p   = "none";

		if(is_array(_row) && array_length(_row) > MON.portrait
		&& sprite_exists(_row[MON.portrait])){
			_p = sprite_get_name(_row[MON.portrait]);
		}

		_txt += (_b > 0 ? " | " : "") + string(_b) + "="
		        + mon_rig_report(mon_rig_from_row(_row, _tag))
		        + " portrait=" + _p;
	}

	scr_meta_log("LEVEL", _tag, " bank: ", _txt);
	return _txt;
}
