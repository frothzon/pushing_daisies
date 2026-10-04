/// @description  scr_damage_particles
function scr_damage_particles(argument0, argument1) {

	/// stream particle
	var _arr = argument0,
	    _ind = argument1,
	    _obj = _arr[_ind];
	if(scr_isValidInstance(_obj)){
	    var _eff = instance_create(x,y,data[TOWER.effect]);
	    _eff.xstart = x;
	    _eff.ystart = y;
	    _eff.xend = _obj.x;
	    _eff.yend = _obj.y;
	    _eff.hit_time = 10;
	}



}
