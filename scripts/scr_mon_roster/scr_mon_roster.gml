/// @description  The monster ROSTER: one struct per creature, its four
///               animations read BACK BY NAME - and the one place a monster's
///               art is looked up.
///
/// WHY THIS FILE EXISTS (LL-081)
/// -----------------------------
/// A rig used to be a bare array - `array(walk, idle, attack, die)` - copied
/// onto every instance by scr_level_spawn and then read by MAGIC INDEX from
/// four different places: scr_zombie_emerge took `sprite_array[0]`, the walk
/// and idle came from `zomb_art_play(sprite_array, ZOMB_ANIM.x)`, and the kill
/// and the fall both asked for `ZOMB_ANIM.die`.  Every one of those reads is
/// correct in isolation, and together they were unanswerable: a corpse that
/// played its WALK frames reported no error anywhere, because a missing slot
/// answers -1 and "change nothing" is a legal answer.
///
/// So the art is a STRUCT now, built once per creature from the same rows
/// scr_setupSpawning writes (`spawn_mon` / `spawn_boss`), cached in the global
/// roster, and pulled by the instance:
///
///     mon_roster()                 - the array of structs, built by
///                                    mon_roster_build() from both banks
///     mon_rig_find(name)           - the struct for one creature
///     zomb_rig()                   - the CALLING monster's struct (pull, and
///                                    self-heal from its own row if the roster
///                                    has no answer)
///     mon_rig_slot(rig, anim)      - one sprite, by NAME, or -1
///     mon_rig_play(rig, anim, s)   - switch to it and return it, or -1
///
/// A slot is now named (`rig.die`) rather than counted (`_art[3]`), so a row
/// whose slot list is short or reordered is a named miss the tests can name
/// too - and a rig with NO die art says so in the log once per creature
/// instead of quietly keeping the walk cycle (mon_rig_warn_no_die).
///
/// THE STRUCT IS READ-ONLY.  One struct is shared by every monster of a
/// creature, so a state must never write `rig.walk = ...`: a monster changes
/// its own `sprite_index`, the rig is the table.  Only mon_rig_from() writes.

/// Provenance for a session that needs to see WHICH art a corpse fell with.
///
/// ON while LL-081 is being confirmed.  It is ungated on purpose -
/// `show_debug_message`, not print() - because global.devMode is FALSE in a
/// normal build (initialize_game), which is exactly why the ZOMB/LEVEL lines
/// that would have answered this never appeared in the run it was found in.
/// Flip it to false (or delete the two callers) once the die sheets are
/// confirmed on screen; leaving it on costs two lines per corpse.
#macro ZOMB_RIG_TRACE true

/// The sprite in one slot of a row's array, or -1 when this creature has no
/// art there.  Guards every field, because a rig is data and data can be
/// wrong (LL-002: an editor's typo must not be a fatal error in a Draw event).
function mon_rig_pick(_art, _slot) {
	if(!is_array(_art)) return -1;
	if(!is_real(_slot)) return -1;
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

/// Play one slot, and return the sprite now on the instance (or -1).
///
/// ONLY SWITCHING ON CHANGE (2026-10-18, LL-030's sibling): the walking state
/// runs this every step, and re-assigning image_index = 0 every step would
/// freeze the animation on frame 0 - a monster that slides along without
/// moving its legs.  A cycle already playing is left alone, so the call is
/// idempotent AND it answers the sprite either way, which is what lets the
/// fall tell "this corpse has a sheet to watch" from "it kept the art it died
/// in" (LL-079, scr_zombie_die).
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

/// The decisive line for a fall: what the rig holds, what the corpse was
/// wearing, what it wears now, and whether that was a CHANGE.
///
/// `changed=false` with `die=spr_x_die` means the apply step is at fault;
/// `die=none` means the row/roster never carried the slot; `now=` naming the
/// die sheet means the art was right all along and the report that said
/// otherwise was reading something else.  Three causes, one line.
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

