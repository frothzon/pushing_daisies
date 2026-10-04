/// @description  scr_view_drag();
function scr_view_drag() {
	/*
	    drag the view
	*/

	//--------------------- drag view
	if(mouse_check_button_released(mb_left)){
	    /// change state
	    hold_timer = 0;
	    scr_changeState(scr_view_idle);
	} else {
	    var _dx = __view_get( e__VW.XView, 0 ) + hold_position[0] - mouse_x,
	        _dy = __view_get( e__VW.YView, 0 ) + hold_position[1] - mouse_y;
        
	    __view_set( e__VW.XView, 0, lerp(__view_get( e__VW.XView, 0 ),_dx,0.25) );
	    __view_set( e__VW.YView, 0, lerp(__view_get( e__VW.YView, 0 ),_dy,0.25) );
	}



}
