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
	global.loadout    = [];                   /// the four towers brought in - filled once the save is loaded

	/// Which Menu state to open on.  The level sets this before it fades
	/// back, so a finished stage returns to the world map rather than to
	/// the title screen (roadmap 1.5).  The Menu resets it as it reads it.
	global.menu_entry = MENU_STATE.START;

	/// ---- the levels (roadmap 1.4) ----
	/// Every level the game knows about, in ONE list, built once here from
	/// the authored stage table (GameLevelData.gml).  The world map and the
	/// level flow both read this, so a node cannot exist without its level
	/// data and a level cannot be created twice or lost between screens.
	global.level_data = [];
	global.level_data = level_data_build();
	scr_meta_log("LEVEL", "authored ", array_length(global.level_data), " levels");

	/// Graphics Settings
	global.shadowQuality = 1.0;
	global.clutterDensity = 1.0;

	/// load saved options
	scr_loadOptions();

	/// load the meta save (roadmap 0.1).  A missing or corrupt file must
	/// never stop the game starting, so this always hands back a usable
	/// struct - the worst case is a fresh save.
	global.meta = scr_load_meta();

	/// The loadout is the four towers the player brought into this run.
	///
	/// It comes OUT OF THE SAVE - meta_default seeds `loadout` as an empty
	/// array, so a first run has none - and loadout_current() then tops it
	/// up from the free starters, so it is always four usable towers
	/// (goal.md 3.1).
	///
	/// THE ORDER MATTERS.  loadout_current() reads global.loadout, so
	/// global.loadout has to be filled from the save BEFORE it is called -
	/// otherwise the pad reads the empty array it was just handed, and
	/// silently replaces a real loadout with the starters on every launch.
	global.loadout = is_array(global.meta[$ "loadout"])
	                 ? global.meta[$ "loadout"] : [];
	global.loadout = loadout_current();

	audio_channel_num((global.clutterDensity+0.1)*50);
    
    //======================  additional systems [10/4/26] ============================//
    
    /// Tile Manager System
    global.tileSystem = new Sprite_Layer_Manager();



}
