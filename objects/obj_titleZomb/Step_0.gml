/// @description  Zombie State Machine

/// increment state timer
state_timer++;

/// STATE MACHINE
switch(state){
    //---------------------- Idle State
    case 0: 
        /// initialize idle state
        if(state_timer == 0){
            sprite_index = spr_grumble_idle;
            image_index = 0;
            /// a DURATION, not a speed: 60 steps is 1 s at 60 fps, and
            /// re-drawing the zombie cannot change it (LL-030)
            image_speed = scr_animSpeedForSteps(sprite_index, 60);
        }
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
        /// initialize walk state
        if(state_timer == 0){
            sprite_index = spr_grumble_walk;
            image_index = 0;
            image_speed = scr_animSpeedForSteps(sprite_index, 60);
        }
        /// if zombie is within range of mouse, go back to idle
        if(abs(mouse_x-x) < 16){
            state = 0;
            state_timer = -1;
        } else {
            /// point in direction of movement.  Never sign(): sign(0) is
            /// 0, which hides the instance for a frame (LL-012)
            var _dir = (mouse_x < x) ? -1 : 1;
            image_xscale = _dir * abs(image_xscale);
            /// move zombie
            x += _dir*1.5;
        }
        break;
    //---------------------------- Grab State
    case 2:
        /// initialize grab state
        if(state_timer == 0){
            sprite_index = spr_grumble_attack;
            image_index = 0;
            image_speed = scr_animSpeedForSteps(sprite_index, 60);
        /// at animation end, change state
        } else if(image_index > image_number-1){
            state = 0;
            state_timer = -1;
        }
        break;      
}

