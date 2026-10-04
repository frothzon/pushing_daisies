/// @description  scr_update_textInput();
function scr_update_textInput() {
	/*-------------------------------
	Check the position of the mouse
	and return a value
	---------------------------------*/
	if(finished) exit;
	var _size = array_length(input_data);
	for (var i=0; i<_size; i+=1)
	{
	    //------------- Get Index based on mouse position -------------//
	    var _box = scr_get_inBox(input_data,i);
	    /// mouse position
	    var _x = mouse_x,
	        _y = mouse_y;
	    //-------------- Add Text by clicking on letter ---------------//
	    if(point_in_rectangle(_x,_y,_box[0],_box[1],_box[2],_box[3])){
	        input_select = i;
	        if(mouse_check_button_pressed(mb_left)){
	            scr_set_inString(i);
	            continue;
	        }
	    }
	    //---------------- Add Text by Pressing Letter Key ------------//
	    var _key = scr_get_inCode(input_data,i);
	    if(keyboard_check_pressed(_key)){
	        scr_set_inString(i);
	    }
	};




}
