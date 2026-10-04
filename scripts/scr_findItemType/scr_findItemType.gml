/// @description  scr_findItemType(bag,item_index,value);
/// @param bag
/// @param item_index
/// @param value
function scr_findItemType(argument0, argument1, argument2) {
	/*----------------------------------------
	This script returns the id (position in bag)
	of the item with index that matches the
	specified value. This is useful for
	searching out items with specific values
	------------------------------------------*/

	var _bag    = argument0,            /// bag that contains the items you are searching for
	    _id     = argument1,            /// index in the item you are searching for
	    _val    = argument2,            /// value the item index must equal 
	    _size   = scr_bagSize(_bag);    /// amount of items in the bag
    
	for (var i=0; i<_size; i+=1)
	{
	    var _item = _bag[|i];  /// item in the list
	    if(_item[_id] == _val){
	        /// return the first index found
	        return(i);
	    }
	};
	/// if no index found, return NULL
	return(-1);



}
