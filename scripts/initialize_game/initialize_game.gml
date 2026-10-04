/// @description  initialize_game();
function initialize_game() {

	gml_pragma("global", "initialize_game()");   /// call at startup

	//------------------- Initialize global values
	global.devMode = true;  /// set developer mode

	/// initialize sound control variables
	scr_initSoundEmitters();

	/// global variables
	global.fadeOut = _fadeout;      /// room transition object
	global.saveName = "test.data";  /// save file name
	global.startRoom = rm_test; /// default start room

	/// Graphics Settings
	global.shadowQuality = 1.0;
	global.clutterDensity = 1.0;

	/// load saved options
	scr_loadOptions();

	audio_channel_num((global.clutterDensity+0.1)*50);
    
    //======================  additional systems [10/4/26] ============================//
    
    /// Tile Manager System
    global.tileSystem = new Sprite_Layer_Manager();



}
