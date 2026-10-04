/// @description  scr_addDebree(back,width,heght,ind_x,ind_y,x,y,depth);
/// @param back
/// @param width
/// @param heght
/// @param ind_x
/// @param ind_y
/// @param x
/// @param y
/// @param depth
function scr_addDebree(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7) {
	/*
	    works just like tile_add but the tiles are automatically
	    destroyed FIFO style when the limit is reached
	    ----------------------------------------------
	    back = background image
	    width = tile width
	    height = tile height
	    ind_x = horizontal index offset in tile
	    ind_y = virtical index offset in tile
	    x = x position to place in room
	    y = y position to place in room
	    depth = depth of image in room
	    -----------------------------------------------
	*/
	//---------------------------------- Get tile position
	var _bck    = argument0,
	    _w      = argument1,
	    _h      = argument2,
	    _ind_x  = argument3,
	    _ind_y  = argument4,
	    _x      = argument5,
	    _y      = argument6,
	    _d      = argument7;
	/// calculate left and top
	var _top    = _h*_ind_y,
	    _left   = _w*_ind_x;


	//---------------------------------- Add tile to QUEUE
	var _tile = tile_add(_bck,_left,_top,_w,_h,_x-_w*0.5,_y-_h*0.5,_d);
	ds_queue_enqueue(global.debree,_tile);
	if(ds_queue_size(global.debree) > global.maxDebree){
	    var _overflow = ds_queue_dequeue(global.debree);
	    tile_delete(_overflow);
	}



}
