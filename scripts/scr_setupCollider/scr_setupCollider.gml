/// @description  scr_setupCollider();
function scr_setupCollider() {

	//----------------- Setup Variables
	globalvar WORLD;
	WORLD = id;

	// cell size in power of 2
	cell_w = 32;
	cell_h = 16;

	// get bit shift value for cell size
	cell_shift_w = logn(2, cell_w);
	cell_shift_h = logn(2, cell_h);

	// get other variables
	grid_w = room_width >> cell_shift_w;
	grid_h = room_height >> cell_shift_h;


	collider = ds_grid_create(grid_w,grid_h);
	ds_grid_clear(collider,0);






}
