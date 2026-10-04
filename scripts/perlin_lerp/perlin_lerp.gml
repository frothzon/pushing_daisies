/// @description  perlin_lerp(dx,dy,[val1;val2;val3;val4]);
/// @param dx
/// @param dy
/// @param [val1;val2;val3;val4]
/// @param dx;
/// @param dy;
/// @param [val1;val2;val3;val4];
function perlin_lerp(argument0, argument1, argument2) {

	var _dx,_dy,_vals;

	_dx = argument0;
	_dy = argument1;
	_vals = argument2;


	/// find midpoint values
	var m1,m2,m3,m4;
	m1 = lerp_smooth(_vals[0],_vals[1],_dx);/// top
	m2 = lerp_smooth(_vals[1],_vals[2],_dy);/// right
	m3 = lerp_smooth(_vals[3],_vals[2],_dx);/// bottom
	m4 = lerp_smooth(_vals[0],_vals[3],_dy);/// left

	/// find both center values
	var c1, c2;
	c1 = lerp_smooth(m1,m3,_dy);
	c2 = lerp_smooth(m4,m2,_dx);

	/// average c1 and c2 and return
	return((c1+c2)*0.5);





}
