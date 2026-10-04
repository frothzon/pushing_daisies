/// @description  box_face(obj_box, other);
/// @param obj_box
/// @param  other
function box_face(argument0, argument1) {

	var _box   = argument0,
	    _other = argument1,
	    _face  = -1;
	/// lined up
	var _a = _other.x > _box.bbox_left,
	    _b = _other.x < _box.bbox_right,
	    _c = _other.y > _box.bbox_top,
	    _d = _other.y < _box.bbox_bottom;
	/// 0-right,1-top,2-left,3-bottom
	_face = (_a && !_b && _c && _d)+
	        (!_c && _d && _a && _b)*2+ 
	        (!_a && _b && _c && _d)*3+ 
	        (_c && !_d && _a && _b)*4-1;
        
	return(_face);
                




}
