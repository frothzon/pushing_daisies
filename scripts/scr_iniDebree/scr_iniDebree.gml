/// @description  scr_iniDebree();
function scr_iniDebree() {

	global.debree = ds_queue_create();

	//------------- Max number of tiles
	global.maxDebree = clamp(150*global.clutterDensity,5,150);



}
