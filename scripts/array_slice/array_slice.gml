/// @description  array_slice(array_src, indices...);
/// @param array_src
/// @param  indices...
function array_slice() {
	/*---------------------------------------
	This script will grab each index out of
	the source array and return it as its
	own array
	-----------------------------------------*/

	var _arr = argument0,   /// source array
	    _arr2 = -1,         /// destination array
	    n = 0;              /// destintions current index
    
	/// throw error if out of bounds
	if(argument_count-1 > array_length(_arr)){
	    show_error("Index Out Of Bounds in array_slice",true);
	}
	/// grab values out of source array
	for (var i=1; i<argument_count; i+=1)
	{
	    var _ind = argument[i];     /// grab index from argument
	    _arr2[n++] = _arr[_ind];    /// grab value from source and pass to destination
	};

	return(_arr2);





}
