/// @description  scr_part_effect(particle, per_frame, end_amount);
/// @param particle
/// @param  per_frame
/// @param  end_amount
function scr_part_effect(argument0, argument1, argument2) {

	/// offset

	var _particle   = argument0,
	    _pframe     = argument1,
	    _amount     = argument2;


	x = lerp(xstart,xend,timer/hit_time);
	y = lerp(ystart,yend,timer/hit_time);
	if(_pframe > 0){
	    burst_particle_range(_particle,x,y,max(1,global.clutterDensity*_pframe),2,8);
	} else {
	    x = xend;
	    y = yend;
	    timer = hit_time;
	}

	if(timer < hit_time){
	    timer++;
	} else {
	    var QTY = clamp(global.clutterDensity*_amount,10,100);
	    burst_particle_range(_particle,x,y,QTY,2,16);
	    instance_destroy();
	}



}
