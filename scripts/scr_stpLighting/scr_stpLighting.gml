/// @description  scr_stpLighting();
function scr_stpLighting() {

	shadow_offset[0] = lengthdir_x(shadow_distance,shadow_angle);
	shadow_offset[1] = lengthdir_y(shadow_distance*1.25,shadow_angle) - shadow_distance;
	shadow_intensity = (lengthdir_y(0.5,shadow_angle) + 0.5)*0.6;
	night_fade = clamp(lengthdir_y(0.5,-shadow_angle),0,0.5);
	shadow_angle += time_unit;
	if(shadow_angle > 360){
	    shadow_angle -= 360;
	}



}
