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
	/// monsters
	spawn_mon[0] = scr_makeMonster("Bald Zombie",1,7,array(spr_bald_crawl,spr_bald_walk),10,1,5);
	spawn_mon[1] = scr_makeMonster("Angry Zombie",0.5,12,array(spr_hair_crawl,spr_hair_walk),10,2,3);
	spawn_mon[2] = scr_makeMonster("Brainy Zombie",1.5,5,array(spr_brain_crawl,spr_brain_walk),10,3,2);

	/// bosses
	spawn_boss[0] = scr_makeMonster("Tuskinator",0.5,55,array(spr_boss1_climb,spr_boss1_walk),100,50,1);
	spawn_boss[1] = scr_makeMonster("Zero",0.25,110,array(spr_boss2_climb,spr_boss2_walk),100,50,1);

	//------------- List Size
	spawn_pool = array_last_index(spawn_mon);
	spawn_index = 0;

	//------------- wave data
	wave_count = 0;
	wait_stuck = 0;      /// frames a wave has had monsters alive past its timer
	is_boss_wave = false;



}
