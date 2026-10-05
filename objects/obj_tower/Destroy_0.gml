/// @description  remove light

if(scr_isValidInstance(tower_light)){
    instance_destroy(tower_light);
}

/// clear grid
mp_grid_clear_rectangle(LEVEL.path_grid, bbox_left, bbox_top, bbox_right, bbox_bottom);

/// Wake every monster so it re-paths against the now-clearer grid.  A
/// tower being removed is the moment a monster that was walking backwards
/// can start moving forwards again, and without this nudge nothing would
/// ever tell it to try (roadmap 4.4.1 acceptance test 2).
with(obj_mon){
    path_retry = 0;
    path_escape = false;
    alarm[0] = 1;
}

