/// @description  scr_collide();
function scr_collide() {
	/*
	    move out of collision with
	    other object
	*/

	if(x == other.x && y == other.y){
	    x += choose(-1,1);
	    y += choose(-1,1);
	    exit;
	}
	var _face = point_direction(other.x,other.y,x,y),
	    _dx = lengthdir_x(1,_face),
	    _dy = lengthdir_y(1,_face),
	    _test = 0;
    
	while(place_meeting(x,y,other) && _test < 30){
	    _test++;
	    x += _dx;
	    y += _dy;
	}



}
