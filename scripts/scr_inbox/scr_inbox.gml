/// @description  scr_inbox(x,y,w,h);
/// @param x
/// @param y
/// @param w
/// @param h
function scr_inbox(argument0, argument1, argument2, argument3) {
	/*------------------------------
	Create a box
	--------------------------------*/
	var _box;
	_box[5] = argument3;                /// h
	_box[4] = argument2;                /// w
	_box[3] = argument1+argument3;      /// y2
	_box[2] = argument0+argument2;      /// x2
	_box[1] = argument1;                /// y
	_box[0] = argument0;                /// x
	return(_box);



}
