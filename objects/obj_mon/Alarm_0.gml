/// @description  restart
///
/// Roadmap 4.4.1.  This alarm used to retry for ever with the identical
/// result - the same grid, the same start cell, the same failure - so a
/// monster that could not get out never could, and the wave never ended.
///
/// It now escalates, and its last resort uses a grid with no towers in it, so
/// the monster can always walk out over the tops of them.  That is what
/// guarantees instance_number(obj_mon) can reach zero.
///
/// LL-025: an attempt that can fail must not be allowed to destroy the
/// route the monster is already walking - see scr_path_replace().

var _fps = game_get_speed(gamespeed_fps);

/// Ask the grid - but do NOT throw away the route we are walking unless
/// a replacement exists.  This used to read
///
///     path_end();
///     path_clear_points(myPath);
///
/// FIRST and ask the grid SECOND, so one failed attempt (a tower just
/// placed, a monster brushing one) left the zombie with NO path.  A
/// monster with no path is a monster nothing rewrites each step, and
/// the unbalanced draw offset then marched it north off the map -
/// through every wall (LL-025).
if(scr_path_replace(LEVEL.path_grid, x, y, path_loc[0], path_loc[1], myPath, path_probe)){
	path_start(myPath,1,0,true);
	path_free = true;
	path_retry = 0;
	path_escape = false;
	exit;
}

//------------------------------- still blocked, so escalate
/// no route from where we stand right now: keep the path we have (if
/// any), back away from the blockage while we wait (scr_zomb_pathSpeed
/// reverses on !path_free), and try again shortly
path_free = false;
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
		/// the same guarded swap, this time against the tower-ignoring
		/// grid: we must not empty the live path and then fail (LL-025)
		if(scr_path_replace(_open, x, y, path_loc[0], path_loc[1], myPath, path_probe)){
			path_start(myPath,1,0,true);
			path_free = true;
			path_retry = 0;
			path_escape = false;
			mp_grid_destroy(_open);
			scr_meta_log("PATH", "monster ", id, " escaping over the towers");
			exit;
		}
		mp_grid_destroy(_open);
	}

	/// even that failed, which means the LEVEL's grid itself is suspect
	if(!path_free){
		scr_meta_log("PATH", "WARNING: escape path failed too - rebuilding the grid");
		mp_grid_clear_all(LEVEL.path_grid);
		scr_grid_block_instances(LEVEL.path_grid, obj_tower);
		scr_grid_block_instances(LEVEL.path_grid, obj_wall);
		path_retry = 0;
	}
}

alarm[0] = _fps * 0.5;
