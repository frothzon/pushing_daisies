/// @description  scr_level_spawn();
function scr_level_spawn() {
	/*
	    spawn creatures
	*/

	//--------------------------- choose creature
	if(state_time == 0){
	    spawn_index = irandom(spawn_pool-1);
	    wave_count++;
	    add_item_value(waves,1);
	    /// play zombie sound
	    scr_playSound(snd_zomb_emerge,false);
	}

	//--------------------------- Spawn Creature--------------------//
	var _mon = spawn_mon[spawn_index],
	    _isBoss = false;

	/// spawn boss every 10 waves
	if(wave_count % 10 == 0 && wave_count > 1){
	    var _max = array_last_index(spawn_boss);
	    spawn_index = irandom(_max-1);
	    _mon = spawn_boss[spawn_index];
    
	    /// set boss money equal to wave number
	    _mon[@ MON.kill_money] = (wave_count+1);
	    _isBoss = true;
	}
	///----------------------Get Spawn Count -------------------------///
	var MAX = _mon[MON.spawn_count] + wave_count div 5;

	/// only spawn 1 boss
	if(_isBoss){
	    MAX = 1;
	}

	if(MAX > spawn_current){
	    wait_timer--;
	    if(wait_timer <= 0){
	        wait_timer = room_speed*0.5;
	        var _inst = instance_create(0,0,obj_mon);
	        spawn_current++;
	        //---------------------- Creature Data --------//
	        _inst.sprite_array = _mon[MON.sprite_data];
	        _inst.data = array_duplicate(_mon);
	        _inst.image_xscale = 0.25;
	        _inst.image_yscale = 0.25;
	        if(_isBoss){
	            _inst.image_xscale = 0.5;
	            _inst.image_yscale = 0.5;
	        }
        
	        /// modify life based on wave
	        scr_level_difficulty(_inst);
	        //---------------------------------------------//
	        print("made creature");
	    }
	} else {
	    spawn_current = 0;
	    spawn_timer = spawn_wait_time;
	    scr_changeState(scr_level_wait);
	}



}
