/// @description  move_collide(_wall-obj,_hsp,_vsp);
/// @param _wall-obj
/// @param _hsp
/// @param _vsp
function move_collide(argument0, argument1, argument2) {

	var _wall = argument0,
	    _hsp = argument1,
	    _vsp = argument2;

	/// horizontal collisions
	if (place_meeting(x+_hsp,y,_wall)){
	    // set player movement in collision
	    while (!place_meeting(x+sign(_hsp),y,_wall)){
	        x += sign(_hsp);
	    }
	    _hsp = 0;
	}

	/// vertical collisions
	if (place_meeting(x,y+_vsp,_wall)){
	    // set player movement in collision
	    while (!place_meeting(x,y+sign(_vsp),_wall)){
	        y += sign(_vsp);
	    }
	    _vsp = 0;
	}




}
