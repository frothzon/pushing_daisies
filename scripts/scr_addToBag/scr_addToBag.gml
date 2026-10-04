/// @description  scr_addToBag(bag, items...);
/// @param bag
/// @param  items...
function scr_addToBag() {
	/*---------------------------------
	Adds items to the bag
	-----------------------------------*/

	var _bag,
	    _ind;
    

	if(argument_count > 0){
	    _bag = argument[0];
	    _ind = scr_bagSize(_bag);
	    print(_bag);
	}
	for (var i=1; i<argument_count; i+=1)
	{
	    ds_list_add(_bag,argument[i]);
	};

	return(_ind);



}
