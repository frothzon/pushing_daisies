/// @description  scr_inRangeBBOX(other, pad);
/// @param other
/// @param  pad
function scr_inRangeBBOX(argument0, argument1) {
	/*
	    check if you are in range of the bbox
	*/

	var _other  = argument0,
	    _pad    = argument1;
    
	var _hit = point_in_rectangle(
	    x,y,
	    _other.bbox_left - _pad,
	    _other.bbox_top - _pad,
	    _other.bbox_right + _pad,
	    _other.bbox_bottom + _pad
	);

	return(_hit);



}
