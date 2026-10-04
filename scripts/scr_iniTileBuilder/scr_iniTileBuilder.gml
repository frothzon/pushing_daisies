/// @description  scr_iniTileBuilder(grid, min-val, max-val, back-img, blend, tile_w, tile_h, depth);
/// @param grid
/// @param  min-val
/// @param  max-val
/// @param  back-img
/// @param  blend
/// @param  tile_w
/// @param  tile_h
/// @param  depth
function scr_iniTileBuilder(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7) {

	var _oldGrid    = argument0,
	    height_     = ds_grid_height(_oldGrid),
	    width_      = ds_grid_width(_oldGrid),
	    _min        = argument1,
	    _max        = argument2,
	    _bg         = argument3,
	    _c1         = argument4,
	    _ww         = argument5,
	    _hh         = argument6,
	    _dp         = argument7;
    
	///--------------------- create and edit new grid
	var grid_ = ds_grid_create(width_,height_);
	ds_grid_copy(grid_,_oldGrid);

	///--------------------- calculate image indices
	var _wc = background_get_width(_bg) div _ww;

	//---------------------- turn data into an array
	var _data = array(height_,width_,_min,_max,_bg,_c1,_ww,_hh,_dp,_wc);

	/// remap values
	for_grid(grid_,scr_remapValues,_data);

	/// build tiles
	for_grid(grid_,scr_buildTiles,_data);

	ds_grid_destroy(grid_);



}
