/// @description  array_trim(array,start,end);
/// @param array
/// @param start
/// @param end
function array_trim(argument0, argument1, argument2) {
	/*
	    return a new array with the indices
	    between start and end
	*/

	var _arr = argument0,
	    _max = min(array_last_index(_arr),argument2+1),
	    _min = clamp(argument1,0,_max),
	    _newArr;
    
	_newArr[_max-_min-1] = 0;

	for (var i=_min; i<_max; i+=1){
	    _newArr[i-_min] = _arr[i];
	};

	return(_newArr);



}
