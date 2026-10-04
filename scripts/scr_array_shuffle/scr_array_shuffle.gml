/// @description  scr_array_shuffle(arr);
/// @param arr
function scr_array_shuffle(argument0) {
	/*
	    This script shuffles an array
	*/

	var _arr = argument0,
	    _amt = array_length(_arr);
    
    
	for (var i=0; i<_amt; i+=1){
	    var _p1 = irandom(_amt-1);
	    /// shuffle
	    if(_p1 != i){
	        var _temp = _arr[i];
	        _arr[@i] = _arr[_p1];
	        _arr[@_p1] = _temp;
	    }
	};




}
