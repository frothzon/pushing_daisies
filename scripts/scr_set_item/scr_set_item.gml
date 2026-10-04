/// @description  scr_set_item(item-id, value);
/// @param item-id
/// @param  value
function scr_set_item(argument0, argument1) {
	/*
	    Set the amount of items of type
	*/

	var _bag = global.ITEMBAG,      /// bag holding item
	    _item = _bag[|argument0];   /// grab item from bag
    
	/// set value
	_item[@4] = argument1;



}
