/// @description  draw stuff

draw_self();

/// the headstone picked in Create_0.  Guarded because a draw on sprite -1 is a
/// fatal error and this is one call a frame per spawner (LL-012) - the guard
/// costs less than the crash it prevents.
if(sprite_exists(grave_spr)){
	draw_sprite(grave_spr, 0, x_shift, y-16);
}

