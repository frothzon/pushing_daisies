/// @description  scr_view_idle();
function scr_view_idle() {

	/// ---- a finishing stage does not want the mouse (LL-055) ----------
	/// The clear sequence is flying the camera out to the room; a drag
	/// would take the finish away from the player.
	if(scr_level_exiting()) return;
	/*
	    view doesn't do anything while idle except
	    check for dragging
	*/


	if(state_time > 10){
	    if(mouse_check_button_pressed(mb_left)){
	        hold_position = array(mouse_x,mouse_y);
	    }
	    if(mouse_check_button(mb_left)){
	        hold_timer++;
	        if(hold_timer > 3){
	            if(point_distance(mouse_x,mouse_y,hold_position[0],hold_position[1]) > 8){
	                hold_position = array(mouse_x,mouse_y);
	                /// change state
	                print("dragging");
	                scr_changeState(scr_view_drag);
	            }
	        }
	    } else {
	        hold_timer = 0;
	    }
	}



}
