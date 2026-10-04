/// @description  scr_iniButton();
function scr_iniButton() {
	/*
	    Setup the variables
	    to run the button
	*/

	text            = "New Button";
	script          = fcn_button_test;
	blend_normal    = c_white;
	blend_hilight   = c_ltgray;
	blend_click     = c_dkgray;
	mouse_gui       = array(0,0);
	blend_timer     = 0;
	text_font       = fnt_size16;
	active          = true;
	hovering        = false;        /// debug: edge detection for the hover log

	///---------------- Get Scaling
	scr_scaleButton();

	print("BTN   init   '", text, "' active=", active, " callable=", is_callable(script));


}
