/// @description  @desc test_tile(grid,i,j,min,max,override);
/// @param grid
/// @param i
/// @param j
/// @param min
/// @param max
/// @param override
/// @param grid {real}
/// @param i {real}
/// @param j {real}
/// @param empty_id  {real}
function test_tile(argument0, argument1, argument2, argument3, argument4, argument5) {

	var _grid   = argument0,
	    _i      = argument1,
	    _j      = argument2,
	    _min    = argument3,
	    _max    = argument4,
	    _ov     = argument5;

	var _north_tile = 1,
	    _east_tile  = 1,
	    _south_tile = 1,
	    _west_tile  = 1,
	    _tile_index = 0;

	if(_j > 0)
	    _north_tile = (_grid[# _i, _j-1] > _min) && (_grid[# _i, _j-1] < _max) || _grid[# _i, _j-1] == _ov;   /// bool: if north tile is empty
	if(_i < ds_grid_width(_grid)-1)
	    _east_tile  = (_grid[# _i+1, _j] > _min) && (_grid[# _i+1, _j] < _max) || _grid[# _i+1, _j] == _ov;   /// bool: if east tile empty
	if(_j < ds_grid_height(_grid)-1)
	    _south_tile = (_grid[# _i, _j+1] > _min) && (_grid[# _i, _j+1] < _max) || _grid[# _i, _j+1] == _ov;   /// bool: if south tile empty
	if(_i > 0)
	    _west_tile  = (_grid[# _i-1, _j] > _min) && (_grid[# _i-1, _j] < _max) || _grid[# _i-1, _j] == _ov;   /// bool: if west tile empty


	/// Get Tile Index
	_tile_index = set_bitmask(_east_tile,_north_tile,_west_tile,_south_tile);

	return(_tile_index);





}
