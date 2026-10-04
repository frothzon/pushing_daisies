/// @description  scr_makeBag(persistent);
/// @param persistent
function scr_makeBag(argument0) {
	/*---------------------------------
	Creates a bag to hold items,
	persistent adds bag to save/load
	quiue
	-----------------------------------*/
	var _bag = ds_list_create();

	//-------- Add bag to bag list ---------//
	if(argument0){
	    var _index = array_length(BAGLIST);
	    BAGLIST[_index] = _bag;
	}
	//--------------------------------------//
	return(_bag);



}
