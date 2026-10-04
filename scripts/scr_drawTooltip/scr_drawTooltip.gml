/// @description  @desc scr_drawTooltip(x,y);
/// @param x
/// @param y
/// @param x
/// @param y
function scr_drawTooltip(argument0, argument1) {

	draw_reset();
	draw_set_font(fnt_size16);
	if(is_array(tooltip)){
	    var count = array_length(tooltip), /// get the size of the text array
	        _max = count * string_height(string_hash_to_newline("W")); /// Height of all strings
    
	    if(count > 0){
	        /// loop through each item
	        for(var i = 0; i < count; i++){
	            /// grab variables
	            var _tip = tooltip[i],/// the tooltip text and color are stored in _tip
	                _dist = i*string_height(string_hash_to_newline("W"));/// the current string position
	            /// draw text
	            if(i == count-1){
	                draw_set_alpha(1);
	                draw_text_outline_scaled(argument0,argument1+_dist-_max,_tip[0],_tip[1],c_black,1,1.1,1.1);
	            } else {
	                draw_set_alpha(0.75);
	                draw_text_outline(argument0,argument1+_dist-_max,_tip[0],_tip[1],c_black,1);
	            }
	        }
	    }
	}
	draw_reset();



}
