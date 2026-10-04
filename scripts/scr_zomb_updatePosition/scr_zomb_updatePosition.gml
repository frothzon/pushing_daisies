/// @description  scr_zomb_updatePosition
function scr_zomb_updatePosition() {

	/// update object

	/// get facing direction
	var _face = point_direction(pos_save[0],pos_save[1],x,y);

	/// flip image
	if(_face > 90 && _face < 270){
	    image_xscale = -abs(image_xscale);
	} else {
	    image_xscale = abs(image_xscale);
	}

	/// destroy when at destination
	if(point_in_circle(path_loc[0],path_loc[1],x,y,16)){
	    lose_life();
	}

	/// destroy at end of path
	if(path_exists(myPath)){
	    if(path_position >= 1){
	        lose_life();
	    }
	}

	/// update positon
	pos_save = array(x,y);



}
