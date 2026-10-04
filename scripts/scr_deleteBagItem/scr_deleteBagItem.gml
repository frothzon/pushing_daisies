/// @description  scr_deleteBagItem(bag, index);
/// @param bag
/// @param  index
function scr_deleteBagItem(argument0, argument1) {
	/*---------------------------------
	Adds items to the bag
	-----------------------------------*/

	var _bag = argument0,
	    _ind = argument1;
    
	ds_list_delete(_bag,_ind);



}
