/// @description  change draw position
///
/// POST DRAW must EXACTLY undo the lift PRE DRAW applied (Draw_72).
/// It used to subtract the same amount a second time, so the instance's
/// y stepped NORTH by 2*(z_climb*2-12) every frame.  On a path that was
/// invisible - the path follower rewrites x/y every step - but the
/// moment a monster had no path, which is exactly what a failed re-path
/// used to leave behind, nothing rewrote y and the zombie marched off
/// the top of the map, through every wall and tower (LL-025).
y += z_climb*2-12;

/// draw life

var _xa = bbox_left - 4,
    _xb = bbox_right + 4;
draw_set_alpha(0.75);
var _y2 = bbox_bottom + 4;
draw_set_colour(c_black);
draw_line_width(_xa,_y2,_xb,_y2,5);
draw_set_colour(c_orange);
var _x2 = lerp(_xa+1,_xb-1,data[MON.life]/data[MON.maxLife]);
draw_line_width(_xa+1,_y2+1,_x2,_y2+1,3);
draw_set_alpha(1);

/// debug stats

/*
if(global.devMode){
    if(path_exists(myPath)){
        var _dis = path_position,
            _txt = concat("Path pos ",_dis);
        draw_text(x,y,_txt);
    } else {
        draw_text(x,y,"No Path");
    }
}
*/

/* */
/*  */
