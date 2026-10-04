/// @description  scr_stpSwapMouse(default,hover-obj[],cursors[]);
/// @param default
/// @param hover-obj[]
/// @param cursors[]
function scr_stpSwapMouse(argument0, argument1, argument2) {
	/*
	    this script will swap images based on the instances
	    the mouse hovers over
	*/

	cursor_sprite = argument0;
	var _objs = argument1,
	    _sprs = argument2,
	    _amt  = array_length(_objs);
    
	for (var i=0; i<_amt; i+=1)
	{
	    var _hit = position_meeting(mouse_x,mouse_y,_objs[i]);
	    if(_hit){
	        cursor_sprite = _sprs[i];
	    }
	};
    




}
