/// @description  remove light

if(scr_isValidInstance(tower_light)){
    instance_destroy(tower_light);
}

/// clear grid
mp_grid_clear_rectangle(LEVEL.path_grid, bbox_left, bbox_top, bbox_right, bbox_bottom);

