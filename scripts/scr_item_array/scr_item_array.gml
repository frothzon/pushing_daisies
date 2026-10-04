/// @description  scr_item_array(item-id);
/// @param item-id
function scr_item_array(argument0) {

	var _bag = global.ITEMBAG,      /// bag holding item
	    _item = _bag[|argument0];   /// grab item from bag
    
	return(_item);



}
