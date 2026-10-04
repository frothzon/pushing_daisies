function __global_object_depths() {
	// Initialise the global array that allows the lookup of the depth of a given object
	// GM2.0 does not have a depth on objects so on import from 1.x a global array is created
	// NOTE: MacroExpansion is used to insert the array initialisation at import time
	gml_pragma( "global", "__global_object_depths()");

	// insert the generated arrays here
	global.__objectDepths[0] = 0; // Control
	global.__objectDepths[1] = 0; // Input
	global.__objectDepths[2] = 0; // _button
	global.__objectDepths[3] = -1000; // _fadeout
	global.__objectDepths[4] = 0; // obj_textbox
	global.__objectDepths[5] = -10000; // _text_rise
	global.__objectDepths[6] = 0; // _oTextInput
	global.__objectDepths[7] = 0; // _stream
	global.__objectDepths[8] = 0; // _dayCycle
	global.__objectDepths[9] = -50; // _shadows
	global.__objectDepths[10] = 0; // _light
	global.__objectDepths[11] = 0; // obj_water
	global.__objectDepths[12] = 0; // obj_title
	global.__objectDepths[13] = 0; // Menu
	global.__objectDepths[14] = 0; // obj_titleZomb
	global.__objectDepths[15] = 0; // obj_demo_particles
	global.__objectDepths[16] = 0; // _spawn
	global.__objectDepths[17] = 0; // obj_raiseGround
	global.__objectDepths[18] = -2; // obj_wall
	global.__objectDepths[19] = -59; // obj_spawn
	global.__objectDepths[20] = -59; // obj_despawn
	global.__objectDepths[21] = 0; // _mainControl
	global.__objectDepths[22] = 0; // _levelControl
	global.__objectDepths[23] = 0; // _viewControl
	global.__objectDepths[24] = 0; // _score
	global.__objectDepths[25] = -99999; // _waveNum
	global.__objectDepths[26] = 0; // _shadow
	global.__objectDepths[27] = -60; // obj_tower
	global.__objectDepths[28] = -1000; // obj_tower_edit
	global.__objectDepths[29] = -60; // obj_mon
	global.__objectDepths[30] = 0; // _eff_acid
	global.__objectDepths[31] = -999; // _eff_puff
	global.__objectDepths[32] = -999; // _eff_spikes
	global.__objectDepths[33] = -999; // _eff_xplod
	global.__objectDepths[34] = 0; // obj_graveCenter


	global.__objectNames[0] = "Control";
	global.__objectNames[1] = "Input";
	global.__objectNames[2] = "_button";
	global.__objectNames[3] = "_fadeout";
	global.__objectNames[4] = "obj_textbox";
	global.__objectNames[5] = "_text_rise";
	global.__objectNames[6] = "_oTextInput";
	global.__objectNames[7] = "_stream";
	global.__objectNames[8] = "_dayCycle";
	global.__objectNames[9] = "_shadows";
	global.__objectNames[10] = "_light";
	global.__objectNames[11] = "obj_water";
	global.__objectNames[12] = "obj_title";
	global.__objectNames[13] = "Menu";
	global.__objectNames[14] = "obj_titleZomb";
	global.__objectNames[15] = "obj_demo_particles";
	global.__objectNames[16] = "_spawn";
	global.__objectNames[17] = "obj_raiseGround";
	global.__objectNames[18] = "obj_wall";
	global.__objectNames[19] = "obj_spawn";
	global.__objectNames[20] = "obj_despawn";
	global.__objectNames[21] = "_mainControl";
	global.__objectNames[22] = "_levelControl";
	global.__objectNames[23] = "_viewControl";
	global.__objectNames[24] = "_score";
	global.__objectNames[25] = "_waveNum";
	global.__objectNames[26] = "_shadow";
	global.__objectNames[27] = "obj_tower";
	global.__objectNames[28] = "obj_tower_edit";
	global.__objectNames[29] = "obj_mon";
	global.__objectNames[30] = "_eff_acid";
	global.__objectNames[31] = "_eff_puff";
	global.__objectNames[32] = "_eff_spikes";
	global.__objectNames[33] = "_eff_xplod";
	global.__objectNames[34] = "obj_graveCenter";


	// create another array that has the correct entries
	var len = array_length(global.__objectDepths);
	global.__objectID2Depth = [];
	for( var i=0; i<len; ++i ) {
		var objID = asset_get_index( global.__objectNames[i] );
		if (objID >= 0) {
			global.__objectID2Depth[ objID ] = global.__objectDepths[i];
		} // end if
	} // end for


}
