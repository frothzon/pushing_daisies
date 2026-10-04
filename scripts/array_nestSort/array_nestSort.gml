/// @description  array_nestSort(array,ascend,index);
/// @param array
/// @param ascend
/// @param index
function array_nestSort(argument0, argument1, argument2) {
	/*
	    sort the nested arrays by the index value
	    in ascending or descending order
	*/

	var _arr = argument0,   /// array to sort
	    _asc = argument1,   /// ascending or descending
	    _ind = argument2,   /// index of nested array to check
	    _big = array_last_index(_arr);  /// size of array
    
	/// bubble sort method
	for (var a=0; a<_big; a+=1){
	   for (var b=a; b<_big; b+=1){
	        var _valA = _arr[a],
	            _valB = _arr[b];
	        if(_valA[_ind] > _valB[_ind] && _asc){
	            _arr[@ b] = _valA;
	            _arr[@ a] = _valB;
	        }
	        if(_valA[_ind] < _valB[_ind] && !_asc){
	            _arr[@ b] = _valA;
	            _arr[@ a] = _valB;
	        }
	    }; 
	};

    

    




}
