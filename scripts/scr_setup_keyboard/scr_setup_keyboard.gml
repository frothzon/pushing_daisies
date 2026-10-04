/// @description  scr_setup_keyboard();
function scr_setup_keyboard() {


	scr_reset_keys();
	//----------------- Key Codes
	scr_add_key(vk_escape,scr_keyDown_get,"Escape");        /// escape key
	scr_add_key(ord("W"),scr_key_get,"Up");                 /// up key
	scr_add_key(ord("A"),scr_key_get,"Left");               /// left
	scr_add_key(ord("S"),scr_key_get,"Down");               /// down
	scr_add_key(ord("D"),scr_key_get,"Right");              /// right
	scr_add_key(vk_numpad5,scr_keyDown_get,"Start");        /// pause
	scr_add_key(vk_numpad2,scr_keyDown_get,"Action");       /// a
	scr_add_key(vk_numpad1,scr_keyDown_get,"Back");         /// b

	//----------------- Load Keys
	print(key_type);
	print(key_name);
	scr_load_keys(global.saveName);
	print(key_type);
	print(key_name);



}
