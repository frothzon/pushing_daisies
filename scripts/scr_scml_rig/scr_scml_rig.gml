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

/// Runtime-only walk correction for the embedded SCML definitions. The imported
/// SCML source files are not present, but the normalized clip key arrays are.
/// Clamp the actual hip-to-knee direction and knee bend per walk key; child feet
/// counterrotate by the exact change so their world angle stays stable.
#macro SCML_WALK_STRAIGHT_DOWN_DEG 270
#macro SCML_WALK_UPPER_LEG_SWING_DEG 30
#macro SCML_WALK_LOWER_LEG_BEND_DEG 30

function zomb_scml_is_lower_leg_bone(_bone) {
	if(!is_string(_bone)) return false;
	var _length = string_length(_bone);
	if(_length < 12) return false;
	return string_copy(_bone, 1, 6) == "b_leg_"
	    && string_copy(_bone, _length - 5, 6) == "_lower";
}

function zomb_scml_is_upper_leg_bone(_bone) {
	if(!is_string(_bone) || string_length(_bone) <= 6) return false;
	return string_copy(_bone, 1, 6) == "b_leg_"
	    && !zomb_scml_is_lower_leg_bone(_bone);
}

function zomb_scml_signed_angle(_angle) {
	while(_angle > 180) _angle -= 360;
	while(_angle < -180) _angle += 360;
	return _angle;
}

function zomb_scml_find_bone_timeline(_timelines, _name) {
	if(!is_array(_timelines) || !is_string(_name)) return -1;
	for(var _i = 0; _i < array_length(_timelines); _i++){
		var _timeline = _timelines[_i];
		if(is_struct(_timeline)
		   && variable_struct_exists(_timeline, "object_type")
		   && _timeline.object_type == "bone"
		   && variable_struct_exists(_timeline, "name")
		   && _timeline.name == _name){
			return _i;
		}
	}
	return -1;
}

function zomb_scml_find_key_at_time(_keys, _key_count, _time, _stride) {
	if(!is_array(_keys) || !is_real(_key_count) || _key_count <= 0 || !is_real(_time)) return -1;
	for(var _i = 0; _i < _key_count; _i++){
		var _time_index = _i * _stride;
		if(_time_index < array_length(_keys)
		   && is_real(_keys[_time_index])
		   && abs(_keys[_time_index] - _time) < 0.001){
			return _i;
		}
	}
	return -1;
}

function zomb_scml_clone_struct_shallow(_source) {
	if(!is_struct(_source)) return undefined;
	var _copy = {},
	    _fields = variable_struct_get_names(_source);
	for(var _i = 0; _i < array_length(_fields); _i++){
		variable_struct_set(_copy, _fields[_i], variable_struct_get(_source, _fields[_i]));
	}
	return _copy;
}

function zomb_scml_clone_array_shallow(_source) {
	if(!is_array(_source)) return undefined;
	var _length = array_length(_source),
	    _copy = array_create(_length);
	for(var _i = 0; _i < _length; _i++){
		_copy[_i] = _source[_i];
	}
	return _copy;
}

function zomb_scml_walk_leg_fix(_entity) {
	if(!is_string(_entity) || _entity == "") return false;

	if(!variable_global_exists("scml_walk_leg_adjusted")
	   || !is_struct(global.scml_walk_leg_adjusted)){
		global.scml_walk_leg_adjusted = {};
	}
	if(variable_struct_exists(global.scml_walk_leg_adjusted, _entity)){
		return global.scml_walk_leg_adjusted[$ _entity];
	}

	var _sys = zomb_scml(),
	    _definition = _sys.describe_entity(SCML_COLLECTION, _entity);
	if(!is_struct(_definition)
	   || !variable_struct_exists(_definition, "animations")
	   || !is_array(_definition.animations)){
		global.scml_walk_leg_adjusted[$ _entity] = false;
		return false;
	}

	var _copy = zomb_scml_clone_struct_shallow(_definition),
	    _animations = zomb_scml_clone_array_shallow(_definition.animations);
	if(!is_struct(_copy) || !is_array(_animations)){
		global.scml_walk_leg_adjusted[$ _entity] = false;
		scr_meta_log("SCML", "WARNING walk leg angle clamp could not clone ", _entity);
		return false;
	}
	variable_struct_set(_copy, "animations", _animations);

	var _pairs_seen = 0,
	    _upper_bones_changed = 0,
	    _lower_bones_changed = 0,
	    _foot_bones_changed = 0,
	    _upper_keys_changed = 0,
	    _lower_keys_changed = 0,
	    _foot_keys_changed = 0,
	    _stride = 18,
	    _angle_field = 3;

	for(var _a = 0; _a < array_length(_definition.animations); _a++){
		var _clip = _definition.animations[_a];
		if(!is_struct(_clip)
		   || !variable_struct_exists(_clip, "name")
		   || _clip.name != "walk"
		   || !variable_struct_exists(_clip, "timelines")
		   || !is_array(_clip.timelines)){
			continue;
		}

		var _clip_copy = zomb_scml_clone_struct_shallow(_clip),
		    _timelines = zomb_scml_clone_array_shallow(_clip.timelines);
		if(!is_struct(_clip_copy) || !is_array(_timelines)) continue;
		variable_struct_set(_clip_copy, "timelines", _timelines);

		var _pelvis_index = zomb_scml_find_bone_timeline(_clip.timelines, "b_pelvis");
		if(_pelvis_index < 0) continue;
		var _pelvis_timeline = _clip.timelines[_pelvis_index];
		if(!variable_struct_exists(_pelvis_timeline, "keys")
		   || !is_array(_pelvis_timeline.keys)
		   || !variable_struct_exists(_pelvis_timeline, "key_count")
		   || !is_real(_pelvis_timeline.key_count)
		   || _pelvis_timeline.key_count <= 0
		   || _pelvis_timeline.key_count * _stride > array_length(_pelvis_timeline.keys)){
			continue;
		}

		var _clip_changed = false;
		for(var _u = 0; _u < array_length(_clip.timelines); _u++){
			var _upper_timeline = _clip.timelines[_u];
			if(!is_struct(_upper_timeline)
			   || !variable_struct_exists(_upper_timeline, "object_type")
			   || _upper_timeline.object_type != "bone"
			   || !variable_struct_exists(_upper_timeline, "name")
			   || !zomb_scml_is_upper_leg_bone(_upper_timeline.name)
			   || !variable_struct_exists(_upper_timeline, "keys")
			   || !is_array(_upper_timeline.keys)
			   || !variable_struct_exists(_upper_timeline, "key_count")
			   || !is_real(_upper_timeline.key_count)
			   || _upper_timeline.key_count <= 0
			   || _upper_timeline.key_count * _stride > array_length(_upper_timeline.keys)){
				continue;
			}

			var _suffix = string_delete(_upper_timeline.name, 1, 6),
			    _lower_index = zomb_scml_find_bone_timeline(_clip.timelines, "b_leg_" + _suffix + "_lower"),
			    _foot_index = zomb_scml_find_bone_timeline(_clip.timelines, "b_foot_" + _suffix);
			if(_lower_index < 0 || _foot_index < 0) continue;

			var _lower_timeline = _clip.timelines[_lower_index],
			    _foot_timeline = _clip.timelines[_foot_index];
			if(!variable_struct_exists(_lower_timeline, "keys")
			   || !is_array(_lower_timeline.keys)
			   || !variable_struct_exists(_lower_timeline, "key_count")
			   || !is_real(_lower_timeline.key_count)
			   || _lower_timeline.key_count <= 0
			   || _lower_timeline.key_count * _stride > array_length(_lower_timeline.keys)
			   || !variable_struct_exists(_foot_timeline, "keys")
			   || !is_array(_foot_timeline.keys)
			   || !variable_struct_exists(_foot_timeline, "key_count")
			   || !is_real(_foot_timeline.key_count)
			   || _foot_timeline.key_count <= 0
			   || _foot_timeline.key_count * _stride > array_length(_foot_timeline.keys)){
				continue;
			}

			var _upper_copy = zomb_scml_clone_struct_shallow(_upper_timeline),
			    _lower_copy = zomb_scml_clone_struct_shallow(_lower_timeline),
			    _foot_copy = zomb_scml_clone_struct_shallow(_foot_timeline),
			    _upper_keys = zomb_scml_clone_array_shallow(_upper_timeline.keys),
			    _lower_keys = zomb_scml_clone_array_shallow(_lower_timeline.keys),
			    _foot_keys = zomb_scml_clone_array_shallow(_foot_timeline.keys);
			if(!is_struct(_upper_copy) || !is_struct(_lower_copy) || !is_struct(_foot_copy)
			   || !is_array(_upper_keys) || !is_array(_lower_keys) || !is_array(_foot_keys)){
				continue;
			}

			var _sample_count = _upper_timeline.key_count,
			    _paired_lower_keys = array_create(_sample_count, -1),
			    _paired_foot_keys = array_create(_sample_count, -1),
			    _thigh_angles = array_create(_sample_count, 0),
			    _bend_angles = array_create(_sample_count, 0),
			    _valid_samples = array_create(_sample_count, false),
			    _thigh_min = 1000000,
			    _thigh_max = -1000000,
			    _bend_min = 1000000,
			    _bend_max = -1000000;

			/// First collect each joint's real segment directions so the full walk
			/// cycle can be remapped without losing its key timing or bend direction.
			for(var _k = 0; _k < _sample_count; _k++){
				var _upper_base = _k * _stride,
				    _time = _upper_keys[_upper_base],
				    _lower_key = zomb_scml_find_key_at_time(_lower_keys, _lower_timeline.key_count, _time, _stride),
				    _foot_key = zomb_scml_find_key_at_time(_foot_keys, _foot_timeline.key_count, _time, _stride),
				    _pelvis_key = zomb_scml_find_key_at_time(_pelvis_timeline.keys, _pelvis_timeline.key_count, _time, _stride);
				if(_lower_key < 0 || _foot_key < 0 || _pelvis_key < 0) continue;

				var _lower_base = _lower_key * _stride,
				    _foot_base = _foot_key * _stride,
				    _pelvis_base = _pelvis_key * _stride,
				    _knee_x = _lower_keys[_lower_base + 1],
				    _knee_y = _lower_keys[_lower_base + 2],
				    _ankle_x = _foot_keys[_foot_base + 1],
				    _ankle_y = _foot_keys[_foot_base + 2];
				if(!is_real(_upper_keys[_upper_base + _angle_field])
				   || !is_real(_lower_keys[_lower_base + _angle_field])
				   || !is_real(_foot_keys[_foot_base + _angle_field])
				   || !is_real(_pelvis_timeline.keys[_pelvis_base + _angle_field])
				   || !is_real(_knee_x) || !is_real(_knee_y)
				   || !is_real(_ankle_x) || !is_real(_ankle_y)
				   || (_knee_x * _knee_x + _knee_y * _knee_y) < 0.0001
				   || (_ankle_x * _ankle_x + _ankle_y * _ankle_y) < 0.0001){
					continue;
				}

				var _knee_vector_angle = point_direction(0, 0, _knee_x, -_knee_y),
				    _pelvis_angle = _pelvis_timeline.keys[_pelvis_base + _angle_field],
				    _upper_angle = _upper_keys[_upper_base + _angle_field],
				    _thigh_world_angle = _pelvis_angle + _upper_angle + _knee_vector_angle,
				    _thigh_from_down = zomb_scml_signed_angle(_thigh_world_angle - SCML_WALK_STRAIGHT_DOWN_DEG),
				    _foot_vector_angle = point_direction(0, 0, _ankle_x, -_ankle_y),
				    _lower_angle = _lower_keys[_lower_base + _angle_field],
				    _knee_bend = zomb_scml_signed_angle(_lower_angle + _foot_vector_angle - _knee_vector_angle);
				_paired_lower_keys[_k] = _lower_key;
				_paired_foot_keys[_k] = _foot_key;
				_thigh_angles[_k] = _thigh_from_down;
				_bend_angles[_k] = _knee_bend;
				_valid_samples[_k] = true;
				_thigh_min = min(_thigh_min, _thigh_from_down);
				_thigh_max = max(_thigh_max, _thigh_from_down);
				_bend_min = min(_bend_min, _knee_bend);
				_bend_max = max(_bend_max, _knee_bend);
				_pairs_seen++;
			}

			var _upper_changed = false,
			    _lower_changed = false,
			    _foot_changed = false,
			    _bend_crosses_zero = _bend_min < -0.001 && _bend_max > 0.001;
			for(var _k = 0; _k < _sample_count; _k++){
				if(!_valid_samples[_k]) continue;
				var _upper_base = _k * _stride,
				    _lower_base = _paired_lower_keys[_k] * _stride,
				    _foot_base = _paired_foot_keys[_k] * _stride,
				    _thigh_value = _thigh_angles[_k],
				    _bend_value = _bend_angles[_k],
				    _thigh_range = _thigh_max - _thigh_min,
				    _bend_range = _bend_max - _bend_min,
				    _target_thigh = _thigh_value,
				    _target_bend = _bend_value;

				if(_thigh_range > 0.001){
					_target_thigh = -SCML_WALK_UPPER_LEG_SWING_DEG
					              + ((_thigh_value - _thigh_min) / _thigh_range)
					              * (2 * SCML_WALK_UPPER_LEG_SWING_DEG);
				}
				if(_bend_range > 0.001){
					if(_bend_crosses_zero){
						_target_bend = clamp(_bend_value, -SCML_WALK_LOWER_LEG_BEND_DEG, SCML_WALK_LOWER_LEG_BEND_DEG);
					}else if(_bend_min < -0.001){
						_target_bend = -SCML_WALK_LOWER_LEG_BEND_DEG
						             * ((_bend_max - _bend_value) / _bend_range);
					}else if(_bend_max > 0.001){
						_target_bend = SCML_WALK_LOWER_LEG_BEND_DEG
						             * ((_bend_value - _bend_min) / _bend_range);
					}else{
						_target_bend = 0;
					}
				}

				var _upper_delta = _target_thigh - _thigh_value,
				    _lower_delta = _target_bend - _bend_value;
				if(abs(_upper_delta) > 0.001){
					_upper_keys[_upper_base + _angle_field] += _upper_delta;
					_upper_keys_changed++;
					_upper_changed = true;
				}
				if(abs(_lower_delta) > 0.001){
					_lower_keys[_lower_base + _angle_field] += _lower_delta;
					_lower_keys_changed++;
					_lower_changed = true;
				}
				var _foot_counterrotate = _upper_delta + _lower_delta;
				if(abs(_foot_counterrotate) > 0.001){
					_foot_keys[_foot_base + _angle_field] -= _foot_counterrotate;
					_foot_keys_changed++;
					_foot_changed = true;
				}
			}

			if(_upper_changed){
				variable_struct_set(_upper_copy, "keys", _upper_keys);
				_timelines[_u] = _upper_copy;
				_upper_bones_changed++;
				_clip_changed = true;
			}
			if(_lower_changed){
				variable_struct_set(_lower_copy, "keys", _lower_keys);
				_timelines[_lower_index] = _lower_copy;
				_lower_bones_changed++;
				_clip_changed = true;
			}
			if(_foot_changed){
				variable_struct_set(_foot_copy, "keys", _foot_keys);
				_timelines[_foot_index] = _foot_copy;
				_foot_bones_changed++;
				_clip_changed = true;
			}
		}
		if(_clip_changed) _animations[_a] = _clip_copy;
	}

	if(_pairs_seen <= 0){
		global.scml_walk_leg_adjusted[$ _entity] = false;
		return false;
	}
	if(_upper_keys_changed + _lower_keys_changed + _foot_keys_changed > 0){
		variable_struct_set(_copy, "scml_walk_pose_clamp_down_deg", SCML_WALK_STRAIGHT_DOWN_DEG);
		variable_struct_set(_copy, "scml_walk_pose_swing_deg", SCML_WALK_UPPER_LEG_SWING_DEG);
		if(!_sys.register_definition(SCML_COLLECTION, _copy)){
			global.scml_walk_leg_adjusted[$ _entity] = false;
			scr_meta_log("SCML", "WARNING walk leg angle clamp registration failed for ", _entity);
			return false;
		}
	}

	global.scml_walk_leg_adjusted[$ _entity] = true;
	scr_meta_log("SCML", "walk leg angle clamp ", _entity,
	             " upper=down+/-", SCML_WALK_UPPER_LEG_SWING_DEG,
	             " lower bend=0..+/-", SCML_WALK_LOWER_LEG_BEND_DEG,
	             " samples=", _pairs_seen,
	             " upper bones=", _upper_bones_changed,
	             " lower bones=", _lower_bones_changed,
	             " foot bones=", _foot_bones_changed,
	             " upper keys=", _upper_keys_changed,
	             " lower keys=", _lower_keys_changed,
	             " foot keys=", _foot_keys_changed);
	return true;
}

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

	zomb_scml_walk_leg_fix(_rig.scml);

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

	/// the per-entity SCALE FIX (zomb_scml_scale_fix, stamped by
	/// mon_rig_from): rides the SAME transform, after the instance's own
	/// scale and facing sign - states, base_scale and the emerge growth
	/// stay blind to it
	var _fix = 1;
	if(variable_struct_exists(_rig, "scml_fix") && is_real(_rig.scml_fix)){
		_fix = _rig.scml_fix;
	}

	zomb_scml().set_transform(zomb_scml_player(), x, y, _rot,
	                          image_xscale * _fix, image_yscale * _fix, _alpha);
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

/// The per-entity SCALE FIX: rig-native height -> original sheet art height.
///
/// The Spriter rigs were authored at a larger, per-entity-varying pixel
/// scale than the sheets they replace (single appendage canvases run to
/// 300px against whole walk sheets of 98-161px), so a rig drawn at the
/// instance's own scale comes out inconsistent with the sheet era and with
/// its neighbours.  The fix makes the rig's NATIVE posed height equal the
/// creature's original walk-sheet ART height - then the same base_scale
/// that scaled the sheets reproduces the sheet-era on-screen size exactly,
/// and no state ever knows (it is applied in zomb_scml_draw, draw-time
/// only).
///
/// MEASURED, not guessed: a scratch player samples sixteen walk poses. For
/// every active part, zomb_scml_part_alpha_bounds transforms the sprite's
/// alpha bbox from its SCML pivot through the sampled pose. get_part_world's
/// width/height are the whole sprite CANVAS, often mostly transparent - using
/// those made the measured rig too tall and the correction too small, which
/// made the visible zombies look squat. The sheet's bbox is the target (its
/// canvas carries padding rows too - LL-078 measured up to 10 on the
/// Gardener's walk sheet). HEIGHT is the anchor because it is the ground-line
/// dimension; the width ratio is LOGGED but never applied. Cached per entity
/// and clamped, because a bad measurement must not make a monster invisible
/// or giant.
#macro SCML_FIX_MIN 0.05
#macro SCML_FIX_MAX 5.0

/// The transformed alpha bounds of one active Spriter part, in room-space
/// coordinates. Part sprites in the imported collection are one-frame images,
/// so sprite_get_bbox_* is their painted-pixel box, not a union of animation
/// frames. The API's part x/y is the SCML pivot; pivot_x/y are normalized on
/// the canvas, with pivot_y measured up from the bottom.
function zomb_scml_part_alpha_bounds(_part) {
	if(!is_struct(_part)) return undefined;
	var _required = ["sprite", "width", "height", "pivot_x", "pivot_y", "x", "y"];
	for(var _i = 0; _i < array_length(_required); _i++){
		if(!variable_struct_exists(_part, _required[_i])) return undefined;
	}

	var _spr = _part.sprite;
	if(!sprite_exists(_spr)) return undefined;

	var _width = _part.width,
		_height = _part.height,
		_pivot_x = _part.pivot_x,
		_pivot_y = _part.pivot_y,
		_x = _part.x,
		_y = _part.y;
	if(!is_real(_width) || _width <= 0) return undefined;
	if(!is_real(_height) || _height <= 0) return undefined;
	if(!is_real(_pivot_x) || !is_real(_pivot_y)) return undefined;
	if(!is_real(_x) || !is_real(_y)) return undefined;

	var _sx = 1,
		_sy = 1,
		_angle = 0;
	if(variable_struct_exists(_part, "scale_x") && is_real(_part.scale_x)) _sx = _part.scale_x;
	if(variable_struct_exists(_part, "scale_y") && is_real(_part.scale_y)) _sy = _part.scale_y;
	if(variable_struct_exists(_part, "angle") && is_real(_part.angle)) _angle = _part.angle;

	var _left = sprite_get_bbox_left(_spr),
		_right = sprite_get_bbox_right(_spr) + 1,
		_top = sprite_get_bbox_top(_spr),
		_bottom = sprite_get_bbox_bottom(_spr) + 1;
	if(_right <= _left || _bottom <= _top) return undefined;

	var _pivot_px = _pivot_x * _width,
		_pivot_py = (1 - _pivot_y) * _height,
		_c = dcos(_angle),
		_s = dsin(_angle),
		_min_x = 0,
		_max_x = 0,
		_min_y = 0,
		_max_y = 0;

	for(var _corner = 0; _corner < 4; _corner++){
		var _u = ((_corner mod 2) == 0) ? _left : _right,
			_v = (_corner < 2) ? _top : _bottom,
			_dx = (_u - _pivot_px) * _sx,
			_dy = (_pivot_py - _v) * _sy,
			_xp = _x + _c * _dx - _s * _dy,
			_yp = _y - (_s * _dx + _c * _dy);
		if(_corner == 0){
			_min_x = _xp; _max_x = _xp;
			_min_y = _yp; _max_y = _yp;
		} else {
			_min_x = min(_min_x, _xp); _max_x = max(_max_x, _xp);
			_min_y = min(_min_y, _yp); _max_y = max(_max_y, _yp);
		}
	}

	return {left:_min_x, right:_max_x, top:_min_y, bottom:_max_y};
}

function zomb_scml_scale_fix(_entity, _sheet) {
	if(!is_string(_entity) || _entity == "") return 1;
	if(!sprite_exists(_sheet)) return 1;

	zomb_scml_walk_leg_fix(_entity);

	if(!variable_global_exists("scml_fix_map") || !is_struct(global.scml_fix_map)){
		global.scml_fix_map = {};
	}
	if(variable_struct_exists(global.scml_fix_map, _entity)){
		return global.scml_fix_map[$ _entity];
	}

	var _fix = 1,
	    _sys = zomb_scml();

	/// the parts to measure, from the shared definition (describe_entity
	/// is the public preloader; parts[] is its part-name list)
	var _def = _sys.describe_entity(SCML_COLLECTION, _entity);
	if(!is_undefined(_def) && variable_struct_exists(_def, "parts")
	   && is_array(_def.parts) && array_length(_def.parts) > 0){

		/// a scratch player poses the rig; play + seek each force a fresh
		/// pose, so no update loop is needed (the demo's export checks do
		/// the same).  Removed before returning - it is never in the
		/// registry, so nothing else can see it.
		var _scratch = "scml-fix";
		_sys.remove_player(_scratch);
		if(_sys.create_player(_scratch, SCML_COLLECTION, _entity)){
			_sys.play(_scratch, "walk");

			var _st  = _sys.get_player_state(_scratch),
			    _dur = (!is_undefined(_st) && _st.duration_ms > 0)
			           ? _st.duration_ms : 1000;

			/// sixteen poses across the walk clip; union the transformed
			/// alpha bounds, not the much larger transparent part canvases
			var _h_max = 0, _w_max = 0;
			for(var _s = 0; _s < 16; _s++){
				_sys.seek(_scratch, _dur * _s / 16);

				var _min_x = 0, _max_x = 0, _min_y = 0, _max_y = 0,
				    _any  = false;
				for(var _p = 0; _p < array_length(_def.parts); _p++){
					var _part = _sys.get_part_world(_scratch, _def.parts[_p]);
					if(is_undefined(_part)) continue;
					var _bounds = zomb_scml_part_alpha_bounds(_part);
					if(is_undefined(_bounds)) continue;

					if(!_any){
						_min_x = _bounds.left; _max_x = _bounds.right;
						_min_y = _bounds.top; _max_y = _bounds.bottom;
						_any = true;
					} else {
						_min_x = min(_min_x, _bounds.left); _max_x = max(_max_x, _bounds.right);
						_min_y = min(_min_y, _bounds.top); _max_y = max(_max_y, _bounds.bottom);
					}
				}

				if(_any){
					_h_max = max(_h_max, _max_y - _min_y);
					_w_max = max(_w_max, _max_x - _min_x);
				}
			}
			_sys.remove_player(_scratch);

			/// the target: the ORIGINAL walk sheet's art bbox, height the
			/// anchor, width logged for eyeballing
			var _sheet_h = sprite_get_bbox_bottom(_sheet)
			               - sprite_get_bbox_top(_sheet) + 1,
			    _sheet_w = sprite_get_bbox_right(_sheet)
			               - sprite_get_bbox_left(_sheet) + 1;

			if(_h_max > 0 && _sheet_h > 0){
				_fix = _sheet_h / _h_max;
				if(_fix < SCML_FIX_MIN || _fix > SCML_FIX_MAX){
					scr_meta_log("SCML", "WARNING normalize ", _entity,
					             " measured fix ", string_format(_fix, 1, 3),
					             " is outside ", SCML_FIX_MIN, "..", SCML_FIX_MAX,
					             " - keeping 1 (rig=", round(_h_max),
					             "px sheet=", _sheet_h, "px)");
					_fix = 1;
				}
			}

			var _wr = (_h_max > 0 && _sheet_w > 0 && _w_max > 0)
			          ? _sheet_w / _w_max : 0;
			scr_meta_log("SCML", "normalize ", _entity,
			             "  rig=", round(_h_max), "x", round(_w_max),
			             "  sheet=", _sheet_h, "x", _sheet_w,
			             "  fix=", string_format(_fix, 1, 3),
			             "  width-ratio=", string_format(_wr, 1, 3));
		}
	}

	global.scml_fix_map[$ _entity] = _fix;
	return _fix;
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

	global.scml_walk_leg_adjusted = {};
	var _entities = zomb_scml_entities();
	for(var _e = 0; _e < array_length(_entities); _e++){
		zomb_scml().describe_entity(SCML_COLLECTION, _entities[_e]);
		zomb_scml_walk_leg_fix(_entities[_e]);
	}

	scr_meta_log("SCML", "boot: ", array_length(_entities),
	             " entities preloaded  pose=", SCML_POSE_HZ, "hz");
}

