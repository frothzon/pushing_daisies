/// @description  scr_setup_gamepad();
function scr_setup_gamepad() {

	scr_reset_keys();
	//----------------- Key Codes
	scr_add_key(vk_escape,scr_keyDown_get,"Escape");            /// escape key
	scr_add_key(gp_padu,scr_gamepad_get,"Up");                  /// up key
	scr_add_key(gp_padl,scr_gamepad_get,"Left");                /// left
	scr_add_key(gp_padd,scr_gamepad_get,"Down");                /// down
	scr_add_key(gp_padr,scr_gamepad_get,"Right");               /// right
	scr_add_key(gp_start,scr_gamepadDown_get,"Pause");          /// pause
	scr_add_key(gp_face1,scr_gamepadDown_get,"A-button");       /// a
	scr_add_key(gp_face3,scr_gamepadDown_get,"B-button");       /// b
	input_state = 1;

	//------------------ input device
	input_control = scr_gamepad_get;



}
