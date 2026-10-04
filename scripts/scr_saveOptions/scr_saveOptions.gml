/// @description  scr_saveOptions();
function scr_saveOptions() {

	var _data;

	_data[0] = global.SEVolume;
	_data[1] = global.MUSVolume;
	_data[2] = global.shadowQuality;
	_data[3] = global.clutterDensity;  

	scr_saveArray(_data,"gameOptions.dat","OPTIOMS","----");




}
