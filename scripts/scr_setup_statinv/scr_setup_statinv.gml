/// @description  scr_setup_statinv();
function scr_setup_statinv() {
	/*------------------------------
	setup the static inventory
	--------------------------------*/

	globalvar STATINV;
	STATINV = id;

	static_list = -1;   /// list of all items
	section_name = "StaticInv";
	savefile = global.saveName;
	savekey = "0";

	//----------------------------------- Setup Image Drawing Properties
	x_draw = display_get_gui_width()-56; /// x position to draw it at
	y_draw = 24;            /// y position to draw it at
	w_draw = 32;            /// width of item
	h_draw = 32;            /// height of item
	text_xoff = 0;          /// text position x offset
	text_yoff = 0;          /// text position y offset
	draw_stack_w = 0;       /// stack items horizontally 
	draw_stack_h = 1;       /// stack items virtically

	//------------------------------------ Set Update Speed
	frame_skip = 3;                 /// frame skip value
	update_frame = frame_skip;      /// current frame index
	//------------------------------------ Setup Static Items
	points = create_static_item(spr_points,"Points");
	money = create_static_item(spr_coin,"Money");
	life = create_static_item(spr_heart,"Life");
	waves = create_static_item(spr_wave,"Wave");

	//------------------------------------- Load File
	/// The meta save belongs to scr_load_meta() now (roadmap 0.1).
	/// This call was commented out AND its path used working_directory,
	/// which is read-only once the game is exported - so a "static"
	/// inventory was never actually restored.  Left unwired on purpose:
	/// the static inventory is per-run state (points/money/life/waves),
	/// not saved data.  Per-run state is reset by the level, and the
	/// things that DO persist (seeds, clovers, shards, unlocks) live in
	/// global.meta.
	//scr_load_static(savefile,savekey);
}
