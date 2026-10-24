/// @description  The blurred backdrop for the screens that sit OVER the world.
///
/// THE ROOM ALREADY CARRIES ONE
/// ----------------------------
/// rooms/rm_menu has a filter layer called "Blur_Effect" - an FX layer holding
/// the built-in `_filter_large_blur` - placed directly ABOVE the sidewalk
/// backdrop and BELOW the instance layer the Menu and its buttons sit on.  A
/// filter applies to the layers below it, so that one layer blurs exactly the
/// art and nothing else; the panels the meta screens draw in Draw GUI are
/// painted after the room, so they stay sharp.  All GML has to do is switch it:
/// the layer is added in the IDE with visible = false, so the title screen
/// starts sharp and these functions turn it on for the four meta screens.
///
/// WHAT THIS REPLACED
/// ------------------
/// The first version baked a half-size copy of the backdrop through shd_blur
/// into a sprite once per run and drew it stretched under the panels, because
/// blurring every frame costs ~83 M texture reads.  LL-074 is that bake's
/// post-mortem (it had to inherit the Draw GUI projection, and
/// `matrix_build_orthographic` does not exist).  The room's own filter does the
/// same job in one call, at full resolution, with no sprite to leak, no one-off
/// hitch and no cache to keep in step - so the bake is gone.
///
/// ON AND OFF ARE TWO FLAGS
/// ------------------------
/// layer_enable_fx() is what makes a filter run; the layer's own visibility is
/// the eye in the room editor, and the layer ships with the eye closed.  This
/// sets both, because a hidden FX layer draws nothing whatever its flag says -
/// that is the shape of the "effect layer works in the room editor but not in
/// the game" report on the GameMaker tracker, where the project had called
/// layer_enable_fx(..., false) and never turned it back on.
///
/// WHICH SCREENS GET IT
/// --------------------
/// The four meta screens: the world map, Deploy, the Garden Book and Results.
/// They paint panels over the room, and the sharp sidewalk art behind a panel
/// competes with it.  The title screen and the Options screen keep the backdrop
/// SHARP - the title is the one screen that is a picture rather than a form, and
/// Options is a stack of sliders over the same art the title shows.

/// The room layer that carries the filter.  A NAME, not an id: the layer is a
/// room asset, so its id does not exist until rm_menu is the current room.
#macro MENU_BLUR_LAYER "Blur_Effect"

/// The FX layer in the current room, or -1 when there is none.
///
/// The id is cached per instance: a layer name is a string search at run time
/// and this is called every frame.  The cache is re-checked by name as well as
/// by handle, because a layer id is only unique inside the room that made it -
/// a stale handle could point at somebody else's layer after a room change.
function menu_blur_layer() {
	var _lyr = variable_instance_exists(id, "menu_blur_lyr") ? menu_blur_lyr : -1;
	if(_lyr != -1 && layer_exists(_lyr) && layer_get_name(_lyr) == MENU_BLUR_LAYER) return _lyr;
	if(!layer_exists(MENU_BLUR_LAYER)) return -1;
	menu_blur_lyr = layer_get_id(MENU_BLUR_LAYER);
	return menu_blur_lyr;
}

/// Does the screen in `_state` draw over the world?  Guarded against a state
/// that is not one of ours (a -1 on the first frame), which is every caller's
/// first frame.
function menu_blur_wanted(_state) {
	if(!is_real(_state)) return false;

	switch(_state){
		case MENU_STATE.WORLD_MAP:
		case MENU_STATE.DEPLOY:
		case MENU_STATE.GARDEN:
		case MENU_STATE.RESULTS:
			return true;
	}
	return false;
}

/// Is the backdrop blurred RIGHT NOW?  Both flags: the layer ships with
/// visible = false and effectEnabled = true, so either one on its own would
/// answer "on" for a title screen that is not blurred.
function menu_blur_is_on() {
	var _lyr = menu_blur_layer();
	if(_lyr == -1) return false;
	return layer_get_visible(_lyr) && layer_fx_is_enabled(_lyr);
}

/// Blur the backdrop on the screens that sit over the world, and clear it on
/// the ones that do not.  Returns the state the layer is in afterwards - false
/// also means "this room cannot blur" (rm_test has no such layer), which is the
/// honest answer and leaves the sharp backdrop standing (LL-002: nothing on the
/// draw path may throw).
///
/// Call it with the Menu in scope, once per Step (objects/Menu/Step_0.gml).
/// Every frame rather than only on a state change, because the ROOM owns the
/// layer: a fresh entry to rm_menu starts from the asset, and only asking the
/// layer what it is doing can notice that.
function menu_blur_apply(_state) {
	var _lyr = menu_blur_layer();
	if(_lyr == -1) return false;

	var _want = menu_blur_wanted(_state);

	/// -1 means "this Menu instance has not decided yet", and that first
	/// decision is applied EVEN WHEN IT IS OFF.  The asset ships the filter
	/// ENABLED (effectEnabled) with the layer hidden (visible), so whichever of
	/// the two flags a runtime actually honours, "off" has to be said out loud
	/// once - assuming the room already has it right is how the title screen
	/// ends up blurred.
	var _applied = variable_instance_exists(id, "menu_blur_applied") ? menu_blur_applied : -1;
	if(_applied == _want && menu_blur_is_on() == _want) return _want;

	menu_blur_applied = _want;
	layer_enable_fx(_lyr, _want);
	layer_set_visible(_lyr, _want);

	/// Log the DECISION once, not the attempt: if the filter never made it into
	/// the build then menu_blur_is_on() stays false and a line here would print
	/// every frame.  The baseline above is the room's opening state rather than
	/// a transition, so it gets no line - what a run should show is one "on" on
	/// the first meta screen and one "off" on the way back to a sharp screen.
	if(_applied != -1 && _applied != _want){
		print("MENU  blur ", _want ? "on" : "off", "  ", MENU_BLUR_LAYER,
		      "  [", scr_menu_state_name(_state), "]");
	}
	return _want;
}
