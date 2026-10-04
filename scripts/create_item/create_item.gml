/// @description  create_item(name, desc, sprite, index);
/// @param name
/// @param  desc
/// @param  sprite
/// @param  index
function create_item(argument0, argument1, argument2, argument3) {
	/*
	    create an item and add it to an array
	*/

	var _bag    = global.ITEMBAG,     /// bag to add item to
	    _item   = array_create(6),      /// item array
	    _ind    = 0;                    /// index in bag 
    
	_item[0] = argument0;   /// name
	_item[1] = argument1;   /// desc
	_item[2] = argument2;   /// sprite
	_item[3] = argument3;   /// index
	_item[4] = 0;           /// quantity
	_item[5] = false;       /// not visible yet

	//-------------- add to bag
	_ind = scr_addToBag(_bag,_item);
	return(_ind);




}
