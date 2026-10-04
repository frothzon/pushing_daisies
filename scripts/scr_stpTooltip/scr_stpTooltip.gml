/// @description  @desc scr_stpTooltip();
function scr_stpTooltip() {

	if(is_array(tooltip)){
	    var _count = array_length(tooltip);// current string count
    
	    if(_count > 0){
	        tool_counter += _count;
	        if(tool_counter > count_time){
	            /// trim array
	            var tmp = undefined;
	            for(var i = 0; i < _count-1; i++){
	                tmp[i] = tooltip[i+1];
	            }
	            tooltip = tmp;
	            tool_counter = 0;
	        }
	    }
	}



}
