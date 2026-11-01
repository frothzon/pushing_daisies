/// @description Builds the rounded Dirt dual-grid atlas and terrain samples for review.
atlas_id = -1;
demo_tile_count = 0;
demo_grid_width = 16;
demo_grid_height = 10;
demo_world_x = 360;
demo_world_y = 130;

/// Build dual-grid frames from the original cardinal Dirt atlas so its real
/// outer-edge and concave-corner art can be reviewed in the test map.
var _bend_rotation_map = array_create(16, -1);
_bend_rotation_map[7] = 0;
_bend_rotation_map[11] = 90;
_bend_rotation_map[14] = 180;
_bend_rotation_map[13] = 270;
atlas_id = dual_grid_atlas_from_cardinal(spr_dirt_128x, true,
                                         spr_dirt_bend_overrides, _bend_rotation_map);
if(!sprite_exists(atlas_id) || sprite_get_number(atlas_id) != 17){
	scr_meta_log("DGRID", "ERROR converted Dirt atlas was not created");
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
var _manager_callable = is_callable(global.tileSystem.add_tile),
    _probe_grid = ds_exists(_grid, ds_type_grid),
    _probe_mask = dual_grid_mask_at(_grid, 1, 1, 0, 2),
    _atlas_exists = sprite_exists(atlas_id),
    _atlas_frames = _atlas_exists ? sprite_get_number(atlas_id) : 0;
scr_meta_log("DGRID", "preflight grid=", _probe_grid,
	         " size=", ds_grid_width(_grid), "x", ds_grid_height(_grid),
	         " sample_cell=", _grid[# 0, 0], " sample_mask=", _probe_mask,
	         " manager_struct=", is_struct(global.tileSystem),
	         " manager_callable=", _manager_callable,
	         " atlas_exists=", _atlas_exists,
	         " atlas_is_real=", is_real(atlas_id),
	         " atlas_frames=", _atlas_frames);

demo_tile_count = dual_grid_draw_layer(_grid, global.tileSystem, atlas_id,
	                                   0, 2, undefined,
	                                   32, 32, -10, 0.25, 0.25, c_white,
	                                   undefined, demo_world_x, demo_world_y, true);
ds_grid_destroy(_grid);
if(demo_tile_count <= 0){
	scr_meta_log("DGRID", "ERROR renderer returned no tiles");
}
scr_meta_log("DGRID", "demo ready atlas_frames=", sprite_get_number(atlas_id),
	         " rendered_tiles=", demo_tile_count,
	         " map=", demo_grid_width, "x", demo_grid_height);
