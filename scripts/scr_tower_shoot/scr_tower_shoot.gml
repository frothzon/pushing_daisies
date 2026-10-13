/// @description  scr_tower_shoot()
function scr_tower_shoot() {
	/*
	    shoot the object
	*/

	/// frame_number is a FLOAT once the level ladder / clover bonus scales
	/// fire_rate (tower_levels.gml): at L2 a base 3/s tower is 3.12/s, so
	/// room_speed/fire_rate is 19.23.  state_time is an integer, so an exact
	/// `== frame_number` test can NEVER be true - the tower then looped the
	/// attack animation forever (LL-029).  Every beat below uses >= with a
	/// one-shot flag, so re-running it cannot double-fire.
	if(state_time == 0){
	    sprite_index = sprite_list[TOWER_ANIM.attack];
	    image_index = 0;
	    var _rate = data[TOWER.fire_rate];
	    frame_number  = (_rate > 0) ? room_speed/_rate : room_speed;
	    /// The attack's length IS the fire rate, so its duration here is
	    /// frame_number - but the SPEED still comes from the frame count, so
	    /// a shorter attack sprite swings over the same period (LL-030).
	    image_speed   = scr_tower_animSpeed(TOWER_ANIM.attack, frame_number);
	    damage_calc   = data[TOWER.damage];
	    target        = noone;    /// acquire fresh - never inherit normal's single pick
	    did_damage    = false;
	    did_particles = false;
	    fire_frame    = max(1, floor(frame_number - time_offset));
	    part_frame    = max(0, floor(frame_number - time_offset - 10));
	}

	/// ---- targets: re-checked EVERY frame, so a target that dies (or walks
	/// out of range) mid-swing sends the tower back to idle instead of
	/// leaving it swinging at nothing.  The loop is bounded by the cached
	/// list (this shot's target cap), not by every monster, so it is cheap;
	/// the full find_all_range() scan only runs when nothing in the list is
	/// still valid and in range.
	var _live = false;
	if(is_array(target)){
	    var _n = array_length(target);
	    for(var _i = 0; _i < _n; _i++){
	        var _t = target[_i];
	        if(scr_isValidInstance(_t) && point_in_circle(x,y,_t.x,_t.y,data[TOWER.range])){
	            _live = true;
	            break;
	        }
	    }
	}
	if(!_live){
	    target = find_all_range(x,y,obj_mon,data[TOWER.range],data[TOWER.targets]);
	    if(!is_array(target)){
	        /// nothing left to shoot - return to idle rather than holding
	        /// the attack pose (this is the playtest bug)
	        print("TOWER  no targets in range, return to idle  frame=",frame_number);
	        scr_changeState(scr_tower_return);
	        exit;
	    }
	}

	if(!did_damage && state_time >= fire_frame){
	    /// do damage
	    for_array(target,scr_do_damage);
	    did_damage = true;
	}

	if(!did_particles && state_time >= part_frame){
	    /// show particles for damage
	    for_array(target,scr_damage_particles);
	    did_particles = true;
	}

	if(state_time >= frame_number){
	    /// change back.  >= , not == : frame_number is fractional whenever
	    /// fire_rate is scaled (LL-029)
	    scr_changeState(scr_tower_return);
	}
}

