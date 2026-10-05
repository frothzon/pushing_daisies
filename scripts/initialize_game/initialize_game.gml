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

	/// ---- the current run's configuration (roadmap 0.8) ----
	/// One place that knows which stage is being played, so the level
	/// flow, the HUD and (later) the world map all read the same values
	/// instead of each keeping a private copy.
	global.region     = 1;                    /// region, 1..6
	global.stage      = 1;                    /// stage inside the region, 1..10
	global.difficulty = DIFFICULTY.NORMAL;    /// see difficulty_data()
	global.loadout    = [];                   /// the four towers brought in

	/// Graphics Settings
	global.shadowQuality = 1.0;
	global.clutterDensity = 1.0;

	/// load saved options
	scr_loadOptions();

	/// load the meta save (roadmap 0.1).  A missing or corrupt file must
	/// never stop the game starting, so this always hands back a usable
	/// struct - the worst case is a fresh save.
	global.meta = scr_load_meta();

	audio_channel_num((global.clutterDensity+0.1)*50);
    
    //======================  additional systems [10/4/26] ============================//
    
    /// Tile Manager System
    global.tileSystem = new Sprite_Layer_Manager();



}
