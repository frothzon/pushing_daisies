/// @description  scr_pointInBBOX(other, vec2[], pad);
/// @param other
/// @param  vec2[]
/// @param  pad
function scr_pointInBBOX(argument0, argument1, argument2) {
	/*
	    check if you are in range of the bbox
	*/

	var _other  = argument0,
	    _v2    = argument1,
	    _pad    = argument2;
    
	var _hit = point_in_rectangle(
	    _v2[0],_v2[1],
	    _other.bbox_left-_pad,
	    _other.bbox_top-_pad,
	    _other.bbox_right+_pad,
	    _other.bbox_bottom+_pad
	);

	return(_hit);



}
