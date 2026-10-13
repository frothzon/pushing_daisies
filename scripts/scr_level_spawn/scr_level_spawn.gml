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

	    /// The creature was already chosen - when the level entered START
	    /// or WAIT - so the "Up Next..." popup and the wave it names agree.
	    /// `irandom` cannot be replayed, so this CONSUMES the stored pick
	    /// rather than re-rolling (see scr_level_pick_spawn).
	    is_boss_wave = next_is_boss;
	    spawn_index  = next_spawn_index;

	    /// guard: if nothing was chosen (a state that reached SPAWN without
	    /// a pick), fall back rather than read an unset variable (LL-002)
	    if(!is_real(is_boss_wave) || !is_real(spawn_index)){
	        var _pick = scr_level_pick_spawn(wave_count);
	        is_boss_wave = _pick.is_boss;
	        spawn_index  = _pick.index;
	    }

	    scr_meta_log("LEVEL", "wave ", wave_count, "/", _row.waves,
	                 " boss=", is_boss_wave, " spawner=", spawn_index,
	                 " pool=", array_length(is_boss_wave ? spawn_boss : spawn_mon));

	    /// close the "Up Next..." popup - the wave is starting now
	    if(instance_exists(obj_textbox)){
	        instance_destroy(obj_textbox);
	    }
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
	        /// the FULL size this monster grows to.  The emerge starts at
	        /// nothing and scales 0.00 -> 1.00 of this, because the crawl
	        /// sprite that used to play on spawn is gone.  0.25 keeps a
	        /// monster to about one 32px grid cell; bosses are twice that.
	        _inst.base_scale = is_boss_wave ? 0.5 : 0.25;
	        _inst.image_xscale = 0;
	        _inst.image_yscale = 0;
	        /// modify life for the wave and the difficulty
	        scr_level_difficulty(_inst);
	    }
	} else {
	    spawn_current = 0;
	    spawn_timer = spawn_wait_time;
	    wait_stuck = 0;
	    wait_valve_fired = false;   /// every wave gets its own backstop
	    scr_level_request(LEVEL_STATE.WAIT);
	}
}
