/// @description  for_collVisible(script[i;j;val],view_id);
/// @param script[i;j;val]
/// @param view_id
function for_collVisible(argument0, argument1) {
	/*
	    loop through each index of the collision grid
	    from x1,y1 to x2,y2; execute the supplied
	    script for each index and pass in the i,j
	    and value at that point (supply as arguments)
	*/


	var _fcn = argument0,
	    _id = argument1;
    
	//----------------------- get view positions
	var _x1 = __view_get( e__VW.XView, argument1 ),
	    _y1 = __view_get( e__VW.YView, argument1 ),
	    _x2 = _x1 + __view_get( e__VW.WView, argument1 ),
	    _y2 = _y1 + __view_get( e__VW.HView, argument1 );
    
	for_collGrid(_fcn,_x1,_y1,_x2,_y2);



}
