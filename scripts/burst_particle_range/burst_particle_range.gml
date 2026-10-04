/// @description burst_particle_range(id,x,y,number,layer<0-1-2>,radius);
/// @param id
/// @param x
/// @param y
/// @param number
/// @param layer<0-1-2>
/// @param radius
function burst_particle_range(argument0, argument1, argument2, argument3, argument4, argument5) {
	/*
	Created by: Rayu Johnson
	This function burst 10 - 30
	particles of id at x and y
	*/
	var _id, _input, _num, _xx, _yy, _sys, _rr;
	_num = argument3;
	_id = argument0;
	_xx = argument1;
	_yy = argument2;
	_sys = SYS_POS[argument4];
	_rr = argument5;
	repeat(_num){
	    var _r = random(_rr),
	        _f = random(360),
	        _x = _xx + lengthdir_x(_r,_f),
	        _y = _yy + lengthdir_y(_r,_f);
	    part_particles_create(_sys, _x, _y, _id, 1);
	}



}
