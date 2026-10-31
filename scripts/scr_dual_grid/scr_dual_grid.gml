/// @description Reusable dual-grid terrain masks and sprite-layer renderer.
///
/// A logical grid stores filled/empty cells. Render vertices sit at the
/// corners between those cells; each rendered tile samples the four cells
/// touching that vertex. Bit order is TL=1, TR=2, BL=4, BR=8. Mask 0 is empty.
/// The default atlas convention is frame 1..15 == mask 1..15; frame 16 is
/// intentionally available for a full-cell cap overlay.

/// Build a four-corner occupancy mask without reading a grid.
function dual_grid_mask_from_corners(_top_left, _top_right, _bottom_left, _bottom_right) {
	return ((_top_left ? 1 : 0)
	      + (_top_right ? 2 : 0)
	      + (_bottom_left ? 4 : 0)
	      + (_bottom_right ? 8 : 0));
}

/// True when one logical terrain value belongs to this elevation band.
function dual_grid_value_filled(_value, _min, _max, _override = undefined) {
	if(!is_real(_value) || !is_real(_min) || !is_real(_max)) return false;
	if(_value > _min && _value < _max) return true;
	return !is_undefined(_override) && is_real(_override) && _value == _override;
}

/// Safe query for one logical cell. Cells outside the grid are empty.
function dual_grid_cell_filled(_grid, _cell_x, _cell_y, _min, _max, _override = undefined) {
	if(!is_real(_grid) || !ds_exists(_grid, ds_type_grid)) return false;
	if(!is_real(_cell_x) || !is_real(_cell_y)
	   || floor(_cell_x) != _cell_x || floor(_cell_y) != _cell_y) return false;
	if(!is_real(_min) || !is_real(_max)) return false;

	var _width = ds_grid_width(_grid),
	    _height = ds_grid_height(_grid);
	if(_cell_x < 0 || _cell_x >= _width || _cell_y < 0 || _cell_y >= _height) return false;
	return dual_grid_value_filled(_grid[# _cell_x, _cell_y], _min, _max, _override);
}

/// Return the four-cell mask around a render-grid vertex (0..width, 0..height).
/// Returns -1 for invalid input; out-of-map logical cells count as empty.
function dual_grid_mask_at(_grid, _vertex_x, _vertex_y, _min, _max, _override = undefined) {
	if(!is_real(_grid) || !ds_exists(_grid, ds_type_grid)) return -1;
	if(!is_real(_vertex_x) || !is_real(_vertex_y)
	   || floor(_vertex_x) != _vertex_x || floor(_vertex_y) != _vertex_y) return -1;
	if(!is_real(_min) || !is_real(_max)) return -1;

	var _width = ds_grid_width(_grid),
	    _height = ds_grid_height(_grid);
	if(_vertex_x < 0 || _vertex_x > _width
	   || _vertex_y < 0 || _vertex_y > _height) return -1;

	var _mask = 0,
	    _left = _vertex_x - 1,
	    _right = _vertex_x,
	    _top = _vertex_y - 1,
	    _bottom = _vertex_y;

	if(_left >= 0 && _top >= 0
	   && dual_grid_value_filled(_grid[# _left, _top], _min, _max, _override)) _mask += 1;
	if(_right < _width && _top >= 0
	   && dual_grid_value_filled(_grid[# _right, _top], _min, _max, _override)) _mask += 2;
	if(_left >= 0 && _bottom < _height
	   && dual_grid_value_filled(_grid[# _left, _bottom], _min, _max, _override)) _mask += 4;
	if(_right < _width && _bottom < _height
	   && dual_grid_value_filled(_grid[# _right, _bottom], _min, _max, _override)) _mask += 8;
	return _mask;
}

/// Default atlas map: 0 is empty; frame N draws corner mask N for masks 1..15.
function dual_grid_default_frame_map() {
	var _frames = array_create(16, -1);
	for(var _mask = 1; _mask < 16; _mask++) _frames[_mask] = _mask;
	return _frames;
}

/// Resolve a four-cell mask through an optional atlas lookup table.
/// Missing, empty, or invalid frames return -1 and are skipped by the renderer.
function dual_grid_frame_for_mask(_mask, _frame_map = undefined) {
	if(!is_real(_mask) || floor(_mask) != _mask || _mask < 0 || _mask > 15) return -1;
	if(_mask == 0) return -1;

	var _frame = _mask;
	if(!is_undefined(_frame_map)){
		if(!is_array(_frame_map) || array_length(_frame_map) < 16) return -1;
		_frame = _frame_map[_mask];
	}
	if(!is_real(_frame) || floor(_frame) != _frame || _frame < 0) return -1;
	return _frame;
}

/// Draw one logical terrain band on the dual grid.
/// Output dimensions are one cell wider/taller; each tile is centered on a
/// logical-cell corner and outside-map samples are empty. A non-band override
/// extends corner adjacency, but at least one in-band cell must touch a vertex.
/// Returns the number of tile sprites added.
function dual_grid_draw_layer(_grid, _tile_manager, _atlas, _min, _max, _override,
                              _cell_w, _cell_h, _depth,
                              _scale_x = 0.25, _scale_y = 0.25, _blend = c_white,
                              _frame_map = undefined, _world_x = 0, _world_y = 0) {
	if(!is_real(_grid) || !ds_exists(_grid, ds_type_grid)) return 0;
	if(!is_struct(_tile_manager)
	   || !variable_struct_exists(_tile_manager, "add_tile")
	   || !is_callable(_tile_manager.add_tile)) return 0;
	if(!is_real(_atlas) || !sprite_exists(_atlas)) return 0;
	if(!is_real(_min) || !is_real(_max)
	   || !is_real(_cell_w) || _cell_w <= 0
	   || !is_real(_cell_h) || _cell_h <= 0
	   || !is_real(_depth)
	   || !is_real(_scale_x) || _scale_x <= 0
	   || !is_real(_scale_y) || _scale_y <= 0
	   || !is_real(_world_x) || !is_real(_world_y)) return 0;
	if(!is_undefined(_frame_map)
	   && (!is_array(_frame_map) || array_length(_frame_map) < 16)) return 0;

	var _grid_w = ds_grid_width(_grid),
	    _grid_h = ds_grid_height(_grid),
	    _tile_w = sprite_get_width(_atlas) * _scale_x,
	    _tile_h = sprite_get_height(_atlas) * _scale_y,
	    _frame_count = sprite_get_number(_atlas),
	    _drawn = 0;

	for(var _vy = 0; _vy <= _grid_h; _vy++){
		for(var _vx = 0; _vx <= _grid_w; _vx++){
			var _mask = dual_grid_mask_at(_grid, _vx, _vy, _min, _max);
			if(_mask <= 0) continue;
			if(!is_undefined(_override)){
				_mask = dual_grid_mask_at(_grid, _vx, _vy, _min, _max, _override);
			}
			var _frame = dual_grid_frame_for_mask(_mask, _frame_map);
			if(_frame < 0 || _frame >= _frame_count) continue;

			var _x = _world_x + _vx * _cell_w - _tile_w * 0.5
			          + sprite_get_xoffset(_atlas) * _scale_x,
			    _y = _world_y + _vy * _cell_h - _tile_h * 0.5
			          + sprite_get_yoffset(_atlas) * _scale_y;
			_tile_manager.add_tile(_x, _y, _atlas, _frame, _depth,
			                       _scale_x, _scale_y, _blend);
			_drawn++;
		}
	}
	return _drawn;
}

/// Draw a cell-aligned overlay such as the existing top-soil cap.
/// Returns the number of cells drawn; frame and color remain caller-owned.
function dual_grid_draw_cells_equal(_grid, _tile_manager, _atlas, _value, _frame,
                                    _cell_w, _cell_h, _depth,
                                    _scale_x = 0.25, _scale_y = 0.25, _blend = c_white,
                                    _world_x = 0, _world_y = 0,
                                    _offset_x = 0, _offset_y = 0) {
	if(!is_real(_grid) || !ds_exists(_grid, ds_type_grid)) return 0;
	if(!is_struct(_tile_manager)
	   || !variable_struct_exists(_tile_manager, "add_tile")
	   || !is_callable(_tile_manager.add_tile)) return 0;
	if(!is_real(_atlas) || !sprite_exists(_atlas)) return 0;
	if(!is_real(_value) || !is_real(_frame) || floor(_frame) != _frame
	   || _frame < 0 || _frame >= sprite_get_number(_atlas)) return 0;
	if(!is_real(_cell_w) || _cell_w <= 0 || !is_real(_cell_h) || _cell_h <= 0
	   || !is_real(_depth) || !is_real(_scale_x) || _scale_x <= 0
	   || !is_real(_scale_y) || _scale_y <= 0
	   || !is_real(_world_x) || !is_real(_world_y)
	   || !is_real(_offset_x) || !is_real(_offset_y)) return 0;

	var _width = ds_grid_width(_grid),
	    _height = ds_grid_height(_grid),
	    _origin_x = sprite_get_xoffset(_atlas) * _scale_x,
	    _origin_y = sprite_get_yoffset(_atlas) * _scale_y,
	    _drawn = 0;
	for(var _y = 0; _y < _height; _y++){
		for(var _x = 0; _x < _width; _x++){
			if(_grid[# _x, _y] != _value) continue;
			_tile_manager.add_tile(_world_x + _x * _cell_w + _offset_x + _origin_x,
			                       _world_y + _y * _cell_h + _offset_y + _origin_y,
			                       _atlas, _frame, _depth, _scale_x, _scale_y, _blend);
			_drawn++;
		}
	}
	return _drawn;
}
