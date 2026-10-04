/// @description burst_particle(id,x,y,amount,layer<0-1-2>);
/// @param id
/// @param x
/// @param y
/// @param amount
/// @param layer<0-1-2>
function burst_particle(argument0, argument1, argument2, argument3, argument4) {
	/*
	Created by: Rayu Johnson
	This function burst 10 - 30
	particles of id at x and y
	*/
	var _id, input, number, xx, yy, _sys;
	number = argument3;
	_id = argument0;
	xx = argument1;
	yy = argument2;
	_sys = SYS_POS[argument4];
	part_particles_create(_sys, xx, yy, _id, number);



}
