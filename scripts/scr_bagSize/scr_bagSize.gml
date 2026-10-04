/// @description  scr_bagSize(bag);
/// @param bag
function scr_bagSize(argument0) {
	/*---------------------------------
	Returns the index count of the bag
	-----------------------------------*/
	print(ds_exists(argument0,ds_type_list));
	print(argument0);
	if(ds_exists(argument0,ds_type_list)){
	    return(ds_list_size(argument0));
	} else {
	    return(0);
	}



}
