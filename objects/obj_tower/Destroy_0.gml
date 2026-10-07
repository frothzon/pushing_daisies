/// @description  remove light

if(scr_isValidInstance(tower_light)){
    instance_destroy(tower_light);
}

/// clear grid - EXACTLY the cell Create_0 blocked.  Remembering the CELL
/// (rather than re-deriving a rectangle) means the add and the clear
/// cannot drift apart, whatever the tower's image_xscale has become
/// (LL-025 / LL-027).
if(variable_instance_exists(id, "grid_col")){
    mp_grid_clear_cell(LEVEL.path_grid, grid_col, grid_row);
}

/// Wake every monster so it re-paths against the now-clearer grid.  A
/// tower being removed is the moment a monster that was walking backwards
/// can start moving forwards again, and without this nudge nothing would
/// ever tell it to try (roadmap 4.4.1 acceptance test 2).
with(obj_mon){
    path_retry = 0;
    path_escape = false;
    alarm[0] = 1;
}

