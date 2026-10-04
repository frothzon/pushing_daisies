/// @description  scr_get_item(item-id);
/// @param item-id
function scr_get_item(argument0) {
	/*
	    Set the amount of items of type
	*/

	var _bag = global.ITEMBAG,      /// bag holding item
	    _item = _bag[|argument0];   /// grab item from bag
    
	/// get value
	return(_item[4]);



}
