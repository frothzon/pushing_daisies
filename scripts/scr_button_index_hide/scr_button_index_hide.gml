/// @description  scr_button_index_hide(array, i);
/// @param array
/// @param  i
function scr_button_index_hide(argument0, argument1) {
	/*
	    Enables the button
	*/

	var _arr = argument0,
	    _id  = argument1;
    
	/// see scr_button_index_enable - 0 / noone / undefined are not instances
	var _inst = _arr[_id];
	if(_inst == undefined || _inst == noone || _inst == 0 || !instance_exists(_inst)){
	    print("BTN   hide    ", _id, " skipped - slot is not a live instance");
	    exit;
	}

	with(_inst){
	    visible = false;
	    active = false;
	};



}
