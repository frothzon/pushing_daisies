/// @description  scr_colliderAddObject();
function scr_colliderAddObject() {
	/*
	    This script adds an instance to the collider
	    using its bounding box
	*/

	var _SW = WORLD.cell_shift_w,
	    _SH = WORLD.cell_shift_h,
	    _grid = WORLD.collider;
    
	var _x1 = bbox_left >> _SW,
	    _y1 = bbox_top >> _SH,
	    _x2 = bbox_right >> _SW,
	    _y2 = bbox_bottom >> _SH;

	ds_grid_set_region(_grid,_x1,_y1,_x2,_y2,1);



}
