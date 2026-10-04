/// @description  scr_collider_reset();
function scr_collider_reset() {
	/*
	    Reset all values in collider to 0
	*/

	var _grid = WORLD.collider;

	ds_grid_clear(_grid,0);



}
