/// @description  scr_gridSetObject(grid,obj,value)
/// @param grid
/// @param obj
/// @param value
function scr_gridSetObject(argument0, argument1, argument2) {
	/*
	    This script adds an instance to the collider
	    using its bounding box
	*/

	with(argument1){
	    var _grid = argument0,
	        _obj = id,
	        _SW = room_width/ds_grid_width(_grid),
	        _SH = room_height/ds_grid_height(_grid);
        
	    var _x1 = _obj.bbox_left div _SW,
	        _y1 = _obj.bbox_top div _SH,
	        _x2 = _obj.bbox_right div _SW,
	        _y2 = _obj.bbox_bottom div _SH;
    
	    ds_grid_set_region(_grid,_x1,_y1,_x2,_y2,argument2);
	}



}
