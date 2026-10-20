/// @description  @desc draw_fadeout(player);
/// @param player
function draw_fadeout(argument0) {
	/*-----------------------------------------
	DRAW EVENT -> place in fadeout object
	draw event to draw effects to the screen
	-------------------------------------------*/
	var _player = argument0;    /// set player object

	draw_set_colour(fade_color);
	draw_set_alpha(image_alpha);
	/// check if in new room
	if(!change_complete){
	    image_alpha += fade_speed;
	    if(image_alpha >= 1){
	        if(scr_isValidInstance(_player)){
	            _player.x = xx;
	            _player.y = yy;
	            _player.x_safe = xx;
	            _player.y_safe = yy;
	        }
	        if(room != target){
	            room_goto(target);
	        } else if(restart){
	            /// room_goto to the room you are ALREADY in does nothing,
	            /// so a retry or a replay used to be a silent no-op: the
	            /// fade ran, the screen went black and came back, and the
	            /// stage simply carried on.  room_restart re-runs the
	            /// room's creation code, so scr_level_boot() runs again
	            /// (LL-049).
	            room_restart();
	        }
	        change_complete = true;
	    }
	/// Destroy when disapears from view
	} else {
	    image_alpha -= fade_speed;
	    if(image_alpha <= 0){
	        instance_destroy();
	    }
	}


	/// draw the rectangle
	draw_rectangle(rect[0],rect[1],rect[2],rect[3],false);
	draw_set_colour(c_white);
	draw_set_alpha(1);



}
