/// @description  fadeout(room, fade-color, fade_time[s], x, y);
/// @param room
/// @param  fade-color
/// @param  fade_time[s]
/// @param  x
/// @param  y
function fadeout(argument0, argument1, argument2, argument3, argument4) {
	/*--------------------------------------------
	Call this script anywere to initialize a
	room transition
	----------------------------------------------*/

	var fade = instance_create_depth(0,0,-10000,global.fadeOut);
	fade.target = argument0;
	fade.image_alpha = 0;
	fade.fade_color = argument1;
	fade.fade_speed = room_speed/argument2;
	fade.xx = argument3;
	fade.yy = argument4;

	print("FADE  -> ", room_get_name(argument0), " in ", argument2, "s  (room_speed=", room_speed, " -> ", fade.fade_speed, " alpha/frame; would take ", ceil(1/max(fade.fade_speed,0.0001)), " frames)");




}
