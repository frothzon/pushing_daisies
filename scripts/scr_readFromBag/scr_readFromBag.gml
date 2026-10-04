/// @description  scr_readFromBag(bag, index);
/// @param bag
/// @param  index
function scr_readFromBag(argument0, argument1) {
	/*---------------------------------
	Adds items to the bag
	-----------------------------------*/

	var _bag = argument0,
	    _cnt = ds_list_size(_bag),
	    _ind = clamp(0,argument1,_cnt-1);
    
	return(_bag[|_ind]);



}
