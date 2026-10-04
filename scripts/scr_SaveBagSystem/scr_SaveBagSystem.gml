/// @description  scr_SaveBagSystem(fname);
/// @param fname
function scr_SaveBagSystem(argument0) {
	/*---------------------------------
	Call this function to save all of
	the bags simultaniously
	-----------------------------------*/

	var _fname = argument0,
	    _size = array_length(BAGLIST);

	ini_open(_fname);
	//-------------- Save Data ------------------------//
	for (i=1; i<_size; i+=1){
	    var _str = ds_list_write(BAGLIST[i]),   /// Turn DS_list (bag) into string
	        _loc = "Bag"+string(i);             /// Get Section Bag0 - BagN
	    ini_write_string(_loc, "0", _str);
	};
	//-------------------------------------------------//
	ini_close();



}
