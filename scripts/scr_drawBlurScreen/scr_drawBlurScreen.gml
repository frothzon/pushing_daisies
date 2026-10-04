/// @description  scr_drawBlurScreen();
function scr_drawBlurScreen() {
	//----------------------- Draw Paused String

	var _surf = surface_create(display_get_gui_width(),display_get_gui_height());
	surface_set_target(_surf);
	draw_clear_alpha(c_black, 1);

	if(state == scr_main_pause){
	    shader_set(shd_blur);
	    draw_surface(application_surface,0,0);
	    draw_background_stretched_ext(bck_paused,-32,-32,display_get_gui_width()+64,display_get_gui_height()+64,c_white,text_alpha);
	    shader_reset();
	    pause_text = "PAUSED";
	    pause_color = c_white;
	}
	if(state == scr_main_gameOver){
	    shader_set(shd_blur);
	    draw_surface(application_surface,0,0);
	    draw_background_stretched_ext(bck_gameOver,-32,-32,display_get_gui_width()+64,display_get_gui_height()+64,c_white,text_alpha);
	    shader_reset();
	    pause_text = "GAME OVER";
	    pause_color = c_red;
	}
	surface_reset_target();

	return(_surf);



}
