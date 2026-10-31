/// @description Builds a procedural atlas and terrain samples for dual-grid review.
atlas_id = -1;
demo_tile_count = 0;
demo_grid_width = 16;
demo_grid_height = 10;
demo_world_x = 360;
demo_world_y = 130;

var _pattern_surface = surface_create(128, 128),
    _atlas_surface = surface_create(128, 128);
if(!surface_exists(_pattern_surface) || !surface_exists(_atlas_surface)){
	if(surface_exists(_pattern_surface)) surface_free(_pattern_surface);
	if(surface_exists(_atlas_surface)) surface_free(_atlas_surface);
	scr_meta_log("DGRID", "ERROR demo surfaces could not be created");
	exit;
}

var _old_color = draw_get_color(),
    _old_alpha = draw_get_alpha();

/// Build a repeating test texture for one logical terrain cell.
surface_set_target(_pattern_surface);
draw_clear_alpha(c_black, 0);
draw_set_alpha(1);
draw_set_color(make_colour_rgb(97, 142, 71));
draw_rectangle(0, 0, 127, 127, false);
draw_set_color(make_colour_rgb(85, 127, 64));
draw_circle(28, 30, 12, false);
draw_circle(94, 29, 10, false);
draw_circle(63, 91, 13, false);
draw_set_color(make_colour_rgb(125, 164, 88));
draw_circle(28, 30, 7, false);
draw_circle(94, 29, 6, false);
draw_circle(63, 91, 8, false);
draw_line(20, 34, 29, 27);
draw_line(88, 32, 97, 26);
draw_line(56, 94, 66, 87);
surface_reset_target();
draw_set_color(c_white);
draw_set_alpha(1);

/// Each dual-grid frame contains the matching quarter of the repeated cell
/// texture for every occupied TL/TR/BL/BR corner bit.
surface_set_target(_atlas_surface);
for(var _mask = 0; _mask <= 15; _mask++){
	draw_clear_alpha(c_black, 0);
	for(var _corner = 0; _corner < 4; _corner++){
		var _bit = floor(_mask / power(2, _corner)) mod 2;
		if(_bit == 0) continue;

		var _dest_x = (_corner mod 2) * 64,
		    _dest_y = floor(_corner / 2) * 64,
		    _texture_corner = 3 - _corner,
		    _source_x = (_texture_corner mod 2) * 64,
		    _source_y = floor(_texture_corner / 2) * 64;
		draw_surface_part(_pattern_surface, _source_x, _source_y, 64, 64,
		                  _dest_x, _dest_y);
	}

	if(_mask == 0){
		atlas_id = sprite_create_from_surface(_atlas_surface, 0, 0, 128, 128,
		                                     false, false, 64, 64);
	} else if(sprite_exists(atlas_id)){
		sprite_add_from_surface(atlas_id, _atlas_surface, 0, 0, 128, 128,
		                        false, false);
	}
}
surface_reset_target();
surface_free(_pattern_surface);
surface_free(_atlas_surface);
draw_set_color(_old_color);
draw_set_alpha(_old_alpha);

if(!sprite_exists(atlas_id) || sprite_get_number(atlas_id) != 16){
	scr_meta_log("DGRID", "ERROR demo atlas frames=",
	             sprite_exists(atlas_id) ? sprite_get_number(atlas_id) : 0,
	             " expected=16");
	exit;
}

/// Solid field with a hole, a cut-in corner, a map-edge boundary and two
/// cells that touch diagonally only.
var _grid = ds_grid_create(demo_grid_width, demo_grid_height);
ds_grid_clear(_grid, 0);
for(var _y = 0; _y < 9; _y++){
	for(var _x = 0; _x < 10; _x++) ds_grid_set(_grid, _x, _y, 1);
}
ds_grid_set(_grid, 4, 3, 0);
ds_grid_set(_grid, 4, 4, 0);
ds_grid_set(_grid, 5, 4, 0);
for(var _cut_y = 0; _cut_y < 3; _cut_y++) ds_grid_set(_grid, 7, _cut_y, 0);
ds_grid_set(_grid, 11, 1, 1);
ds_grid_set(_grid, 12, 2, 1);
ds_grid_set(_grid, 15, 8, 1);

if(!variable_global_exists("tileSystem") || !is_struct(global.tileSystem)){
	ds_grid_destroy(_grid);
	scr_meta_log("DGRID", "ERROR tile manager is unavailable");
	exit;
}
demo_tile_count = dual_grid_draw_layer(_grid, global.tileSystem, atlas_id,
	                                   0, 2, undefined,
	                                   32, 32, -10, 0.25, 0.25, c_white,
	                                   undefined, demo_world_x, demo_world_y);
ds_grid_destroy(_grid);
scr_meta_log("DGRID", "demo ready atlas_frames=", sprite_get_number(atlas_id),
	         " rendered_tiles=", demo_tile_count,
	         " map=", demo_grid_width, "x", demo_grid_height);
