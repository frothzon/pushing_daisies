/// @description Shared, read-only monster art rigs, keyed by creature and slot.
///
/// mon_roster_build() caches one rig per spawn row; zomb_rig() returns the
/// calling monster's rig. Read slots with mon_rig_slot()/mon_rig_play(), never
/// positional sprite_array accesses (LL-081). Missing slots return -1; missing
/// die art logs once per creature. Only mon_rig_from() writes rig fields.

/// Ungated trace for validating die art in normal builds. Disable after
/// validation; it logs each rig at boot and each corpse once.
#macro ZOMB_RIG_TRACE true

/// The sprite in one slot of a row's array, or -1 when this creature has no
/// art there.  Guards every field, because a rig is data and data can be
/// wrong (LL-002: an editor's typo must not be a fatal error in a Draw event).
function mon_rig_pick(_art, _slot) {
	if(!is_array(_art)) return -1;
	/// NO is_real() ON THE SLOT (LL-083, LL-034's shape).  _slot is a
	/// ZOMB_ANIM constant, and enum values are stored as int64s - the
	/// manual's is_real page says so outright ("This function will return
	/// false for any enum values as they are stored as int64s") - so the
	/// is_real(_slot) line that used to be here answered FALSE for every
	/// perfectly good slot.  Every rig was then built with
	/// walk/idle/attack/die all -1, which is the "every monster is a
	/// 32x32 still (spr_mon)" report: the boot trace said
	/// `slots=4 walk=none` while the art sat in the row.  The bounds
	/// checks below are the real guards; the slot is a compile-time
	/// constant, not data anyone can mistype.
	if(_slot < 0) return -1;
	if(_slot >= array_length(_art)) return -1;

	var _spr = _art[_slot];
	if(!sprite_exists(_spr)) return -1;
	return _spr;
}

/// The NAME of a slot, from ZOMB_ANIM's value - the one place the enum's
/// numbers meet the struct's fields, so "which animation" is asked once.
function mon_rig_key(_anim) {
	switch(_anim){
		case ZOMB_ANIM.walk:   return "walk";
		case ZOMB_ANIM.idle:   return "idle";
		case ZOMB_ANIM.attack: return "attack";
		case ZOMB_ANIM.die:    return "die";
	}
	return "";
}

/// One creature's rig, from its four-slot array.  This is the ONLY writer of
/// a rig's fields (see the header): every slot is filled, and a slot the row
/// does not carry is -1 rather than absent, so a reader never has to ask
/// whether a field exists.
function mon_rig_from(_name, _art, _tag) {
	var _s = {};

	_s.name   = string(_name);
	_s.tag    = is_string(_tag) ? _tag : "?";
	/// how many slots the ROW actually had: 4 is what every creature should
	/// say, and the boot trace prints it, which is the number that settles
	/// "the rig is short" without an argument (LL-057's lesson, LL-081's bug)
	_s.slots  = is_array(_art) ? array_length(_art) : 0;
	_s.walk   = mon_rig_pick(_art, ZOMB_ANIM.walk);
	_s.idle   = mon_rig_pick(_art, ZOMB_ANIM.idle);
	_s.attack = mon_rig_pick(_art, ZOMB_ANIM.attack);
	_s.die    = mon_rig_pick(_art, ZOMB_ANIM.die);
	return _s;
}

/// One bank row -> that creature's rig.  The row is `scr_makeMonster`'s, whose
/// MON.sprite_data slot holds the four-slot array; anything malformed answers
/// undefined instead of throwing inside a boot sequence.
function mon_rig_from_row(_row, _tag) {
	if(!is_array(_row)) return undefined;
	if(array_length(_row) <= MON.sprite_data) return undefined;
	return mon_rig_from(_row[MON.name], _row[MON.sprite_data], _tag);
}


/// The sprite playing `_anim` on this rig, or -1 - by NAME, never by index.
/// A rig that is not a struct, an animation that is not in the enum, a field
/// this (older) struct does not have, and a slot holding something that is not
/// a sprite all answer -1, which every caller treats as "change nothing".
function mon_rig_slot(_rig, _anim) {
	if(!is_struct(_rig)) return -1;

	var _key = mon_rig_key(_anim);
	if(_key == "") return -1;
	if(!variable_struct_exists(_rig, _key)) return -1;

	var _spr = variable_struct_get(_rig, _key);
	if(!sprite_exists(_spr)) return -1;
	return _spr;
}

/// Play a slot and return its sprite, or -1. Replaying the current sprite is
/// a no-op so per-step callers do not reset image_index (LL-030, LL-079).
function mon_rig_play(_rig, _anim, _secs) {
	var _spr = mon_rig_slot(_rig, _anim);
	if(_spr == -1) return -1;
	if(sprite_index == _spr) return _spr;

	sprite_index = _spr;
	image_index  = 0;
	/// a name, so the ANIM line in the log says WHICH rig was timed
	image_speed  = scr_animSpeedForSeconds(_spr, _secs, sprite_get_name(_spr));
	return _spr;
}

/// Is _spr one of the four sheets this rig names?  The question the heal in
/// scr_zomb_step asks - "is this monster wearing its OWN art?" - and the one
/// state a monster can be in that answers no: still holding the object's
/// placeholder sheet (LL-082).  A walker holds its walk sheet and a corpse
/// holds its die sheet, both of which are IN the rig, so the answer can never
/// undo a fall or a cycle that is already correct.
function mon_rig_has(_rig, _spr) {
	if(!is_struct(_rig)) return false;
	if(!sprite_exists(_spr)) return false;

	for(var _i = 0; _i < 4; _i++){
		if(mon_rig_slot(_rig, _i) == _spr) return true;
	}
	return false;
}

/// Say it ONCE per creature which sheets its class was given - the line that
/// makes "every monster plays the same placeholder sprite" answerable from the
/// log instead of from a screenshot.  The die slot is NAMED here, never played
/// here: falling is the DIE state's job (mon_rig_play(_rig, ZOMB_ANIM.die, ...))
/// and dressing a live monster in its corpse sheet would draw a body that has
/// not fallen yet.
function mon_rig_report_spawn(_rig) {
	if(!is_struct(_rig)) return;

	if(!variable_global_exists("mon_spawn_reported")) global.mon_spawn_reported = {};
	var _key = string(_rig.name);
	if(variable_struct_exists(global.mon_spawn_reported, _key)) return;
	global.mon_spawn_reported[$ _key] = true;

	var _walk = mon_rig_slot(_rig, ZOMB_ANIM.walk),
	    _die  = mon_rig_slot(_rig, ZOMB_ANIM.die);

	/// every read guarded: sprite_get_name on -1 is a fatal error (LL-012,
	/// LL-002)
	scr_meta_log("ZOMB", "SPAWN ", _key,
	             "  walk=", sprite_exists(_walk) ? sprite_get_name(_walk) : "none",
	             "  die=",  sprite_exists(_die)  ? sprite_get_name(_die)  : "none");
}

/// Dress the CALLING monster in its class's own WALK sheet.  Returns the
/// sprite, or -1 when the class has no walk art (the sprite is then left
/// alone, exactly like mon_rig_slot's -1 - never blanked).
///
/// obj_mon's own sprite is spr_mon: ONE 32x32 frame, a placeholder.  Until this
/// existed, the only thing that ever replaced it was a state's entry code, so
/// a monster created anywhere other than scr_level_spawn - a test, a dev seed,
/// an instance placed by hand - played one still picture as its walk AND as
/// its death while fifteen rigs of real art sat unused (LL-082).  Called from
/// scr_level_spawn, so a spawn is born in its class art, and from the heal at
/// the top of scr_zomb_step, so nothing can leave a monster in the placeholder
/// however it was created.
///
/// Re-dressing the sheet already playing is a no-op, so a per-step caller never
/// resets a cycle in progress (LL-030, LL-079).
function mon_rig_dress(_rig) {
	var _walk = mon_rig_slot(_rig, ZOMB_ANIM.walk);
	if(_walk == -1) return -1;

	mon_rig_report_spawn(_rig);
	if(sprite_index == _walk) return _walk;

	sprite_index = _walk;
	image_index  = 0;
	image_speed  = scr_animSpeedForSeconds(_walk, ZOMB_CYCLE_SECS,
	                                       sprite_get_name(_walk));
	return _walk;
}

/// "Grumble-Mulch slots=4 walk=spr_grumble_walk idle=... attack=... die=..."
/// - every slot NAMED, so a blank one reads as a blank and not as a shorter
/// list.  Every read is guarded: sprite_get_name on a missing sprite is fatal
/// (LL-012).
function mon_rig_report(_rig) {
	var _txt = "?";
	if(is_struct(_rig)){
		_txt = string(_rig.name);
		if(variable_struct_exists(_rig, "slots")){
			_txt += " slots=" + string(_rig.slots);
		}
	}

	for(var _i = 0; _i < 4; _i++){
		var _spr = mon_rig_slot(_rig, _i);
		_txt += " " + mon_rig_key(_i) + "="
		      + (sprite_exists(_spr) ? sprite_get_name(_spr) : "none");
	}
	return _txt;
}

/// One line for one rig, while ZOMB_RIG_TRACE is on.
function mon_rig_trace(_rig, _where) {
	if(!ZOMB_RIG_TRACE) return;
	show_debug_message("RIG   " + string(_where) + "  " + mon_rig_report(_rig));
}

/// Trace the rig and sprite transition. changed=false or die=none distinguishes
/// an apply failure from a missing slot.
function mon_rig_trace_die(_rig, _was) {
	if(!ZOMB_RIG_TRACE) return;

	var _now = sprite_exists(sprite_index) ? sprite_get_name(sprite_index) : "none",
	    _was_txt = sprite_exists(_was) ? sprite_get_name(_was) : "none";

	show_debug_message("RIG   die " + string(id) + "  " + mon_rig_report(_rig)
		+ "  was=" + _was_txt
		+ "  now=" + _now
		+ "  changed=" + string(_now != _was_txt)
		+ "  frames=" + string(image_number)
		+ "  speed=" + string(image_speed));
}

/// Build the roster from the two banks.  Called ONCE, from scr_setupSpawning,
/// and for a scope reason that matters: spawn_mon/spawn_boss are the level
/// controller's variables, so a monster asking for its art later could not
/// reach them (AGENTS.md 1 rule 6) - the global roster is the hand-off.
function mon_roster_build(_mon_bank, _boss_bank) {
	var _banks = [_mon_bank, _boss_bank],
	    _tags  = ["walker", "boss"];

	global.mon_roster = [];

	for(var _b = 0; _b < array_length(_banks); _b++){
		var _bank = _banks[_b];
		if(!is_array(_bank)) continue;

		for(var _i = 0; _i < array_length(_bank); _i++){
			var _rig = mon_rig_from_row(_bank[_i], _tags[_b]);
			if(!is_struct(_rig)) continue;
			array_push(global.mon_roster, _rig);
			mon_rig_trace(_rig, _tags[_b] + " " + string(_i));
		}
	}

	var _count = array_length(global.mon_roster);
	scr_meta_log("ZOMB", "roster: ", _count, " creatures");
	return global.mon_roster;
}

/// The roster, or an empty array before scr_setupSpawning has run.  Never
/// undefined, because every caller indexes it.
function mon_roster() {
	if(!variable_global_exists("mon_roster")) global.mon_roster = [];
	if(!is_array(global.mon_roster)) global.mon_roster = [];
	return global.mon_roster;
}

/// The rig for one creature, or undefined.  Linear over fifteen rows, called
/// once per monster (zomb_rig caches the answer on the instance).
function mon_rig_find(_name) {
	if(!is_string(_name) || _name == "") return undefined;

	var _roster = mon_roster();
	for(var _i = 0; _i < array_length(_roster); _i++){
		var _rig = _roster[_i];
		if(is_struct(_rig) && variable_struct_exists(_rig, "name")
		&& _rig.name == _name){
			return _rig;
		}
	}
	return undefined;
}

/// The CALLING monster's rig.  Pulled from the roster by the creature's name,
/// cached on the instance - and self-healed from the instance's own row when
/// the roster has no answer, so a monster that predates this file (or a build
/// whose setup did not run) still gets its art instead of silently keeping
/// whatever sprite it was born with (LL-079's shape).
function zomb_rig() {
	if(variable_instance_exists(id, "rig") && is_struct(rig)) return rig;

	var _name = "",
	    _art  = [];
	if(variable_instance_exists(id, "data") && is_array(data)){
		_name = string(data[MON.name]);
	}
	if(variable_instance_exists(id, "sprite_array") && is_array(sprite_array)){
		_art = sprite_array;
	}

	rig = mon_rig_find(_name);
	if(!is_struct(rig)){
		rig = mon_rig_from(_name, _art, "rebuilt");
		scr_meta_log("ZOMB", "WARNING ", _name, " is not in the roster - ",
		             "rebuilt its rig from the instance: ", mon_rig_report(rig));
	}
	return rig;
}

/// Say it ONCE per creature when a rig carries no die sheet - the silent case
/// that shipped five creatures playing their walk frames through a death
/// (LL-079).  A corpse whose fallback is the step clock is legal (art yet to
/// land); a corpse whose fallback is SILENT is how it stayed undiagnosed.
function mon_rig_warn_no_die(_rig) {
	if(!is_struct(_rig)) return;

	if(!variable_global_exists("mon_no_die_reported")) global.mon_no_die_reported = {};
	var _key = string(_rig.name);
	if(variable_struct_exists(global.mon_no_die_reported, _key)) return;

	global.mon_no_die_reported[$ _key] = true;
	scr_meta_log("ZOMB", "WARNING ", _key, " has NO die slot - its corpse ",
	             "keeps the art it died in, removed by the step clock: ",
	             mon_rig_report(_rig));
}

