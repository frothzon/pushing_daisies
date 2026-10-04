/// @description  points_to_gui(x,y,view_id);
/// @param x
/// @param y
/// @param view_id
/// GM studio 2 only
function points_to_gui(argument0, argument1, argument2) {
	/*
	var _asp_x = display_get_gui_width()/camera_get_view_width(view_camera[0]),
	    _asp_y = display_get_gui_height()/camera_get_view_height(view_camera[0]),
	    _x = (argument0 - camera_get_view_x(view_camera[0]))*_asp_x,
	    _y = (argument1 - camera_get_view_y(view_camera[0]))*_asp_y;

	return([_x,_y]);
	*/

	var _asp_x = display_get_gui_width()/__view_get( e__VW.WView, argument2 ),
	    _asp_y = display_get_gui_height()/__view_get( e__VW.HView, argument2 ),
	    _x = (argument0 - __view_get( e__VW.XView, 0 ))*_asp_x,
	    _y = (argument1 - __view_get( e__VW.YView, 0 ))*_asp_y;

	return(array(_x,_y));





}
