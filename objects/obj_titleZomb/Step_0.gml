/// @description  Zombie State Machine

/// increment state timer
state_timer++;

/// STATE MACHINE
switch(state){
    //---------------------- Idle State
    case 0: 
        /// initialize idle state
        if(state_timer == 0){
            sprite_index = spr_hair_idle;
            image_index = 0;
            image_speed = 0.5;
        }
        /// if range too great, change to walk state
        if(abs(mouse_x-x) > 16){
            state = 1;
            state_timer = -1;
        }
        /// if player touches buttons, change to grab state
        if(position_meeting(mouse_x,mouse_y,_button)){
            if(state_timer > room_speed*wait_grab){
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
            sprite_index = spr_hair_walk;
            image_index = 0;
            image_speed = 0.5;
        }
        /// if zombie is within range of mouse, go back to idle
        if(abs(mouse_x-x) < 16){
            state = 0;
            state_timer = -1;
        } else {
            /// point in direction of movement
            image_xscale = sign(mouse_x-x);
            /// move zombie
            x += image_xscale*1.5;
        }
        break;
    //---------------------------- Grab State
    case 2:
        /// initialize grab state
        if(state_timer == 0){
            sprite_index = spr_hair_grab;
            image_index = 0;
            image_speed = 0.5;
        /// at animation end, change state
        } else if(image_index > image_number-1){
            state = 0;
            state_timer = -1;
        }
        break;      
}

