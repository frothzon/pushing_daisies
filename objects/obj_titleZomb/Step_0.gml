/// @description  Zombie State Machine

/// ---- THE SPRITER CLOCK (scr_scml_rig) ----------------------------------
/// rm_menu has no _levelControl, so THIS instance is the room's one update
/// owner: it is the only SCML consumer here, and there is exactly one of
/// it.  A no-op with no players.
zomb_scml_update();

/// increment state timer
state_timer++;

/// STATE MACHINE
switch(state){
    //---------------------- Idle State
    case 0:
        /// THE RIG, re-asserted every step exactly like scr_zombie_path
        /// does: the no-restart rule inside zomb_scml_play makes that safe
        /// (a looping clip is never reset), and it re-rigs the player
        /// after a stage boot reset it (zomb_scml_reset clears every
        /// player, and the menu is re-entered after every stage).
        ///
        /// idle retains its 2.0s title loop (LL-072). Walk and grab use
        /// the deliberately quicker 1.0s ZOMB_CYCLE_SECS duration; all
        /// three periods are seconds, not raw state steps.
        mon_rig_play(rig, ZOMB_ANIM.idle, ANIM_SECONDS_ZOMBIE_IDLE);
        /// if range too great, change to walk state
        if(abs(mouse_x-x) > 16){
            state = 1;
            state_timer = -1;
        }
        /// if player touches buttons, change to grab state
        if(position_meeting(mouse_x,mouse_y,_button)){
            if(state_timer > game_get_speed(gamespeed_fps)*wait_grab){
                state = 2;
                state_timer = -1;
                wait_grab = random_range(0.1,0.5);
            }
        }
        break;
    //---------------------------- Walk State
    case 1:
        /// the rig again, per step: walk at the deliberately quick one-second cycle
        mon_rig_play(rig, ZOMB_ANIM.walk, ZOMB_CYCLE_SECS);
        /// if zombie is within range of mouse, go back to idle
        if(abs(mouse_x-x) < 16){
            state = 0;
            state_timer = -1;
        } else {
            /// point in direction of movement.  Never sign(): sign(0) is
            /// 0, which hides the instance for a frame (LL-012).  The
            /// adapter mirrors the sign into set_transform, so a negative
            /// image_xscale mirrors the whole rig.
            var _dir = (mouse_x < x) ? -1 : 1;
            image_xscale = _dir * abs(image_xscale);
            /// move zombie
            x += _dir*1.5;
        }
        break;
    //---------------------------- Grab State
    case 2:
        /// initialize grab state - ONCE.  Unlike idle and walk, the grab
        /// is NOT re-asserted per step: zomb_scml_play restarts a finished
        /// non-looping clip when asked again, so a per-step call here
        /// would replay the grab for ever and it could never end.
        if(state_timer == 0){
            mon_rig_play(rig, ZOMB_ANIM.attack, ZOMB_CYCLE_SECS);
        } else {
            /// at animation end, change state: the CLIP's end when the
            /// SCML half answered (playing goes false at the clip's end -
            /// scr_scml_rig), the sheet's last frame otherwise (no player,
            /// sprite_index is the attack sheet and image_index advances)
            var _st = zomb_scml_state();
            if(!is_undefined(_st)){
                if(!_st.playing){
                    state = 0;
                    state_timer = -1;
                }
            } else if(image_index > image_number-1){
                state = 0;
                state_timer = -1;
            }
        }
        break;
}
