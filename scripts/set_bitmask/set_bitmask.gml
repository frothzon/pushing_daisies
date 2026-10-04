/// @description  set_bitmask(north, east, south, west);
/// @param north
/// @param  east
/// @param  south
/// @param  west
/// @description return the value calculated from the bitmask function
/// @param {bool} north
/// @param {bool} west
/// @param {bool} east
/// @param {bool} south
function set_bitmask() {

	var _tile_index = 1;


	for(var i = 0; i < argument_count; i++){
	    _tile_index += power(2,i)*argument[i];
	}
	return(_tile_index);




}
