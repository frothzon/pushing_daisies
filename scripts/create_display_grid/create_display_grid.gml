/// @description  create_display_grid(x,y,w,h,hcount,vcount);
/// @param x
/// @param y
/// @param w
/// @param h
/// @param hcount
/// @param vcount
function create_display_grid() {
	/*----------------------------------------------------------------------------------
	create_display_grid, Display Grid, creates a 1d array that stores position and size
	of any M x N size table. There are additional functions that can determine the 
	position and size of an individual cell, or the cell in which an x,y coordinate
	resides.
	----------------------------------------------------------------------------------*/

	var _dg = -1;   /// initialize the display grid

	// Loop through all the arguments and pass them to the array
	for (var i=0; i<argument_count; i+=1)
	{
	    _dg[i] = argument[i]; /// sset array[index] = argument[index]
	};

	return(_dg);



}
