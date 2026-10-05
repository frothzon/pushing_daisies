/// @description  restart
///
/// Roadmap 4.4.1.  This alarm used to retry for ever with the identical
/// result - the same grid, the same start cell, the same failure - so a
/// monster that could not get out never could, and the wave never ended.
///
/// It now escalates, and its last resort uses a grid with no towers in it, so
/// the monster can always walk out over the tops of them.  That is what
/// guarantees instance_number(obj_mon) can reach zero.

path_end();
path_clear_points(myPath);

var _fps = game_get_speed(gamespeed_fps);

path_free = scr_path_try(LEVEL.path_grid, x, y, path_loc[0], path_loc[1], myPath);

if(path_free){
	path_start(myPath,1,0,true);
	path_retry = 0;
	path_escape = false;
	exit;
}

//------------------------------- still blocked, so escalate
path_retry++;

scr_meta_log("PATH", "monster ", id, " at ", round(x), ",", round(y),
             " has no route (attempt ", path_retry, ", ",
             instance_number(obj_mon), " alive)");

/// after roughly two seconds of trying, stop politely waiting and walk out
if(path_retry >= 4){
	path_escape = true;
}

if(path_escape){
	/// an empty grid: the monster ignores the towers and reaches the despawn
	var _open = scr_path_open_grid_make();
	if(_open != -1){
		path_clear_points(myPath);
		var _out = mp_grid_path(_open, myPath, x, y, path_loc[0], path_loc[1], true);
		mp_grid_destroy(_open);

		if(_out){
			path_start(myPath,1,0,true);
			path_free = true;
			path_retry = 0;
			path_escape = false;
			scr_meta_log("PATH", "monster ", id, " escaping over the towers");
			exit;
		}
	}

	/// even that failed, which means the LEVEL's grid itself is suspect
	if(!path_free){
		scr_meta_log("PATH", "WARNING: escape path failed too - rebuilding the grid");
		mp_grid_clear_all(LEVEL.path_grid);
		mp_grid_add_instances(LEVEL.path_grid, obj_tower, false);
		mp_grid_add_instances(LEVEL.path_grid, obj_wall, false);
		path_retry = 0;
	}
}

alarm[0] = _fps * 0.5;
