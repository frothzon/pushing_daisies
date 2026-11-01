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
	if(!ds_exists(_grid, ds_type_grid)) return false;
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
	if(!ds_exists(_grid, ds_type_grid)) return -1;
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
                              _frame_map = undefined, _world_x = 0, _world_y = 0,
                              _debug = false) {
	if(!ds_exists(_grid, ds_type_grid)){
		if(_debug) scr_meta_log("DGRID", "renderer stop=grid_exists");
		return 0;
	}
	if(_debug) scr_meta_log("DGRID", "renderer stage=grid_ok");
	if(!is_struct(_tile_manager)){
		if(_debug) scr_meta_log("DGRID", "renderer stop=manager_struct");
		return 0;
	}
	if(!is_callable(_tile_manager.add_tile)){
		if(_debug) scr_meta_log("DGRID", "renderer stop=manager_callable");
		return 0;
	}
	if(_debug) scr_meta_log("DGRID", "renderer stage=manager_ok");
	if(!sprite_exists(_atlas)){
		if(_debug) scr_meta_log("DGRID", "renderer stop=atlas_exists atlas_is_real=", is_real(_atlas));
		return 0;
	}
	if(_debug) scr_meta_log("DGRID", "renderer stage=atlas_ok atlas_is_real=", is_real(_atlas));
	if(!is_real(_min) || !is_real(_max)
	   || !is_real(_cell_w) || _cell_w <= 0
	   || !is_real(_cell_h) || _cell_h <= 0
	   || !is_real(_depth)
	   || !is_real(_scale_x) || _scale_x <= 0
	   || !is_real(_scale_y) || _scale_y <= 0
	   || !is_real(_world_x) || !is_real(_world_y)){
		if(_debug) scr_meta_log("DGRID", "renderer stop=numeric_params min=", _min,
		                       " max=", _max, " cell=", _cell_w, "x", _cell_h,
		                       " depth=", _depth, " scale=", _scale_x, "x", _scale_y,
		                       " world=", _world_x, ",", _world_y);
		return 0;
	}
	if(_debug) scr_meta_log("DGRID", "renderer stage=params_ok");
	if(!is_undefined(_frame_map)){
		if(!is_array(_frame_map)){
			if(_debug) scr_meta_log("DGRID", "renderer stop=frame_map_not_array");
			return 0;
		}
		if(array_length(_frame_map) < 16){
			if(_debug) scr_meta_log("DGRID", "renderer stop=frame_map_short length=", array_length(_frame_map));
			return 0;
		}
	}
	if(_debug) scr_meta_log("DGRID", "renderer stage=frame_map_ok");

	var _grid_w = ds_grid_width(_grid),
	    _grid_h = ds_grid_height(_grid),
	    _tile_w = sprite_get_width(_atlas) * _scale_x,
	    _tile_h = sprite_get_height(_atlas) * _scale_y,
	    _frame_count = sprite_get_number(_atlas),
	    _drawn = 0,
	    _vertices = 0,
	    _zero_masks = 0,
	    _invalid_masks = 0,
	    _valid_masks = 0,
	    _bad_frames = 0,
	    _add_calls = 0,
	    _first_bad_mask = -1,
	    _first_bad_frame = -1,
	    _mask_counts = array_create(16, 0);

	if(_debug) scr_meta_log("DGRID", "renderer stage=loop_start vertices=",
	                       (_grid_w + 1) * (_grid_h + 1),
	                       " grid=", _grid_w, "x", _grid_h,
	                       " frames=", _frame_count, " atlas_is_real=", is_real(_atlas));

	for(var _vy = 0; _vy <= _grid_h; _vy++){
		for(var _vx = 0; _vx <= _grid_w; _vx++){
			_vertices++;
			var _mask = dual_grid_mask_at(_grid, _vx, _vy, _min, _max);
			if(_mask < 0){
				_invalid_masks++;
				if(_first_bad_mask < 0) _first_bad_mask = _mask;
				continue;
			}
			if(_mask == 0){ _zero_masks++; continue; }
			if(!is_undefined(_override)) _mask = dual_grid_mask_at(_grid, _vx, _vy, _min, _max, _override);
			if(_mask < 0){
				_invalid_masks++;
				if(_first_bad_mask < 0) _first_bad_mask = _mask;
				continue;
			}
			if(_mask == 0){ _zero_masks++; continue; }
			_valid_masks++;
			_mask_counts[_mask]++;
			var _frame = dual_grid_frame_for_mask(_mask, _frame_map);
			if(_frame < 0 || _frame >= _frame_count){
				_bad_frames++;
				if(_first_bad_frame < 0) _first_bad_frame = _frame;
				continue;
			}

			var _x = _world_x + _vx * _cell_w - _tile_w * 0.5
			          + sprite_get_xoffset(_atlas) * _scale_x,
			    _y = _world_y + _vy * _cell_h - _tile_h * 0.5
			          + sprite_get_yoffset(_atlas) * _scale_y;
			if(_debug && _add_calls == 0) scr_meta_log("DGRID", "renderer first_add begin vertex=", _vx, ",", _vy,
			                                                   " mask=", _mask, " frame=", _frame,
			                                                   " pos=", _x, ",", _y);
			var _tile_id = _tile_manager.add_tile(_x, _y, _atlas, _frame, _depth,
			                                      _scale_x, _scale_y, _blend);
			_add_calls++;
			_drawn++;
			if(_debug && _add_calls == 1) scr_meta_log("DGRID", "renderer first_add returned id=", _tile_id,
			                                                   " undefined=", is_undefined(_tile_id));
		}
	}
	var _mask_summary = "";
	for(var _mi = 1; _mi < 16; _mi++){
		if(_mask_counts[_mi] <= 0) continue;
		if(_mask_summary != "") _mask_summary += ",";
		_mask_summary += string(_mi) + ":" + string(_mask_counts[_mi]);
	}
	if(_debug) scr_meta_log("DGRID", "renderer stats vertices=", _vertices,
	                       " mask0=", _zero_masks, " invalid_mask=", _invalid_masks,
	                       " valid_mask=", _valid_masks, " bad_frame=", _bad_frames,
	                       " add_calls=", _add_calls, " drawn=", _drawn,
	                       " first_bad_mask=", _first_bad_mask,
	                       " first_bad_frame=", _first_bad_frame,
	                       " mask_counts={", _mask_summary, "}");
	return _drawn;
}

/// Draw a cell-aligned overlay such as the existing top-soil cap.
/// Returns the number of cells drawn; frame and color remain caller-owned.
function dual_grid_draw_cells_equal(_grid, _tile_manager, _atlas, _value, _frame,
                                    _cell_w, _cell_h, _depth,
                                    _scale_x = 0.25, _scale_y = 0.25, _blend = c_white,
                                    _world_x = 0, _world_y = 0,
                                    _offset_x = 0, _offset_y = 0) {
	if(!ds_exists(_grid, ds_type_grid)) return 0;
	if(!is_struct(_tile_manager)) return 0;
	if(!is_callable(_tile_manager.add_tile)) return 0;
	if(!sprite_exists(_atlas)) return 0;
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


/// Convert a cardinal-neighbor atlas into corner-mask frames using its existing edge art.
/// Output frames 0..15 map directly to masks; source frame 16 is copied as the full-cell cap.
/// Optional overrides use one 128x128 bend sprite plus a 16-entry map of 0/90/180/270 rotations.
function dual_grid_atlas_from_cardinal(_source, _debug = false, _bend_sprite = -1, _bend_rotation_map = undefined) {
	if(!sprite_exists(_source)){
		if(_debug) scr_meta_log("DGRID", "atlas stop=source_sprite_missing");
		return -1;
	}
	var _source_frames = sprite_get_number(_source),
	    _source_w = sprite_get_width(_source),
	    _source_h = sprite_get_height(_source);
	if(_source_frames < 17 || _source_w != 128 || _source_h != 128){
		if(_debug) scr_meta_log("DGRID", "atlas stop=source_contract frames=", _source_frames,
		                       " size=", _source_w, "x", _source_h,
		                       " expected=17 frames 128x128");
		return -1;
	}

	var _bend_sprite_ready = false,
	    _bend_map_ready = false,
	    _bend_sprite_frames = 0;
	if(!is_undefined(_bend_sprite)) _bend_sprite_ready = sprite_exists(_bend_sprite);
	if(_bend_sprite_ready){
		if(sprite_get_width(_bend_sprite) != 128 || sprite_get_height(_bend_sprite) != 128){
			_bend_sprite_ready = false;
		} else {
			_bend_sprite_frames = sprite_get_number(_bend_sprite);
			if(_bend_sprite_frames < 1) _bend_sprite_ready = false;
		}
	}
	if(is_array(_bend_rotation_map)) _bend_map_ready = array_length(_bend_rotation_map) >= 16;
	if(_debug) scr_meta_log("DGRID", "atlas bend_overrides sprite=", _bend_sprite_ready,
	                       " map=", _bend_map_ready,
	                       " frames=", _bend_sprite_frames);

	var _surface = surface_create(128, 128);
	if(!surface_exists(_surface)){
		if(_debug) scr_meta_log("DGRID", "atlas stop=surface_create");
		return -1;
	}
	var _old_color = draw_get_color(),
	    _old_alpha = draw_get_alpha(),
	    _atlas = -1;
	draw_set_color(c_white);
	draw_set_alpha(1);

	for(var _mask = 0; _mask < 16; _mask++){
		surface_set_target(_surface);
		draw_clear_alpha(c_black, 0);
		var _source_frames_for_mask = "",
		    _bend_rotation = -1;
		if(_mask > 0 && _bend_sprite_ready && _bend_map_ready){
			var _candidate_bend_rotation = _bend_rotation_map[_mask];
			if(is_real(_candidate_bend_rotation)
			   && floor(_candidate_bend_rotation) == _candidate_bend_rotation
			   && (_candidate_bend_rotation == 0
			       || _candidate_bend_rotation == 90
			       || _candidate_bend_rotation == 180
			       || _candidate_bend_rotation == 270)){
				_bend_rotation = _candidate_bend_rotation;
			}
		}
		if(_bend_rotation >= 0){
			switch(_bend_rotation){
				case 0:
					draw_sprite_part(_bend_sprite, 0, 0, 0, 128, 128, 0, 0);
					break;
				case 90:
					draw_sprite_pos(_bend_sprite, 0,
					                128, 0, 128, 128, 0, 128, 0, 0, 1);
					break;
				case 180:
					draw_sprite_pos(_bend_sprite, 0,
					                128, 128, 0, 128, 0, 0, 128, 0, 1);
					break;
				case 270:
					draw_sprite_pos(_bend_sprite, 0,
					                0, 128, 0, 0, 128, 0, 128, 128, 1);
					break;
			}
		} else if(_mask > 0){
			for(var _corner = 0; _corner < 4; _corner++){
				var _occupied = floor(_mask / power(2, _corner)) mod 2;
				if(_occupied == 0) continue;

				var _north = 1,
				    _east = 1,
				    _west = 1,
				    _south = 1;
				switch(_corner){
					case 0: _east = floor(_mask / 2) mod 2; _south = floor(_mask / 4) mod 2; break;
					case 1: _west = _mask mod 2; _south = floor(_mask / 8) mod 2; break;
					case 2: _north = _mask mod 2; _east = floor(_mask / 8) mod 2; break;
					case 3: _north = floor(_mask / 2) mod 2; _west = floor(_mask / 4) mod 2; break;
				}
				var _source_frame = 1 + _east + _north * 2 + _west * 4 + _south * 8,
				    _source_corner = 3 - _corner,
				    _source_x = (_source_corner mod 2) * 64,
				    _source_y = floor(_source_corner / 2) * 64,
				    _dest_x = (_corner mod 2) * 64,
				    _dest_y = floor(_corner / 2) * 64;
				draw_sprite_part(_source, _source_frame, _source_x, _source_y, 64, 64,
				                _dest_x, _dest_y);
				if(_source_frames_for_mask != "") _source_frames_for_mask += ",";
				_source_frames_for_mask += string(_corner) + "=" + string(_source_frame);
			}
		}
		surface_reset_target();

		if(_mask == 0){
			_atlas = sprite_create_from_surface(_surface, 0, 0, 128, 128,
			                                     false, false, 64, 64);
		} else if(sprite_exists(_atlas)){
			sprite_add_from_surface(_atlas, _surface, 0, 0, 128, 128, false, false);
		}
		if(_debug){
			if(_bend_rotation >= 0) scr_meta_log("DGRID", "atlas mask=", _mask,
			                                " bend_rotation=", _bend_rotation);
			else scr_meta_log("DGRID", "atlas mask=", _mask,
			                  " cardinal_frames={", _source_frames_for_mask, "}");
		}
	}

	/// Preserve the existing full-cell/top-soil cap in output frame 16.
	surface_set_target(_surface);
	draw_clear_alpha(c_black, 0);
	draw_sprite_part(_source, 16, 0, 0, 128, 128, 0, 0);
	surface_reset_target();
	if(sprite_exists(_atlas)) sprite_add_from_surface(_atlas, _surface, 0, 0, 128, 128, false, false);
	surface_free(_surface);
	draw_set_color(_old_color);
	draw_set_alpha(_old_alpha);

	if(!sprite_exists(_atlas) || sprite_get_number(_atlas) != 17){
		if(sprite_exists(_atlas)) sprite_delete(_atlas);
		if(_debug) scr_meta_log("DGRID", "atlas stop=output_contract frames=",
		                       sprite_exists(_atlas) ? sprite_get_number(_atlas) : 0,
		                       " expected=17");
		return -1;
	}
	if(_debug) scr_meta_log("DGRID", "atlas ready source_frames=", _source_frames,
	                       " output_frames=", sprite_get_number(_atlas),
	                       " origin=64,64 cap_frame=16",
	                       " bend_sprite=", _bend_sprite_ready,
	                       " bend_map=", _bend_map_ready);
	return _atlas;
}