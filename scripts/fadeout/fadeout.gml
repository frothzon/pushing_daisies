/// @description  fadeout(room, fade-color, fade_time[s], x, y);
/// @param room
/// @param  fade-color
/// @param  fade_time[s]
/// @param  x
/// @param  y
function fadeout(argument0, argument1, argument2, argument3, argument4, argument5) {
	/*--------------------------------------------
	Call this script anywere to initialize a
	room transition
	----------------------------------------------*/

	var fade = instance_create_depth(0,0,-10000,global.fadeOut);
	fade.target = argument0;
	fade.image_alpha = 0;
	fade.fade_color = argument1;
	/// game_get_speed replaces the obsolete room_speed (LL-007)
	fade.fade_speed = game_get_speed(gamespeed_fps)/argument2;
	fade.xx = argument3;
	fade.yy = argument4;
	/// a SIXTH argument asks for the room to be RESTARTED when it is the
	/// room we are already in - a retry or a replay.  Omitted, the call
	/// means exactly what it always did (LL-049).  Written as an if rather
	/// than `(argument_count > 5) && argument5` so that no reader (and no
	/// future GML) has to assume && short-circuits past an argument that
	/// was never passed.
	var _restart = false;
	if(argument_count > 5) _restart = argument5;
	fade.restart = _restart;

	print("FADE  -> ", room_get_name(argument0), " in ", argument2, "s  (fps=", game_get_speed(gamespeed_fps), " -> ", fade.fade_speed, " alpha/frame; would take ", ceil(1/max(fade.fade_speed,0.0001)), " frames)");




}
