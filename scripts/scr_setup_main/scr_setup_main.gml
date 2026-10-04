/// @description  scr_setup_main();
function scr_setup_main() {
	/*
	    setup the main state
	*/

	/// state machine
	randomize();
	scr_setupState();

	/// surface for pausing
	pause_surf = -1;
	pause_text = "";
	pause_color = c_black;
	grab_surf = false;
	text_alpha = 0;
	fade_in = false;

	/// loading
	load_amount = 0;
	load_finished = false;

	load_counter = 0
	load_max = 0;
	load_bg = bck_tile_dirt;
	load_color = c_white;


	/// High Score
	highScoreTable = -1;    /// array of high scores
	highScoreIndex = -1;    /// index player is in the array
	highScoreFade = 0;      /// fade in high score table
	blackScreen = 0;        /// fade screen to black


	/// cut scene
	section = 0;
	section_timer = 0;
	text_box = noone;




}
