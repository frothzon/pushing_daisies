/// @description  find_all_range(x,y,obj,range,qty);
/// @param x
/// @param y
/// @param obj
/// @param range
/// @param qty
///
/// Every instance of `obj` inside the circle, NEAREST FIRST, capped at `qty`.
///
/// THE MISSING ADVANCE (found 2026-10-13).  This used to read
/// `var _ind = array_last_index(_targets)` and then write `_targets[_ind]` -
/// the index it had JUST READ.  Writing at the last index cannot change the
/// last index, so the list could never grow past ONE entry, and `qty`
/// (`TOWER.targets`) did nothing at all: every tower in the game was
/// single-target.  That is why the shop's `damage x rate x targets` claimed
/// 2000 dps for a Pina Collider that could only ever hit one monster for 200,
/// and why the curve panel read `ok` while a full wrap leaked (LL-038).
///
/// THE RETURN CONTRACT is not a style choice: with nothing in range this
/// returns a NON-ARRAY sentinel, never an empty array.  scr_tower_shoot tests
/// `!is_array(target)` to decide "nothing to shoot, return to idle", so `[]`
/// would read as a VALID list - the tower would never go idle and would swing
/// at the air.  A failure that looks like a success (LL-025).
function find_all_range(argument0, argument1, argument2, argument3, argument4) {
	/*
	    grabs the instances nearest within range, up to qty of them
	*/

	var _x    = argument0,
	    _y    = argument1,
	    _type = argument2,
	    _r    = argument3,
	    _max  = argument4;

	/// no targets stat, or nothing to look at: the caller gets the sentinel
	if(!is_real(_max) || _max < 1) return -1;

	var _count = instance_number(_type);
	if(_count <= 0) return -1;

	/// pairs of [distance, instance], collected raw and sorted AFTER the scan -
	/// the nearest `_max` cannot be picked without seeing all of them
	var _near = [];

	for (var i=0; i<_count; i+=1)
	{
	    var _them = instance_find(_type,i);
	    /// a monster can die mid-scan - another tower's volley lands first - so
	    /// its x/y must not be read before this (LL-012)
	    if(!scr_isValidInstance(_them)) continue;
	    /// a CORPSE is still in the room for the length of its die
	    /// animation (scr_zomb_death), but its life is already 0 - a shot
	    /// at it is damage thrown away, and the tower would swing at a
	    /// body instead of at the monster behind it
	    if(zomb_is_dying(_them)) continue;

	    /// x/y are built-ins, so reading them from here is safe (LL-003 is about
	    /// an instance's OWN variables)
	    var _dist = point_distance(_x, _y, _them.x, _them.y);
	    if(_dist <= _r){
	        _near[array_length(_near)] = [_dist, _them];
	    }
	};

	var _found = array_length(_near);
	if(_found == 0) return -1;

	/// nearest first, so a capped list takes the monsters closest to the tower -
	/// which is what the original comment ("the instance nearest within range")
	/// always asked for.  An insertion sort, because `_found` is the handful in
	/// range rather than the whole level, and because it is stable and adds no
	/// API this project does not already use.
	for(var _i = 1; _i < _found; _i+=1){
	    var _key = _near[_i],
	        _j   = _i - 1;
	    while(_j >= 0 && _near[_j][0] > _key[0]){
	        _near[_j + 1] = _near[_j];
	        _j -= 1;
	    }
	    _near[_j + 1] = _key;
	}

	/// the cap - this is the loop that makes `targets` mean something
	var _out  = [],
	    _take = min(_max, _found);
	for(var _i = 0; _i < _take; _i+=1){
	    _out[_i] = _near[_i][1];
	}
	return _out;
}
