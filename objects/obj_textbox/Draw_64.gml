/// @description  draw textbox

/// backgorund rectangle
draw_set_halign(fa_left);
draw_set_colour(c_black);

draw9slice(spr_towerUpgrade,m_pos[0],m_pos[1],m_pos[4],m_pos[5],c_white,1);

/// text
draw_text_ext(m_pos[0] + t_xf,m_pos[1] + t_yf, string_hash_to_newline(message_draw), 28, t_width);

/// image
if(message_image[message_current] >= 0){
    var xx = m_pos[0] + p_pos[0],
        yy = m_pos[1] + p_pos[1];
    draw_sprite_stretched(message_sprite,message_image[message_current],xx,yy,p_pos[2],p_pos[3]);
}

