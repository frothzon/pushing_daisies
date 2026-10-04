/// @description  Menu states - plain enum + helpers
///
/// This replaces the old scr_runState() / scr_changeState() state machine for
/// the title menu.  That machine stored *script functions* inside the `state`
/// variable and used numeric sentinels ("if(state < 0) ..."), which stopped
/// meaning anything once the project was imported from GM8 into GMS2.
///
/// The menu is now driven by a plain switch over MENU_STATE - see
/// objects/Menu/Step_0.gml.

enum MENU_STATE {
	START = 0,
	NEW_GAME,
	CONTINUE,
	OPTIONS,
	RETURN,
	QUIT,
}

/// Human readable state name, used by the debug logging.
function scr_menu_state_name(_state) {
	switch(_state){
		case MENU_STATE.START:    return "START";
		case MENU_STATE.NEW_GAME: return "NEW_GAME";
		case MENU_STATE.CONTINUE: return "CONTINUE";
		case MENU_STATE.OPTIONS:  return "OPTIONS";
		case MENU_STATE.RETURN:   return "RETURN";
		case MENU_STATE.QUIT:     return "QUIT";
	}
	return "UNKNOWN(" + string(_state) + ")";
}

/// Request a state change.  The change is applied at the top of the next Menu
/// Step, which guarantees that every state gets exactly one frame with
/// menu_state_time == 0 (its "just entered" frame).
///
/// Must be called with the Menu instance in scope, e.g.
///     with(Menu){ scr_menu_changeState(MENU_STATE.OPTIONS); }
function scr_menu_changeState(_new_state) {
	print("MENU  request ", scr_menu_state_name(menu_state), " -> ", scr_menu_state_name(_new_state));
	menu_state_next = _new_state;
}

/// Print the whole menu / button state (dev mode only).
///
/// The Menu instance is passed in, so this can be called from ANY scope and
/// nothing is looked up in the caller's instance.  Call it like:
///     scr_menu_debug(id, "state entered");               /// from the Menu
///     scr_menu_debug(_menu, "button click");             /// from a button
function scr_menu_debug(_menu, _where) {
	if(!global.devMode) return;
	if(!instance_exists(_menu)){
	    print("MENU  [", _where, "] no Menu instance");
	    return;
	}
	if(!variable_instance_exists(_menu, "menu_state")){
	    print("MENU  [", _where, "] ", _menu, " has no menu_state");
	    return;
	}
	print("MENU  [", _where, "] state=", scr_menu_state_name(_menu.menu_state),
	      " time=", _menu.menu_state_time, " next=", _menu.menu_state_next);
	/// only dump what actually exists - a debug helper must never be able to
	/// throw an error and abort the event that called it
	if(variable_instance_exists(_menu, "menu_button")){
	    scr_menu_debug_buttons("menu_button", _menu.menu_button);
	} else {
	    print("        menu_button not set yet");
	}
	if(variable_instance_exists(_menu, "menu_options")){
	    scr_menu_debug_buttons("menu_options", _menu.menu_options);
	} else {
	    print("        menu_options not set yet");
	}
}

/// Dump one button array: index, text, active, visible and whether the slot
/// really holds a live instance.  undefined / noone / 0 are all bad news -
/// a bare with() or instance_exists() on 0 targets object index 0 (_button).
function scr_menu_debug_buttons(_label, _arr) {
	if(!global.devMode) return;
	if(!is_array(_arr)){
	    print("        ", _label, " is not an array (", _arr, ")");
	    return;
	}
	var _n = array_length(_arr);
	print("        ", _label, " length=", _n);
	for (var _i = 0; _i < _n; _i += 1) {
		var _slot = string(_i);
		var _b = _arr[_i];
		if(_b == undefined){
			print("          [", _slot, "] undefined");
		} else if(_b == noone){
			print("          [", _slot, "] noone");
		} else if(_b == 0){
			print("          [", _slot, "] 0  <- object index 0, would hit EVERY instance");
		} else if(!instance_exists(_b)){
			print("          [", _slot, "] ", _b, " - not a live instance");
		} else if(!variable_instance_exists(_b, "text")){
			print("          [", _slot, "] ", _b, " - instance without button variables");
		} else {
			/// read the button's own variables in the button's own scope
			with(_b){
				print("          [", _slot, "] '", text, "' active=", active,
				      " visible=", visible, " id=", id);
			}
		}
	}
}
