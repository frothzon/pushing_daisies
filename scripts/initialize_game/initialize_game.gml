/// @description  initialize_game();
function initialize_game() {

	gml_pragma("global", "initialize_game()");   /// call at startup
    
    /// ---- the sprite fonts --------------------------------------------
    /// font_add_sprite_ext() maps sub-image i to string_map[i], so the map
    /// must hold EXACTLY one character per frame: 94 frames, 94 characters.
    /// A space is not in "!".."~", so it needs a slot of its own - and here
    /// it takes the backtick's, because the backtick is the one printable
    /// character that appears in NO string in this project (the only
    /// literal holding it was this table).  That does not draw a backtick:
    /// the manual says the space image "will never be rendered", only its
    /// WIDTH is used - and with no slot at all the fallback is "the width of
    /// the widest character in the sprite font", which is an em-wide gap
    /// between every word in the game (see LL-067).
    var _fontText = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_ abcdefghijklmnopqrstuvwxyz{|}~";
    
    global.font_list = {
        p12: font_add_sprite_ext(spr_toonfont_12x, _fontText, true, -2),
        p16: font_add_sprite_ext(spr_toonfont_16x, _fontText, true, -2),
        p20: font_add_sprite_ext(spr_toonfont_20x, _fontText, true, -4),
        p32: font_add_sprite_ext(spr_toonfont_32x, _fontText, true, -4),
        p48: font_add_sprite_ext(spr_toonfont_48x, _fontText, true, -4)
    };
    
    #macro fnt_size12 global.font_list.p12
    #macro fnt_size16 global.font_list.p16
    #macro fnt_size20 global.font_list.p20
    #macro fnt_size32 global.font_list.p32
    #macro fnt_size48 global.font_list.p48

	//------------------- Initialize global values
	/// TRUE while the flex/screen layer is being verified (2026-10-21).
	/// Every UI log line is gated on this (ui_log, scr_meta_log, print), so
	/// it is the switch that makes the log the thing to read after a reload.
	/// Flip it back to false when the layer is trusted.
	global.devMode = false;   /// set developer mode

	/// One line that PROVES the fonts mapped, for global.devMode = true.
	/// Nothing else in the game can show a font metric.  Read it as:
	///   p16 i=.. W=.. space=.. line=..
	/// i narrower than W means `prop` was honoured, and `space` must be a
	/// third of W - if it ever reads the same as W, the space slot is gone.
	draw_set_font(fnt_size16);
	scr_meta_log("FONT  ", "p16 i=", string_width("i"),
	             " W=", string_width("W"),
	             " space=", string_width("a a") - 2*string_width("a"),
	             " line=", string_height("H"));
	draw_set_font(fnt_size48);
	scr_meta_log("FONT  ", "p48 W=", string_width("W"),
	             " space=", string_width("a a") - 2*string_width("a"));
	draw_reset();

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

	/// ---- the UI layer (2026-10-21) --------------------------------------
	/// BEFORE the options, because scr_loadOptions() writes the saved
	/// fullscreen flag into global.ui; and before any room exists, because
	/// scr_initResolution() (obj_title's Create) reads it back to decide how
	/// big the window is on this launch.
	ui_init();

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
