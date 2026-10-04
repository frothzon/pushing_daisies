/// @description  instance_in_view( x, y, offset);
/// @param  x
/// @param  y
/// @param  offset
function instance_in_view(argument0, argument1, argument2) {
	/*
	This function checks if the instance
	is inside of the view returning
	returns a bool
	------------------------------------
	GM STUDIO 1.3 or older
	*/

	/*
	-------------------------------------------------------------------------------------
	*/

	var x1, y1, offset, x_view, y_view, wide, high;

	x1 = argument0;                         /// x position of instance
	y1 = argument1;                         /// y position of instance
	offset = argument2;                     /// the crop distance from the view border
	x_view = __view_get( e__VW.XView, 0 );                 /// x position of view
	y_view = __view_get( e__VW.YView, 0 );                 /// y position of view
	wide = __view_get( e__VW.WView, 0 );                   /// width of the view
	high = __view_get( e__VW.HView, 0 );                   /// height of the view

	/*
	--------------------------------------------------------------------------------------
	*/

	/// check if point is in rectangle made from variables above
	return point_in_rectangle( x1, y1, x_view - offset, y_view - offset, x_view + wide + offset, y_view + high + offset);




}
