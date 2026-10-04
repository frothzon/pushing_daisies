/// @description  scr_loadOptions();
function scr_loadOptions() {

	var _data = scr_loadArray("gameOptions.dat","OPTIOMS","----");
	if(is_array(_data)){
	    global.SEVolume         = _data[0];
	    global.MUSVolume        = _data[1];
	    global.shadowQuality    = _data[2];
	    global.clutterDensity   = _data[3];   
	}



}
