/// @description  scr_stpButton();
function scr_stpButton() {
	/*
	    Update button appearance
	    and run code when clicked

	    A hidden button is not a button: it must not hover, must not play
	    the click sound, and must not be able to run its script.  Only
	    `active` stopped the script before, so a hidden button would still
	    beep when clicked through.
	*/
	if(!visible) exit;



	//--------------- Button State
	mouse_gui = points_to_gui(mouse_x,mouse_y,0);  /// mouse coordinates tin GUI layer

	/// check if mouse is in button
	if(point_in_rectangle(mouse_gui[0],mouse_gui[1],x,y,x+sprite_width,y+sprite_height)){
	    if(!hovering){
	        hovering = true;
	        print("BTN   hover  ON   '", text, "' active=", active);
	    }
	    /// only change blend mode if mouse has been outside of button
	    if(image_blend == blend_normal){
	        image_blend = blend_hilight;
	    }
	    /// if button clicked, change blend mode and execute script
	    if(mouse_check_button_pressed(mb_left)){
	        image_blend = blend_click;
	        button_state = 2;
	        blend_timer = room_speed*0.5;
	        scr_playSound(snd_button,false);
	        print("BTN   click  '", text, "' active=", active, " callable=", is_callable(script));
	        /// dump the menu state too.  The Menu instance is looked up and
	        /// passed IN - the button cannot read the menu's variables.
	        var _menu = instance_find(Menu, 0);
	        if(_menu != noone && instance_exists(_menu)) scr_menu_debug(_menu, "button click");
	        /// run script
	        if(active){
	            /// GMS2 scripts are function references, not numeric script
	            /// indices, so the old "script >= 0" test meant nothing.
	            if(is_callable(script)){
	                print("BTN   call   '", text, "'");
	                run_script(script, id);
	                print("BTN   return '", text, "'");
	            } else {
	                print("BTN   SKIP   '", text, "' - script is not callable");
	            }
	        } else {
	            print("BTN   SKIP   '", text, "' - button is inactive");
	        }
	    }
	} else {
	    if(hovering){
	        hovering = false;
	        print("BTN   hover  OFF  '", text, "'");
	    }
	    /// reset blending when mouse outside image
	    image_blend = blend_normal;
	}
	if(blend_timer > -1){
	    blend_timer--;
	}
	if(blend_timer == 0){
	    image_blend = blend_normal;
	}



}
