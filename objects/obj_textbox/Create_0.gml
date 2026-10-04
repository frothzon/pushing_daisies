/// @description  setup textbox
message[0] = "This message should not appear, if it does it is a bug.";

/// letter variables
message_current = 0;
message_end = 1;
message_draw = "";
message_speed = 1;
characters = 0;
action_hold = 0;

/// get the number of characters in the first message
message_length = string_length(message[message_current]);

/// image to be drawn on textbox
message_image[0] = -1;
message_color[0] = c_white;
message_sprite = spr_zombie;

/// box dimensions
m_pos[0] = display_get_gui_width()*0.5 - 200;   /// x1
m_pos[1] = display_get_gui_height()*0.5 - 150;  /// y1
m_pos[2] = m_pos[0] + 400;                      /// x2
m_pos[3] = m_pos[1] + 150;                      /// y2
m_pos[4] = 400;
m_pos[5] = 150;

/// picture dimensions (offset from box)
p_pos[0] = 2;   /// x1
p_pos[1] = 16;  /// y1
p_pos[2] = 64;  /// w
p_pos[3] = 64;  /// h

t_xf = p_pos[0] + p_pos[2] + 16;      /// text x offset
t_yf = 12;
t_width = m_pos[2] - m_pos[0] - t_xf - 8;               /// text width

