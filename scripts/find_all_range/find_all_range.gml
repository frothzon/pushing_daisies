/// @description  find_all_range(x,y,obj,range,qty);
/// @param x
/// @param y
/// @param obj
/// @param range
/// @param qty
function find_all_range(argument0, argument1, argument2, argument3, argument4) {
	/*
	    grabs the instance nearest within range
	*/

	var _x = argument0,
	    _y = argument1,
	    _type = argument2,
	    _r = argument3,
	    _max = argument4,
	    _count = instance_number(_type),
	    _targets = -1;
    
	for (var i=0; i<_count; i+=1)
	{
	    var _them = instance_find(_type,i);
	    if(point_in_circle(_x,_y,_them.x,_them.y,_r)){
	        var _ind = array_last_index(_targets);
	        if(_ind < _max){
	            _targets[_ind] = _them;
	        }
	    }
	};

	return(_targets);





}
