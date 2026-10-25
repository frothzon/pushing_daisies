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
	/// monsters - the restyled roster.  The crawl animation that used to
	/// play on spawn is gone, and scr_zombie_emerge grows the monster from
	/// nothing to its full size instead.
	///
	/// EVERY ROW CARRIES ITS FOUR SLOTS, including the originals - they had
	/// a one-element array long after their idle/attack/die art landed, and
	/// the rig's fallback ("no slot -> keep the walk art") made that
	/// invisible: a Grumble-Mulch played its WALK frames while it died and
	/// then vanished, and region 1 sends nothing else until stage 6
	/// (LL-079).  A missing slot is now caught by
	/// test_every_rigged_creature_carries_its_own_four_slots rather than by a
	/// playtest.
	spawn_mon[0] = scr_makeMonster("Grumble-Mulch",1,7,array(spr_grumble_walk, spr_grumble_idle, spr_grumble_attack, spr_grumble_die),10,1,5);
	spawn_mon[1] = scr_makeMonster("Dome-Alone",0.5,12,array(spr_dome_alone_walk, spr_dome_alone_idle, spr_dome_alone_attack, spr_dome_alone_die),10,2,3);
	spawn_mon[2] = scr_makeMonster("Professor-Cerebrisk",1.5,5,array(spr_professor_walk, spr_professor_idle, spr_professor_attack, spr_professor_die),10,3,2);

	/// bosses
	spawn_boss[0] = scr_makeMonster("Tusk-A-Lot",0.5,55,array(spr_tusk_walk, spr_tusk_idle, spr_tusk_attack, spr_tusk_die),100,50,1);
	spawn_boss[1] = scr_makeMonster("Sub-Zero",0.25,110,array(spr_zero_walk, spr_zero_idle, spr_zero_attack, spr_zero_die),100,50,1);

	/// ---- THE TEN RESTYLED RIGS (region-zombies / region-bosses) ----------
	/// A row carries a RIG, not a sprite: array(walk, idle, attack, die), in
	/// ZOMB_ANIM's order (scr_zomb_art), so slot 0 is still "the walking art"
	/// for every existing reader.  The five rows above follow the same
	/// contract, so every creature in both banks plays four animations.
	///
	/// EACH NEW CREATURE IS ITS REGION'S LETTER.  Read the row as "slower and
	/// tougher the deeper in you go": Newly-Turned is quicker than anything in
	/// region 1 and just as frail; Bog-Wader trades its speed for body; by
	/// region 6 the Harvester is half Grumble-Mulch's pace with six times its
	/// blood.  The bosses climb the same way, and each one's wave ramp still
	/// comes from region_data's curve - these are the BASE numbers.
	spawn_mon[3] = scr_makeMonster("Newly-Turned",1.25,5,array(spr_newly_turned_walk, spr_newly_turned_idle, spr_newly_turned_attack, spr_newly_turned_die),10,1,6);
	spawn_mon[4] = scr_makeMonster("Bog-Wader",0.4,20,array(spr_bog_wader_walk, spr_bog_wader_idle, spr_bog_wader_attack, spr_bog_wader_die),10,2,4);
	spawn_mon[5] = scr_makeMonster("Sandblasted",1.75,9,array(spr_sand_blasted_walk, spr_sand_blasted_idle, spr_sand_blasted_attack, spr_sand_blasted_die),10,3,3);
	spawn_mon[6] = scr_makeMonster("Root-Bound",0.3,34,array(spr_root_bound_walk, spr_root_bound_idle, spr_root_bound_attack, spr_root_bound_die),10,4,3);
	spawn_mon[7] = scr_makeMonster("Shroud",2.0,14,array(spr_shroud_walk, spr_shroud_idle, spr_shroud_attack, spr_shroud_die),10,4,3);
	spawn_mon[8] = scr_makeMonster("Harvester",0.6,45,array(spr_harvester_walk, spr_harvester_idle, spr_harvester_attack, spr_harvester_die),10,5,4);

	spawn_boss[2] = scr_makeMonster("Foreman-Rustlung",0.4,160,array(spr_foreman_rustlung_walk, spr_foreman_rustlung_idle, spr_foreman_rustlung_attack, spr_foreman_rustlung_die),100,50,1);
	spawn_boss[3] = scr_makeMonster("Orchid-Widow",0.35,220,array(spr_orchid_walk, spr_orchid_idle, spr_orchid_attack, spr_orchid_die),100,50,1);
	spawn_boss[4] = scr_makeMonster("Bell-Ringer",0.3,300,array(spr_bell_ringer_walk, spr_bell_ringer_idle, spr_bell_ringer_attack, spr_bell_ringer_die),100,50,1);
	spawn_boss[5] = scr_makeMonster("Gardener",0.2,420,array(spr_gardener_walk, spr_gardener_idle, spr_gardener_attack, spr_gardener_die),100,50,1);

	/// the textbox portrait for each creature (MON.portrait) - used by the
	/// "Up Next..." popup.  Set here AFTER scr_makeMonster, not through it:
	/// its positional arguments are fragile (MON.maxLife sits at index 7).
	spawn_mon[0][MON.portrait] = spr_grumble_portrait;
	spawn_mon[1][MON.portrait] = spr_dome_portrait;
	spawn_mon[2][MON.portrait] = spr_cerebrisk_portrait;
	spawn_boss[0][MON.portrait] = spr_tusk_portrait;
	spawn_boss[1][MON.portrait] = spr_zero_portrait;

	/// ---- the restyled rigs' portraits -----------------------------------
	/// Named by the ART, not by the rig: the portrait sheets are
	/// spr_bogwader_portrait, spr_rootbound_portrait and spr_bellringer_portrait
	/// while the rigs are spr_bog_wader_*, spr_root_bound_* and spr_bell_ringer_*
	/// - a portrait is its own drawing, so its file name says so.
	///
	/// TWO ARE MISSING AND SAY SO (art-sandblasted-portrait): the art drop
	/// promised six walker portraits and delivered four.  -1 is the documented
	/// "no portrait", the popup guards on it, and test_content pins -1 to
	/// EXACTLY these two names - so a third creature cannot quietly join them,
	/// and neither can one of these two quietly stay -1 after its art lands.
	spawn_mon[3][MON.portrait] = spr_newly_turned_portrait;
	spawn_mon[4][MON.portrait] = spr_bogwader_portrait;
	spawn_mon[5][MON.portrait] = -1;   /// Sandblasted - no art yet
	spawn_mon[6][MON.portrait] = spr_rootbound_portrait;
	spawn_mon[7][MON.portrait] = -1;   /// Shroud - no art yet
	spawn_mon[8][MON.portrait] = spr_harvester_portrait;
	spawn_boss[2][MON.portrait] = spr_foreman_rustlung_portrait;
	spawn_boss[3][MON.portrait] = spr_orchid_widow_portrait;
	spawn_boss[4][MON.portrait] = spr_bellringer_portrait;
	spawn_boss[5][MON.portrait] = spr_gardener_portrait;

	/// ---- both banks, named out loud (LL-057) --------------------------
	/// The line that settles "the portraits are swapped", and now also
	/// "that creature has no rig": scr_zomb_art's report prints what each
	/// row ACTUALLY holds at runtime, so a stale build, a second writer of
	/// MON.portrait or a one-sprite rig shows up here instead of in a
	/// playtest.  walkers first, because a boot log reads top-down in the
	/// order the player meets them.
	zomb_bank_report(spawn_mon,  "walker");
	zomb_bank_report(spawn_boss, "boss");

	//------------- List Size
	spawn_pool = array_last_index(spawn_mon);
	spawn_index = 0;

	//------------- wave data
	wave_count = 0;
	wait_stuck = 0;      /// frames a wave has had monsters alive past its timer
	wait_valve_fired = false;  /// the 10-minute backstop has fired (LL-031)
	is_boss_wave = false;



}
