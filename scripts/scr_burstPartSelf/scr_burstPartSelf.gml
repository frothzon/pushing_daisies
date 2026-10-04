/// @description  scr_burstPartSelf(particle,min,max);
/// @param particle
/// @param min
/// @param max
function scr_burstPartSelf(argument0, argument1, argument2) {

	var _part = argument0,
	    _QTY = lerp(argument1,argument2,global.clutterDensity);
    
	burst_particle_range(_part,x,y,_QTY,2,sprite_width);



}
