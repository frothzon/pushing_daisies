/// @description  scr_level_boot();  - the ONE place a stage begins.
///
/// WHY THIS EXISTS (2026-10-17).  The level used to be bootstrapped entirely
/// from Control/Create_0, which did instance_create(0,0,_mainControl).  Control
/// is a PERSISTENT instance and is the FIRST instance in rm_test's creation
/// order, so its Create event runs exactly ONCE per launch - while
/// _mainControl, _levelControl, _viewControl and _dayCycle are all
/// non-persistent and die on Room End.  The second visit to the room therefore
/// had no main controller at all: scr_main_startup never ran (no ground_map,
/// no load_max, so scr_iniTileBuilder was never called and the terrain never
/// appeared) and the cutscene never ran (no _levelControl, so no waves).
///
/// A persistent instance DOES keep its Room Start and Room End events, but not
/// its Create - so the fix is not to make Control persistent-aware, it is to
/// stop making an instance's Create the thing that boots the level.  This is
/// called from rm_test's ROOM CREATION CODE, which runs on EVERY entry to the
/// room, after every instance's Create event - so the room's own instances
/// (obj_raiseGround, obj_spawn, obj_graveCenter ...) already exist, which is
/// what scr_gridSetObject needs when it iterates them.
///
/// It is IDEMPOTENT: whatever a previous visit left behind is destroyed before
/// anything is created, so it is safe to call twice and safe after a
/// room_restart() (LL-002: every guard here is one that cannot throw).
///
/// @returns nothing.  It logs, so a boot that did not happen is visible.
function scr_level_boot() {
	/// ---- 0. nothing from the last visit may survive --------------------
	/// On a normal room change this is a no-op, because all four are
	/// non-persistent and the room change already destroyed them.  It matters
	/// for the paths that do NOT change room - a retry that restarts the room
	/// in place, or a deploy to the room you are already in - where a stale
	/// controller would otherwise compete with the new one.
	/// KNOWN GAP: instance_destroy() does not fire _levelControl Room End,
	/// which is where its two mp_grids are freed.  A same-room restart
	/// therefore leaks two grids.  Harmless at the size of a retry, and
	/// the retry screen should call a scr_level_teardown() rather than
	/// making this function know _levelControl internals (card
	/// fadeout-retry-noop).
	with(_mainControl)  instance_destroy();
	with(_levelControl) instance_destroy();
	with(_viewControl)  instance_destroy();
	with(_dayCycle)     instance_destroy();

	/// ---- 1. the data the level reads -----------------------------------
	/// Never throws and never returns a non-array, so stage_current() below
	/// is safe to read on the very first frame of a launch.
	level_data_ensure();
	var _row = stage_current();

	/// ---- 2. the controllers, in dependency order -----------------------
	/// _mainControl runs scr_main_startup, which builds the terrain grid and
	/// tiles it one row a frame; scr_main_startup creates the view and the
	/// day cycle; the cutscene it hands over to is what creates
	/// _levelControl.  So this ONE instance is the whole chain - if it exists
	/// the stage builds, and if it does not, nothing else will.
	/// instance_create() is this project's shim over instance_create_depth,
	/// using the object's own depth - the same call Control used to make.
	instance_create(0, 0, _mainControl);

	/// ---- the camera, in the DESIGN aspect (2026-10-21) -----------------
	/// A room's view comes from its .yy, which is authored at 960x540.  On a
	/// window that is not 16:9 the GUI is a different width, and
	/// points_to_gui() maps the pointer with gui/view on each axis - so the
	/// view has to take the same aspect or every click in the stage lands in
	/// the wrong place (LL-068).  AFTER _mainControl exists: its Create is
	/// what gives view 0 its camera.
	ui_screen_apply_camera();
	ui_screen_log();

	/// the line to look for.  `main=` must be 1 on EVERY entry to the room,
	/// the first and the fifth alike - that is the whole point of this file.
	scr_meta_log("LEVEL", "boot ", _row.region, "-", _row.stage,
	             " waves=", _row.waves, "  main=", instance_number(_mainControl));

	/// the band every actor sorts in (LL-059): depth comes from the world y
	/// of the FEET, one unit per 32px, starting at -60.  Logged once per
	/// entry because a wrong depth rule is a screenshot bug that reads as an
	/// art problem - this line makes it arithmetic.  -50 is the shadows and
	/// ~0 is the ground, so the band has to stay between them.
	scr_meta_log("DEPTH", "actors sort by feet: y 0..", room_height,
	             " -> depth ", scr_depth_band(0), " .. ",
	             scr_depth_band(room_height),
	             "  (plants, monsters, gravestones)");
}
