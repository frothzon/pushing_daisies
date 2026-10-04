/// @description  scr_showWave(wave_number);
/// @param wave_number
function scr_showWave(argument0) {
	/*
	    show the wave number
	*/

	var _show = instance_create(-100,-100,_waveNum);
	_show.disp_text = concat("Wave ",argument0);



}
