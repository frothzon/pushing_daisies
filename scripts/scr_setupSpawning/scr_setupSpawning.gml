/// @description  scr_setupSpawning();
/// setup spawns
function scr_setupSpawning() {

	//------------- spawn data
	spawn_timer = 0;
	spawn_count = 5;
	spawn_current = 0;
	wait_timer = 0;
	/// game_get_speed replaces the obsolete room_speed (LL-007): the
	/// wait is a real duration, not a frame count that changes with the
	/// runtime speed setting.
	spawn_wait_time = game_get_speed(gamespeed_fps)*5.9;

	//------------- creature list
	/// monsters - the restyled roster.  One WALK sprite each: the crawl
	/// animation that used to play on spawn is gone, and scr_zombie_emerge
	/// grows the monster from nothing to its full size instead.
	spawn_mon[0] = scr_makeMonster("Grumble-Mulch",1,7,array(spr_grumble_walk),10,1,5);
	spawn_mon[1] = scr_makeMonster("Dome-Alone",0.5,12,array(spr_dome_alone_walk),10,2,3);
	spawn_mon[2] = scr_makeMonster("Professor-Cerebrisk",1.5,5,array(spr_professor_walk),10,3,2);

	/// bosses
	spawn_boss[0] = scr_makeMonster("Tusk-A-Lot",0.5,55,array(spr_tusk_walk),100,50,1);
	spawn_boss[1] = scr_makeMonster("Sub-Zero",0.25,110,array(spr_zero_walk),100,50,1);

	/// the textbox portrait for each creature (MON.portrait) - used by the
	/// "Up Next..." popup.  Set here AFTER scr_makeMonster, not through it:
	/// its positional arguments are fragile (MON.maxLife sits at index 7).
	spawn_mon[0][MON.portrait] = spr_grumble_portrait;
	spawn_mon[1][MON.portrait] = spr_dome_portrait;
	spawn_mon[2][MON.portrait] = spr_cerebrisk_portrait;
	spawn_boss[0][MON.portrait] = spr_tusk_portrait;
	spawn_boss[1][MON.portrait] = spr_zero_portrait;

	//------------- List Size
	spawn_pool = array_last_index(spawn_mon);
	spawn_index = 0;

	//------------- wave data
	wave_count = 0;
	wait_stuck = 0;      /// frames a wave has had monsters alive past its timer
	wait_valve_fired = false;  /// the 10-minute backstop has fired (LL-031)
	is_boss_wave = false;



}
