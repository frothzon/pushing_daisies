/// @description The SCML (Spriter) half of every monster rig (SCML-custom).
///
/// ONE SpriterInterfaceSystem() for the whole game: players share the
/// collection's definition data, and each monster gets its own named player
/// ("mon-<id>").  A rig whose creature has an entity in the "zombies"
/// collection (scr_mon_roster fills rig.scml through the name map below)
/// plays its clips here; a creature with no entity, no clip, or a player
/// that could not be created falls back to the sprite-sheet path exactly as
/// before - and says so in the log, never silently (LL-079's shape).
///
/// TIMING: the CALLER'S seconds always win (decided 2026-10-28).  mon_rig_play
/// passes ZOMB_CYCLE_SECS / ZOMB_DIE_SECS; set_speed stretches or squeezes
/// the clip to that duration, so re-authoring art can never change gameplay
/// timing (LL-030's shape: one number, one reader).
///
/// THE HALF-RATE POSE: set_pose_rate(player, SCML_POSE_HZ, phase) - the
/// playback clock and events still advance EVERY step, only the bone/part
/// evaluation drops to 30hz, and each monster carries its own phase so a
/// crowd's evaluations spread across frames instead of spiking one.

/// The collection key the Spriter GML Interface gave the zombie import.
#macro SCML_COLLECTION "zombies"

/// Pose evaluations per second.  30 = the "native 30fps" ask: half the
/// game's 60, bought back as headroom on the expensive half of the runtime.
#macro SCML_POSE_HZ 30

/// The ONE system, created on first use.  Never per-monster: players share
/// definition data, and update() must run once per step from one owner.
function zomb_scml() {
	if(variable_global_exists("spriter_system") && is_struct(global.spriter_system)){
		return global.spriter_system;
	}
	global.spriter_system = SpriterInterfaceSystem();
	return global.spriter_system;
}

/// The collection's entity names, read once and cached.  list_entities on
/// an unknown collection answers an empty array, never an error, so a
/// missing import degrades to "every creature falls back to sheets".
function zomb_scml_entities() {
	if(!variable_global_exists("scml_entities") || !is_array(global.scml_entities)){
		var _list = zomb_scml().list_entities(SCML_COLLECTION);
		global.scml_entities = is_array(_list) ? _list : [];
	}
	return global.scml_entities;
}

/// The bank-name -> SCML-entity map.  SEVEN of the fifteen creatures have a
/// different name in the SCML than in scr_setupSpawning's banks - a rename
/// the import did, not a typo here - and a mismatched name that defaulted to
/// itself would silently fall back to sheets (LL-082's shape).  Every
/// creature is listed explicitly, so the coverage test can pin all fifteen.
/// Keys are the BANK names (the roster's key); values are the entity names.
function zomb_scml_entity_map() {
	if(!variable_global_exists("scml_entity_map") || !is_struct(global.scml_entity_map)){
		global.scml_entity_map = {
			"Grumble-Mulch":       "Grumble-Mulch",
			"Dome-Alone":          "dome-alone",
			"Professor-Cerebrisk": "Professor-Cerebrisk",
			"Tusk-A-Lot":          "Sir-Tusk-A-Lot",
			"Sub-Zero":            "Sub-Zero-Self-Esteem",
			"Newly-Turned":        "Newly-Turned",
			"Bog-Wader":           "Bog-Wader",
			"Sandblasted":         "Sandblasted",
			"Root-Bound":          "Rootbound",
			"Shroud":              "Shroud",
			"Harvester":           "Harvester",
			"Foreman-Rustlung":    "Foreman-Rustlung",
			"Orchid-Widow":        "Orchid-Widow",
			"Bell-Ringer":         "Bellringer",
			"Gardener":            "Gardener"
		};
	}
	return global.scml_entity_map;
}

/// Resolve one creature's SCML entity, or "" when it has none.  "" is the
/// "fall back to the sheets" answer, and it is what a renamed-out-of-map
/// creature gets too - the entity must exist in the collection.
function zomb_scml_entity(_name) {
	if(!is_string(_name) || _name == "") return "";

	var _map = zomb_scml_entity_map();
	if(!variable_struct_exists(_map, _name)) return "";

	var _entity = _map[$ _name];
	if(!is_string(_entity) || _entity == "") return "";

	var _entities = zomb_scml_entities();
	for(var _i = 0; _i < array_length(_entities); _i++){
		if(_entities[_i] == _entity) return _entity;
	}
	return "";
}

/// This CALLING monster's player name.  Instance ids are unique for the
/// whole run, so this is unique per monster and stable across states.
function zomb_scml_player() {
	return "mon-" + string(id);
}

/// The registry of live player names - the library has no public way to
/// enumerate its players, so zomb_scml_reset() sweeps this instead.
function zomb_scml_players() {
	if(!variable_global_exists("scml_players") || !is_array(global.scml_players)){
		global.scml_players = [];
	}
	return global.scml_players;
}

/// Ensure the calling monster's player exists.  FALSE - and the caller
/// falls back to sheets - when the rig has no entity or the player could
/// not be created; the failure is named ONCE per creature (LL-079's shape).
/// On creation the player gets the half-rate pose with its own phase.
function zomb_scml_ensure(_rig) {
	if(!is_struct(_rig)) return false;
	if(!variable_struct_exists(_rig, "scml") || !is_string(_rig.scml) || _rig.scml == ""){
		return false;
	}

	var _name = zomb_scml_player();
	if(!is_undefined(zomb_scml().get_player_state(_name))) return true;

	if(!zomb_scml().create_player(_name, SCML_COLLECTION, _rig.scml)){
		if(!variable_global_exists("scml_create_failed")) global.scml_create_failed = {};
		var _key = string(_rig.scml);
		if(!variable_struct_exists(global.scml_create_failed, _key)){
			global.scml_create_failed[$ _key] = true;
			scr_meta_log("SCML", "WARNING create_player failed for ", _key,
			             " - ", _name, " falls back to its sprite sheets");
		}
		return false;
	}

	/// the half-rate pose, staggered: phase spreads evaluations across
	/// frames so a wave's worth of monsters does not spike one step
	if(!variable_global_exists("scml_spawn_count") || !is_real(global.scml_spawn_count)){
		global.scml_spawn_count = 0;
	}
	global.scml_spawn_count++;
	var _phase = (global.scml_spawn_count mod 32) / 32;
	zomb_scml().set_pose_rate(_name, SCML_POSE_HZ, _phase);

	array_push(zomb_scml_players(), _name);
	scr_meta_log("SCML", "player ", _name, " = ", _rig.scml,
	             "  pose=", SCML_POSE_HZ, "hz  phase=", string_format(_phase, 1, 3));
	return true;
}

/// One entity's clip names, read once and cached.  An empty array means
/// "no clips here" and every play falls back to the sheets.
function zomb_scml_clips(_entity) {
	if(!is_string(_entity) || _entity == "") return [];

	if(!variable_global_exists("scml_clip_map") || !is_struct(global.scml_clip_map)){
		global.scml_clip_map = {};
	}
	if(variable_struct_exists(global.scml_clip_map, _entity)){
		return global.scml_clip_map[$ _entity];
	}

	var _clips = zomb_scml().list_animations(SCML_COLLECTION, _entity);
	if(!is_array(_clips)) _clips = [];
	global.scml_clip_map[$ _entity] = _clips;
	return _clips;
}

/// Play one of the four slots on the calling monster's player, stretched to
/// the CALLER'S seconds.  Returns the clip name on success; FALSE means
/// "not on SCML - use the sheets" (no entity, no clip, no player).  This is
/// the SCML half of mon_rig_play; the no-restart rule below is LL-030's.
function zomb_scml_play(_rig, _anim, _secs) {
	if(!zomb_scml_ensure(_rig)) return false;

	var _clip = mon_rig_key(_anim);
	if(_clip == "") return false;

	/// the clip must exist by name: play() on an unknown clip is logged and
	/// IGNORED by the runtime - LL-079's silent shape, so ask here instead
	var _clips = zomb_scml_clips(_rig.scml);
	var _has = false;
	for(var _i = 0; _i < array_length(_clips); _i++){
		if(_clips[_i] == _clip){ _has = true; break; }
	}
	if(!_has) return false;

	var _sys  = zomb_scml(),
	    _name = zomb_scml_player();

	/// NO restart of the clip that is already playing: a per-step caller
	/// must never reset a cycle in progress (LL-030, LL-079).  A finished
	/// non-looping clip (a corpse's die) IS restarted if asked again.
	var _state = _sys.get_player_state(_name);
	if(is_undefined(_state) || _state.animation != _clip || !_state.playing){
		_sys.play(_name, _clip);
		_state = _sys.get_player_state(_name);
	}

	/// the caller's seconds win: the clip is stretched or squeezed to the
	/// duration the game asked for, whatever it was authored as
	if(!is_undefined(_state) && _state.duration_ms > 0
	   && is_real(_secs) && _secs > 0){
		_sys.set_speed(_name, (_state.duration_ms / 1000) / _secs);
	}

	return _clip;
}

/// Is the calling monster wearing its own SCML art?  TRUE only when the
/// player exists, belongs to this rig's entity, and is playing one of the
/// four clips - a walker holds walk, a corpse holds die (finished or not),
/// so the heal can never undo a fall (LL-030, LL-080).  This is the SCML
/// half of mon_rig_has; a FALSE here still answers through the sheets.
function zomb_scml_active(_rig) {
	if(!is_struct(_rig)) return false;
	if(!variable_struct_exists(_rig, "scml") || _rig.scml == "") return false;

	var _state = zomb_scml().get_player_state(zomb_scml_player());
	if(is_undefined(_state)) return false;
	if(_state.entity != _rig.scml) return false;

	for(var _i = 0; _i < 4; _i++){
		if(_state.animation == mon_rig_key(_i)) return true;
	}
	return false;
}

/// The calling monster's player state, or undefined.  Every caller guards
/// on is_undefined before reading a field (LL-002).
function zomb_scml_state() {
	return zomb_scml().get_player_state(zomb_scml_player());
}

/// Draw the calling monster as its rigged player, at its own depth.  TRUE
/// when drawn (the caller must then NOT draw_self - two renders of one
/// monster is the double this ordering prevents); FALSE when there is no
/// player to draw, and the sheet path runs instead.
///
/// ONE set_transform carries everything: position, rotation, the emerge's
/// growing size, and the facing SIGN (a negative image_xscale mirrors the
/// whole rig - right-to-left walking).  Scale 0 - the emerge's birth - is
/// legal: the runtime multiplies, never divides, so every part lands on the
/// root point at zero size, exactly like draw_self at image_xscale 0 did.
///
/// Known, carded regressions on this branch: the status tint (parts draw
/// c_white) and the waterline crop (the crop reads one sheet's pixels).
function zomb_scml_draw(_rig) {
	if(!zomb_scml_active(_rig)) return false;

	var _rot = 0;
	if(variable_instance_exists(id, "rot_angle") && is_real(rot_angle)) _rot = rot_angle;
	var _alpha = 1;
	if(variable_instance_exists(id, "image_alpha") && is_real(image_alpha)) _alpha = image_alpha;

	zomb_scml().set_transform(zomb_scml_player(), x, y, _rot,
	                          image_xscale, image_yscale, _alpha);
	zomb_scml().draw(zomb_scml_player(), x, y);
	return true;
}

/// THE update hook: one call per Step, from ONE owner (_levelControl's Step
/// event).  Cheap no-op with no players; advances every player's clock and
/// events by delta_time when there are.  delta_time is microseconds; the
/// system takes seconds.
function zomb_scml_update() {
	if(array_length(zomb_scml_players()) <= 0) return;
	if(!variable_global_exists("spriter_system")) return;
	if(delta_time <= 0) return;
	zomb_scml().update(delta_time / 1000000);
}

/// Remove the calling monster's player (and its registry entry).  obj_mon's
/// Destroy event calls this, so every destroy path - the fall's last frame,
/// the despawn, the room end - lands in the same place.
function zomb_scml_remove() {
	var _name    = zomb_scml_player(),
	    _players = zomb_scml_players();

	for(var _i = array_length(_players) - 1; _i >= 0; _i--){
		if(_players[_i] == _name){
			array_delete(_players, _i, 1);
			break;
		}
	}
	zomb_scml().remove_player(_name);
}

/// Boot/reset: remove every tracked player (their monsters died with the
/// room they were in), clear the caches a re-import would change, and
/// PRELOAD every definition - the interface doc's advice - so no first
/// spawn ever pays the decode.  Called from scr_level_boot, which runs on
/// EVERY entry to the stage room (LL-049).
function zomb_scml_reset() {
	var _players = zomb_scml_players();
	for(var _i = array_length(_players) - 1; _i >= 0; _i--){
		zomb_scml().remove_player(_players[_i]);
	}
	global.scml_players     = [];
	global.scml_clip_map    = {};
	global.scml_spawn_count = 0;

	var _entities = zomb_scml_entities();
	for(var _e = 0; _e < array_length(_entities); _e++){
		zomb_scml().describe_entity(SCML_COLLECTION, _entities[_e]);
	}

	scr_meta_log("SCML", "boot: ", array_length(_entities),
	             " entities preloaded  pose=", SCML_POSE_HZ, "hz");
}

