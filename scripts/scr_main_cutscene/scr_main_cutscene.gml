function scr_main_cutscene() {

	var ratio = __view_get( e__VW.HPort, 0 ) / __view_get( e__VW.WPort, 0 ),
	    sc_amt = 5;
        
	/// zoom
	if(section == 0){
	    /// center view and zoom in
	    if(__view_get( e__VW.WView, 0 ) > 500 + sc_amt){
	        __view_set( e__VW.WView, 0, __view_get( e__VW.WView, 0 ) - (sc_amt) );
	        __view_set( e__VW.HView, 0, __view_get( e__VW.HView, 0 ) - (sc_amt * ratio) );
	        __view_set( e__VW.XView, 0, lerp(__view_get( e__VW.XView, 0 ),obj_graveCenter.x - __view_get( e__VW.WView, 0 )*0.5,0.1) );
	        __view_set( e__VW.YView, 0, lerp(__view_get( e__VW.YView, 0 ),obj_graveCenter.y - __view_get( e__VW.HView, 0 )*0.5,0.1) );
	    } else {
	        section = 1;
	        section_timer = 0;
	    }  
	}

	/// move view
	if(section == 1){
	    section_timer++;
	    __view_set( e__VW.XView, 0, lerp(__view_get( e__VW.XView, 0 ),obj_graveCenter.x - __view_get( e__VW.WView, 0 )*0.5,0.1) );
	    __view_set( e__VW.YView, 0, lerp(__view_get( e__VW.YView, 0 ),obj_graveCenter.y - __view_get( e__VW.HView, 0 )*0.5,0.1) );
	    if(section_timer > room_speed*1.5){
	        section = 2;
	        scr_playSound(snd_zomb_die,false);
	        text_box = show_message_box(0,c_white,"BRAINSSS.... #BRAAIINNSSS... #BRAAIINNSSSESS... ");
	        section_timer = 0;
	    }
	}

	/// wait a second...
	if(section == 2){
	    section_timer++;
	    if(section_timer > room_speed*2){
	        section = 3;
	        section_timer = 0;
	        if(scr_isValidInstance(text_box)){
	            instance_destroy(text_box);
	        }
	    }
	}

	sc_amt = 10;
	/// return to game
	if(section == 3){
	    if(__view_get( e__VW.WView, 0 ) < 960){
	        __view_set( e__VW.WView, 0, __view_get( e__VW.WView, 0 ) + (sc_amt) );
	        __view_set( e__VW.HView, 0, __view_get( e__VW.HView, 0 ) + (sc_amt * ratio) );
	    } else {
	        __view_set( e__VW.WView, 0, 960 );
	        __view_set( e__VW.HView, 0, 960 * ratio );
	        section_timer++;
	    }
	    if(section_timer > room_speed){
	        //------------- create control objects ---------//
	        instance_create(0,0,_levelControl);
	        //----------------------------------------------//
	        scr_changeState(scr_main_normal);
	    }
	}


	/// skip
	if(section < 3 && mouse_check_button(mb_any) && scr_stateTime() > 10){
	    section = 3;
	    section_timer = 0;
	}



}
