/// @description  scr_level_spawn();  - spawn one wave
function scr_level_spawn() {
	/*
	    Spawn the creatures for the current wave.

	    Roadmap 0.2/0.4.  The spawn pool and the wave target now come from
	    stage_data() rather than being implicit, which is what lets a stage
	    END - the old flow spawned waves forever because nothing ever
	    compared the wave count to a target.
	*/

	var _fps = game_get_speed(gamespeed_fps),
	    _row = stage_current();

	//--------------------------- choose the creature
	if(level_state_time == 0){
	    wave_count++;
	    add_item_value(waves,1);
	    scr_playSound(snd_zomb_emerge,false);

	    /// a stage names its own spawners.  Its boss, if it has one, is the
	    /// FINAL wave - a stage ends on its climax.
	    ///
	    /// The cadence of mid-stage bosses comes from the LEVEL data
	    /// (`boss_every`, region_data.gml) rather than a magic `% 10`.  At the
	    /// 5-10 waves a stage used to have that constant never once fired; at
	    /// 15-60 it would fire five times a stage and the last wave would not
	    /// be a boss at all - the shape of the stage, inverted.
	    var _pool   = _row.spawns,
	        _bosses = _row.bosses,
	        _every  = _row.boss_every;
	    if(array_length(_pool) == 0) _pool = [0];
	    if(!is_real(_every) || _every < 0) _every = 0;

	    is_boss_wave = (_every > 0 && wave_count % _every == 0 && wave_count > 1);
	    if(array_length(_bosses) > 0 && wave_count >= _row.waves){
	        is_boss_wave = true;   /// the named boss always closes the stage
	    }

	    if(is_boss_wave && array_length(_bosses) > 0){
	        spawn_index = _bosses[irandom(array_length(_bosses) - 1)];
	    } else if(is_boss_wave){
	        spawn_index = irandom(array_length(spawn_boss) - 1);
	    } else {
	        spawn_index = _pool[irandom(array_length(_pool) - 1)];
	    }

	    /// clamp, so bad stage data cannot index past a pool and throw
	    var _bank = is_boss_wave ? spawn_boss : spawn_mon;
	    spawn_index = clamp(spawn_index, 0, array_length(_bank) - 1);

	    scr_meta_log("LEVEL", "wave ", wave_count, "/", _row.waves,
	                 " boss=", is_boss_wave, " spawner=", spawn_index,
	                 " pool=", array_length(_bank));
	}

	//--------------------------- Spawn Creature
	var _bank2 = is_boss_wave ? spawn_boss : spawn_mon,
	    _mon   = _bank2[spawn_index];

	if(is_boss_wave){
	    /// the boss pays out money equal to the wave number
	    _mon[@ MON.kill_money] = (wave_count + 1);
	}

	/// how many of this wave's creature to spawn.  Grows with the wave, and
	/// the difficulty column adds its own extra (Brutal sends one more).
	var MAX = _mon[MON.spawn_count] + wave_count div 5 + difficulty_count_bonus();
	if(MAX < 1) MAX = 1;
	if(is_boss_wave) MAX = 1;

	if(MAX > spawn_current){
	    wait_timer--;
	    if(wait_timer <= 0){
	        wait_timer = _fps * 0.5;
	        var _inst = instance_create_depth(0,0,-60,obj_mon);
	        spawn_current++;
	        _inst.sprite_array = _mon[MON.sprite_data];
	        _inst.data = array_duplicate(_mon);
	        _inst.image_xscale = 0.25;
	        _inst.image_yscale = 0.25;
	        if(is_boss_wave){
	            _inst.image_xscale = 0.5;
	            _inst.image_yscale = 0.5;
	        }
	        /// modify life for the wave and the difficulty
	        scr_level_difficulty(_inst);
	    }
	} else {
	    spawn_current = 0;
	    spawn_timer = spawn_wait_time;
	    wait_stuck = 0;
	    scr_level_request(LEVEL_STATE.WAIT);
	}
}
