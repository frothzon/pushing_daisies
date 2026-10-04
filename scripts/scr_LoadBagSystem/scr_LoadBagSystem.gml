/// @description  scr_LoadBagSystem(fname);
/// @param fname
function scr_LoadBagSystem(argument0) {
	/*---------------------------------
	Call this function to save all of
	the bags simultaniously
	-----------------------------------*/

	var _fname = argument0,
	    _size = array_length(BAGLIST);

	ini_open(_fname);
	//-------------- Save Data ------------------------//
	for (i=1; i<_size; i+=1){
	    var _loc = "Bag"+string(i);                     /// Get Section Bag0 - BagN
	        _str = ini_read_string(_loc, "0", "");      /// Grab string from file
	    if(_str != ""){
	        /// if data is present, add it to ds list
	        ds_list_read(BAGLIST[i], _str);
	    }
	};
	//-------------------------------------------------//
	ini_close();



}
