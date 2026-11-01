/// @description scr_iniTileBuilder(grid, min-val, max-val, back-img, blend, tile_w, tile_h, depth, cap-img, use_dual_grid=false, dual_grid_frame_map=undefined);
/// @param grid
/// @param min-val
/// @param max-val
/// @param back-img
/// @param blend
/// @param tile_w
/// @param tile_h
/// @param depth
/// @param cap-img
/// @param use_dual_grid Draw the atlas as a four-corner dual-grid terrain layer.
/// @param dual_grid_frame_map Optional array mapping masks 0..15 to zero-based atlas frames.
function scr_iniTileBuilder(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7, argument8, argument9=false, argument10=undefined) {
	var _oldGrid    = argument0,
	    height_     = ds_grid_height(_oldGrid),
	    width_      = ds_grid_width(_oldGrid),
	    _min        = argument1,
	    _max        = argument2,
	    _bg         = argument3,
	    _c1         = argument4,
	    _ww         = argument5,
	    _hh         = argument6,
	    _dp         = argument7,
	    _gnd        = argument8,
	    _useDualGrid = argument9,
	    _frameMap   = argument10;

	///--------------------- create and edit new grid
	var grid_ = ds_grid_create(width_, height_);
	ds_grid_copy(grid_, _oldGrid);

	///--------------------- calculate image indices only for the legacy background atlas
	var _wc = 0;
	if(!_useDualGrid) _wc = background_get_width(_bg) div _ww;

	//---------------------- turn data into an array
	var _data = [height_, width_, _min, _max, _bg, _c1, _ww, _hh, _dp, _wc, _gnd];

	if(_useDualGrid){
		// The legacy cardinal remap can erase diagonal-only cells. Dual-grid masks
		// handle those cells directly, so preserve the source height map here.
		var _scale = 0.2525;
		dual_grid_draw_layer(grid_, global.tileSystem, _bg,
		                     _min, _max, load_max,
		                     _ww, _hh, _dp, _scale, _scale, _c1,
		                     _frameMap, 0, 0);

		// Keep the existing full-cell top cap on the same height slices as before.
		if(load_max > _min && load_max < _max){
			dual_grid_draw_cells_equal(grid_, global.tileSystem, _gnd,
			                            load_max, 16, _ww, _hh, -45,
			                            _scale, _scale, make_colour_rgb(64, 37, 11),
			                            0, 0, -0.016, -0.016);
		}
	} else {
		/// remap values for the existing single-grid atlases
		for_grid(grid_, scr_remapValues, _data);

		/// build legacy tiles
		for_grid(grid_, scr_buildTiles, _data);
	}

	ds_grid_destroy(grid_);
}
