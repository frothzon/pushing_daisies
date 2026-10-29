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

	/// the decision this wave spawns from.  DECLARED for the whole call and
	/// not only on the entry frame, because the promise check further down
	/// runs on EVERY spawn frame and reading a `var` that this call never
	/// set is the classic "not set before reading it" (LL-002).
	var _pick = scr_level_pick_none();

	//--------------------------- choose the creature
	if(level_state_time == 0){
	    wave_count++;
	    add_item_value(waves,1);
	    scr_playSound(snd_zomb_emerge,false);

	    /// The creature was already chosen - when the level entered START
	    /// or WAIT - so the "Up Next..." popup and the wave it names agree.
	    /// `irandom` cannot be replayed, so this CONSUMES the stored decision
	    /// (scr_level_pick_store) rather than re-rolling it.
	    _pick = is_struct(next_pick) ? next_pick : scr_level_pick_none(wave_count);

	    /// EVERY way the promise and the delivery could disagree is LOUD
	    /// (LL-058).  A spawned monster cannot be taken back, so say it BEFORE
	    /// spawning: a pick for another wave means something re-entered the
	    /// flow or the controller was rebuilt, and that is the bug the popup
	    /// report is made of.
	    if(_pick.wave != wave_count){
	        scr_meta_log("LEVEL", "WARNING pick is for wave ", _pick.wave,
	                     " but spawning wave ", wave_count, " - re-picking");
	        _pick = scr_level_pick_store(wave_count);
	    }
	    if(instance_number(_levelControl) != 1){
	        scr_meta_log("LEVEL", "WARNING ", instance_number(_levelControl),
	                     " level controllers alive - two wave loops can send ",
	                     "creatures no popup named");
	    }

	    is_boss_wave = _pick.is_boss;
	    spawn_index  = _pick.index;

	    /// guard: a pick with no row (-1) can only come from broken stage
	    /// data; clamp instead of indexing a bank with -1 (LL-002)
	    var _bank0 = is_boss_wave ? spawn_boss : spawn_mon;
	    if(!is_real(spawn_index) || spawn_index < 0
	    || spawn_index >= array_length(_bank0)){
	        scr_meta_log("LEVEL", "WARNING spawner ", spawn_index, " is outside ",
	                     is_boss_wave ? "spawn_boss" : "spawn_mon", " (",
	                     array_length(_bank0), ") - clamping");
	        spawn_index = clamp(spawn_index, 0, array_length(_bank0) - 1);
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

	/// what the popup PROMISED, against what is about to walk out (LL-058).
	/// This can only fire if the decision and the bank disagree, which is the
	/// one failure a player cannot diagnose from a screenshot.
	if(is_array(_mon) && _pick.name != "" && _mon[MON.name] != _pick.name){
	    scr_meta_log("LEVEL", "WARNING the popup said ", _pick.name,
	                 " and wave ", wave_count, " spawns ", _mon[MON.name]);
	}

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
	        /// created at the y=0 edge of the band: obj_mon/Create_0 immediately
	        /// re-derives it from the spawn point it picked (LL-059)
	        var _inst = instance_create_depth(0,0,scr_depth_band(0),obj_mon);
	        spawn_current++;
	        _inst.sprite_array = _mon[MON.sprite_data];
	        /// THE RIG the monster's states read (scr_mon_roster): pulled from
	        /// the roster BY NAME, so every monster of a creature shares one
	        /// struct and no instance carries its own copy of the slot list.
	        /// `sprite_array` above stays - it is this row's art on the
	        /// instance, and zomb_rig() rebuilds a rig from it when the roster
	        /// has no answer - but no state indexes it any more (LL-081).
	        _inst.rig = mon_rig_find(_mon[MON.name]);
	        /// THE CLASS'S OWN WALK SHEET, ON THE INSTANCE, FROM BIRTH - not
	        /// on the monster's first Step.  obj_mon's own sprite is spr_mon:
	        /// ONE 32x32 frame, a placeholder, so a monster drawn before any
	        /// state names its art was a still blob whose "walk" and "death"
	        /// were the same picture (LL-082).  mon_rig_dress also says once
	        /// per creature which walk and die sheets its class got, which is
	        /// how "is any of the zombie art being used?" gets answered from
	        /// the log.
	        with(_inst){
	            mon_rig_dress(rig);
	        }
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
