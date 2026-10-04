/// @description  scr_drawTimerExt();
function scr_drawTimerExt() {

	//----------------------- Get GUI position
	var _x = display_get_gui_width()*0.5,
	    _y = 24,
	    _ind = 0;

	//----------------------- Draw Timer
	var _logAmt = instance_number(_objSwitch);
	draw_set_colour(c_black);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(fnt_size16);
	for (var i=0; i<_logAmt; i+=1)
	{
	    var _log = instance_find(_objSwitch,i);
	    if(_log.state == scr_switch_timer){
	        scr_drawSwitchTimer(_log,_x,_y+(_ind++)*16);
	    }
	};
	draw_reset();



}
