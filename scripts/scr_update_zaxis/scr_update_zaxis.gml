/// @description  scr_update_zaxis();
function scr_update_zaxis() {

	/// set motion
	if(!z_freeze){
	    z_speed -= z_gravity;
	    z += z_speed;
    
	    if(z < z_ground){
	        z = z_ground;
	        z_speed = 0;
	    }
    
	    if(z_float){
	        var _sink = -sprite_height*0.5 + wave(-4,4,1.5,0);
	        if(z < _sink && z_speed < 0){
	            z_speed = 0;
	            z = _sink;
	        }
	    }
	}



}
