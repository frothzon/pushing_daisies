/// @description  change draw position
y -= z_climb*2-12;

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
