/// @description  The monster RIG: which of a creature's four animations is
///               playing - and the ground is the sprite's ORIGIN, so nothing
///               in this file moves the art (LL-078).
///
/// WHY THIS FILE EXISTS
/// --------------------
/// Every creature ships four animations - walk, idle, attack, die - and a
/// monster used to be a single sprite: scr_zombie_emerge and scr_zombie_path
/// both wrote `sprite_array[0]` and there was nothing else to play.  Four
/// slots mean three new decisions (which slot, when to change it, how long a
/// cycle lasts), and a decision in two places is two answers.
///
/// THE SLOT ORDER IS THE CONTRACT.  `array(walk, idle, attack, die)` is what
/// scr_setupSpawning writes and what ZOMB_ANIM indexes, and walk is 0 so a row
/// still reads in its author's order.
///
/// THE READER IS scr_mon_roster NOW.  An index into an array copied onto every
/// instance was silent when it was wrong - `sprite_array[3]` on a row with two
/// slots answers -1, "change nothing" is a legal answer, and the corpse simply
/// kept the art it died in (LL-079, LL-081).  The slots are asked for BY NAME
/// on a rig struct instead, and a rig with no die sheet says so out loud.  This
/// file keeps the ORDER and the two durations; the lookup lives there.
///
/// A ROW THAT HAS NO ART STILL WORKS, on purpose.  A slot that is missing
/// answers -1 and the monster keeps the art it had, because a one-slot row is
/// legal for art that has not landed yet.  What is no longer allowed is a row
/// that HAS the art and does not pass it: that is a test failure now, and a
/// WARNING in the log at the first corpse that misses it.

/// The four slots of a rig, in the order scr_setupSpawning writes them.
enum ZOMB_ANIM { walk, idle, attack, die }

/// How long one cycle of the walking / idling animation takes, in seconds.
/// A duration, not an image_speed: scr_animSpeedForSeconds turns it into a
/// speed from the sprite's OWN frame count, so re-drawing a rig cannot change
/// how fast it plays (LL-030).
#macro ZOMB_CYCLE_SECS 1.0

/// How long the corpse lies on the ground.  The die sprite is played at
/// exactly this duration, and the destroy is this same number - so the
/// monster disappears when its animation ends rather than after a delay
/// that was tuned beside it (LL-040's shape: one number, one reader).
#macro ZOMB_DIE_SECS   0.8

/// ---- WHERE THE SLOTS ARE READ NOW -------------------------------------
/// The two helpers that lived here - zomb_art_sprite() and zomb_art_play() -
/// are gone: they took a bare ARRAY and an index, which is exactly the shape
/// that let a dying monster play its walk frames in silence (LL-079, LL-081).
/// Their job is scr_mon_roster's, by name:
///
///     mon_rig_slot(rig, ZOMB_ANIM.die)     instead of zomb_art_sprite()
///     mon_rig_play(rig, ZOMB_ANIM.walk, s) instead of zomb_art_play()
///
/// What stays here is what this file is for: the SLOT ORDER (ZOMB_ANIM), the
/// two durations, and the boot report.  A caller that wants a monster's art
/// asks zomb_rig() for it - never an array on the instance.

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

/// One log line per bank, naming what every row ACTUALLY holds at runtime.
///
/// This is the line that settles "the portraits are swapped" (LL-057) and now
/// also "that creature has no die sheet": every SLOT is printed by name, so a
/// short row reads `die=none slots=2` at boot instead of being discovered by a
/// corpse that keeps walking (LL-079, LL-081).  The slots come from
/// scr_mon_roster's mon_rig_report(), which is the same lookup the monsters
/// use - a report that re-derived the art would be a second opinion about it,
/// and the whole bug was two opinions.
/// Every read is guarded: sprite_get_name on a missing sprite is fatal
/// (LL-012).
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
