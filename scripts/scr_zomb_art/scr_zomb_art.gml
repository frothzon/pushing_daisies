/// @description  The monster RIG: which of a creature's four animations is
///               playing, and how its art meets the ground.
///
/// WHY THIS FILE EXISTS
/// --------------------
/// Ten creatures now ship four animations each - walk, idle, attack, die - and
/// a monster used to be a single sprite: scr_zombie_emerge and scr_zombie_path
/// both wrote `sprite_array[0]` and there was nothing else to play.  Four
/// slots mean three new decisions (which slot, when to change it, how long a
/// cycle lasts), and a decision in two places is two answers.
///
/// THE SLOT ORDER IS THE CONTRACT.  `array(walk, idle, attack, die)` is what
/// scr_setupSpawning writes and what ZOMB_ANIM indexes, and walk is 0 so every
/// existing reader of `sprite_array[0]` keeps meaning "the walking art".
///
/// A ROW THAT HAS NO RIG STILL WORKS.  The three original creatures carry a
/// one-element array, so idle/attack/die answer -1 and the monster simply
/// keeps its walk art - the behaviour it had before any of this existed.

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

/// The sprite in one slot of a rig, or -1 when this creature has no art
/// there.  Guards every field, because a rig is data and data can be wrong
/// (LL-002: an editor's typo must not be a fatal error in a Draw event).
function zomb_art_sprite(_art, _slot) {
	if(!is_array(_art))   return -1;
	if(!is_real(_slot))   return -1;
	if(_slot < 0)         return -1;
	if(_slot >= array_length(_art)) return -1;

	var _spr = _art[_slot];
	if(!sprite_exists(_spr)) return -1;
	return _spr;
}

/// Play one slot, and say whether this call CHANGED the sprite.
///
/// ONLY SWITCHING ON CHANGE (2026-10-18, LL-030's sibling): the walking state
/// runs this every step, and re-assigning image_index = 0 every step would
/// freeze the animation on frame 0 - a monster that slides along without
/// moving its legs.  A cycle already playing is left alone, so the switch is
/// idempotent and the states can call it as often as they like.
function zomb_art_play(_art, _slot, _secs) {
	var _spr = zomb_art_sprite(_art, _slot);
	if(_spr == -1) return false;
	if(sprite_index == _spr) return false;

	sprite_index = _spr;
	image_index  = 0;
	/// a name, so the ANIM line in the log says WHICH rig was timed
	image_speed  = scr_animSpeedForSeconds(_spr, _secs, sprite_get_name(_spr));
	return true;
}

/// How far the drawn art sits ABOVE the sprite's bottom edge, in canvas px.
///
/// WHY THIS IS DERIVED (LL-071's rule, for a monster instead of a thumbnail):
/// the die art does not reach the bottom of its canvas - the corpse is lying
/// down and the frame keeps the standing creature's footprint - so drawing it
/// exactly where the living monster stood lifts it by that gap, and the
/// monster visibly POPS UP as it dies.  The gap is a property of the ART, so
/// it is measured, never authored: a re-cut rig re-derives it.
///
/// Walk and idle art reaches the bottom edge, so they return 0 and nothing
/// moves for them.
function zomb_ground_offset(_spr) {
	if(!sprite_exists(_spr)) return 0;

	var _h = sprite_get_height(_spr);
	if(_h <= 0) return 0;

	/// -1 is "no bbox" (fully transparent art) - not a distance to add
	var _b = sprite_get_bbox_bottom(_spr);
	if(_b < 0) return 0;

	var _gap = (_h - 1) - _b;
	return (_gap > 0) ? _gap : 0;
}

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
/// also "that creature has no rig" - a row whose sprite_data is a bare sprite
/// prints rig=1, which is the difference between a creature that can idle and
/// one that cannot.  Every read is guarded: sprite_get_name on a missing
/// sprite is fatal (LL-012).
function zomb_bank_report(_bank, _tag) {
	if(!is_array(_bank)) return "";
	if(!is_string(_tag)) _tag = "bank";

	var _txt = "";
	for(var _b = 0; _b < array_length(_bank); _b++){
		var _row = _bank[_b],
		    _w   = "none",
		    _p   = "none",
		    _rig = 0,
		    _nm  = "?";

		if(is_array(_row)){
			var _art = _row[MON.sprite_data];
			if(is_array(_art)){
				_rig = array_length(_art);
				if(_rig > 0 && sprite_exists(_art[0])){
					_w = sprite_get_name(_art[0]);
				}
			}
			if(sprite_exists(_row[MON.portrait])){
				_p = sprite_get_name(_row[MON.portrait]);
			}
			_nm = string(_row[MON.name]);
		}

		_txt += (_b > 0 ? " | " : "") + string(_b) + "=" + _nm
		        + " rig=" + string(_rig) + " walk=" + _w + " portrait=" + _p;
	}

	scr_meta_log("LEVEL", _tag, " bank: ", _txt);
	return _txt;
}
