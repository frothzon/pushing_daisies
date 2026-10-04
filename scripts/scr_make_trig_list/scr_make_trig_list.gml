/// @description  scr_make_trig_list(slices)
/// @param slices
function scr_make_trig_list() {
	/************************
	This function creates discrete angles
	so they dont have to be calculated
	************************/
	var _adj = 360/slices,
	_list = -1;

	for(var i = 0; i < 360; i+=_adj)
	{
	    var temp = -1;
	    temp[1] = lengthdir_y(1,i);
	    temp[0] = lengthdir_x(1,i);
	    _list[i] = temp;
	}

	return(_list);




}
