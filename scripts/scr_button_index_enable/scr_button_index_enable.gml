/// @description  scr_button_index_enable(array, i);
/// @param array
/// @param  i
function scr_button_index_enable(argument0, argument1) {
	/*
	    Enables the button
	*/

	var _arr = argument0,
	    _id  = argument1;
    
	/// Skip slots that are not a live instance.  An empty array slot can read
	/// as undefined OR 0 (and 0 is object index 0 == _button), and a bare
	/// with() on either would affect EVERY button instance.
	var _inst = _arr[_id];
	if(_inst == undefined || _inst == noone || _inst == 0 || !instance_exists(_inst)){
	    print("BTN   enable  ", _id, " skipped - slot is not a live instance");
	    exit;
	}

	with(_inst){
	    visible = true;
	    active = true;
	};



}
