/// @description  draw_parabola(color, _x1, _y1, _x2, _y2, step);
/// @param color
/// @param  _x1
/// @param  _y1
/// @param  _x2
/// @param  _y2
/// @param  step
function draw_parabola(argument0, argument1, argument2, argument3, argument4, argument5) {
	/***********************
	This functiond draws a parabola!
	************************/
	var _cSet, _x1, _y1, _x2, _y2, _d1, _stp;
	_cSet = argument0;
	_x1 = argument1;
	_y1 = argument2;
	_x2 = argument3;
	_y2 = argument4;
	_stp = argument5;
	_d1 = point_distance(_x1,_y1,_x2,_y2);

	if(_d1 > 199)
	{
	    exit;
	}

	var _dx, _dy, _dz, _dd;
	_dx = .01+(_x2 - _x1)/_d1;
	_dy = .01+(_y2 - _y1)/_d1;
	_dd = pi/_d1;

	draw_set_color(_cSet)
	d3d_primitive_begin(pr_linestrip);
	d3d_vertex(_x1,_y1,12);
	for(var _i = _dd; _i <= _d1 - _dd; _i+=_stp)
	{
	    d3d_vertex(_x1 + _dx*_i, _y1 + _dy*_i, 64*sin(_dd*_i) + 12);
	}
	d3d_vertex(_x2,_y2,12);
	d3d_primitive_end();
	draw_set_color(c_white);




}
