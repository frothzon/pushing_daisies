/// @description  Type Message

var actionKey = mouse_check_button(mb_left);

action_hold = 0;
if(actionKey){
    action_hold = 2;
}

/// check if need more characters
if(characters < message_length){
    characters += min(message_length,message_speed+action_hold);
    
    /// copy string to character
    message_draw = string_copy(message[message_current], 0, floor(characters));
} else {
    /// finished adding characters
    if(actionKey){
        /// check for more messages
        if(message_current < message_end){
            /// reset message from start of new message
            message_current += 1;
            message_length = string_length(message[message_current]);
            characters = 0;
            message_draw = "";
        } else {
            /// destroy the object
            instance_destroy();
        }
    }
}



