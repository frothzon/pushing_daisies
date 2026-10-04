/// @description setup_partsys();
function setup_partsys() {
	/*
	Created by: Rayu Johnson
	This function creates a new particle system
	*/


	globalvar SYS_POS, ENGINE, _partArray;
	SYS_POS[0] = part_system_create();
	SYS_POS[1] = part_system_create();
	SYS_POS[2] = part_system_create();
	ENGINE = id;
	_partArray = -1;

	/*******************************************/
	part_system_depth( SYS_POS[0], 256);
	part_system_depth( SYS_POS[1], 0);
	part_system_depth( SYS_POS[2], -256);

	pt_acid_puff  = ini_part_geyser(pt_shard);
	pt_daisy_puff = ini_part_puff();
	pt_explode    = ini_part_explode();
	pt_spikes     = setup_animate(pt_groundClaw,5,10);
	pt_clodPuff   = setup_splash(pt_rock);
	pt_bloody     = setup_splash(pt_blood);
	pt_splashy    = setup_splatter(pt_water);

	/// spike dirt flinging
	var _amt = global.clutterDensity;
	part_type_step(pt_spikes, _amt, pt_clodPuff);





}
