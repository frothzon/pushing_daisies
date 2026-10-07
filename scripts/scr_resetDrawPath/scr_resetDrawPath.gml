/// @description  scr_resetDrawPath
function scr_resetDrawPath() {

	/// get path data
	path_clear_points(path_show);
	var path_loc = array(obj_despawn.x,obj_despawn.y);
	var path_begin = array(obj_spawn.x,obj_spawn.y);
	scr_grid_block_instances(LEVEL.path_grid, obj_tower);
	scr_grid_block_instances(LEVEL.path_grid, obj_wall);
	path_ready = mp_grid_path(LEVEL.path_grid,path_show,path_begin[0],path_begin[1],path_loc[0],path_loc[1],true);




}
