/// @description  scr_indexToCoord(ind,w-count);
/// @param ind
/// @param w-count
function scr_indexToCoord(argument0, argument1) {
	/*
	    convert an index to coordinates on a 2d grid
	*/

	var _ind = argument0,
	    _wc  = argument1;
    
	//--------------- calculate position
	var _out = array((_ind % _wc),(_ind div _wc));

	return(_out);



}
