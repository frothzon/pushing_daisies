/// @description  Path integrity helpers (roadmap 4.4.1).
///
/// One place that answers "is this route still walkable", so the placement
/// check and the monster's own recovery cannot drift apart.  The old code
/// tested only the SPAWN, which is how a tower that left the spawn connected
/// could still pocket a monster that was already on the map.

/// Is there a route from one point to another?  The path is cleared first, so
/// a caller can reuse one path for several probes.
function scr_path_try(_grid, _x1, _y1, _x2, _y2, _path) {
	path_clear_points(_path);
	return mp_grid_path(_grid, _path, _x1, _y1, _x2, _y2, true);
}

/// True when a live monster is standing in the cell the player is trying to
/// build on.
///
/// The old test only asked position_meeting(x,y,obj_tower), so a tower could be
/// dropped onto a monster's own cell - sealing the cell it was standing in and
/// freezing it in place, with no pocket required at all.
function scr_path_cell_blocked_by_monster(_x, _y, _r) {
	var _n = instance_number(obj_mon);
	for(var _i = 0; _i < _n; _i++){
		var _m = instance_find(obj_mon, _i);
		if(!instance_exists(_m)) continue;

		/// x/y are built-ins, so reading them from here is safe (LL-003 is
		/// about an instance's OWN variables)
		if(abs(_m.x - _x) < _r && abs(_m.y - _y) < _r) return true;
	}
	return false;
}

/// True when EVERY live monster can still reach the destination from where it
/// currently stands.
///
/// This is the check that makes a pocket impossible by construction: a tower
/// that seals off one monster while leaving the spawn connected is rejected,
/// because the monster itself cannot get out.
function scr_path_all_monsters_ok(_grid, _path, _to_x, _to_y) {
	var _n = instance_number(obj_mon);
	for(var _i = 0; _i < _n; _i++){
		var _m = instance_find(obj_mon, _i);
		if(!instance_exists(_m)) continue;

		if(!scr_path_try(_grid, _m.x, _m.y, _to_x, _to_y, _path)) return false;
	}
	return true;
}

/// A grid with nothing in it, used by a monster as a last-resort escape route
/// so that instance_number(obj_mon) can always reach zero and a wave can
/// always end.  Sized to match the level's own grid.  Returns -1 when there is
/// no level to match.
function scr_path_open_grid_make() {
	if(!variable_global_exists("LEVEL")) return -1;
	var _lev = LEVEL;
	if(!instance_exists(_lev)) return -1;
	if(!variable_instance_exists(_lev, "path_grid")) return -1;

	return mp_grid_create(-_lev.cell_w, -_lev.cell_h,
	                      _lev.grid_w + 2, _lev.grid_h + 2,
	                      _lev.cell_w, _lev.cell_h);
}
