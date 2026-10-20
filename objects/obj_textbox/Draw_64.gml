/// @description  draw textbox

/// backgorund rectangle
draw_set_halign(fa_left);
draw_set_colour(c_black);

draw9slice(spr_towerUpgrade,m_pos[0],m_pos[1],m_pos[4],m_pos[5],c_white,1);

/// text
draw_text_ext(m_pos[0] + t_xf,m_pos[1] + t_yf, string_hash_to_newline(message_draw), 28, t_width);

/// portrait - ONE whole sprite for the box, not a frame of `message_sprite`
/// and NOT indexed by `message_current` (LL-058): a portrait looked up in
/// an array whose message list can grow is a portrait that can end up
/// beside another creature's name.  Guarded: draw_sprite_stretched on a
/// missing sprite is a FATAL error (LL-012).
var _portrait = portrait;

var xx = m_pos[0] + p_pos[0],
    yy = m_pos[1] + p_pos[1];

if(sprite_exists(_portrait)){
    draw_sprite_stretched(_portrait,0,xx,yy,p_pos[2],p_pos[3]);
} else if(message_image[message_current] >= 0 && sprite_exists(message_sprite)){
    draw_sprite_stretched(message_sprite,message_image[message_current],xx,yy,p_pos[2],p_pos[3]);
}

