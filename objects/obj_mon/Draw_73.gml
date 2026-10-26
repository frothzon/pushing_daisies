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

/// ---- draw life ------------------------------------------------------
/// The fill is a CLAMPED ratio over a READ denominator (LL-056):
///
///   * `life` goes NEGATIVE.  scr_do_damage subtracts the whole hit, and
///     scr_zomb_step notices the death on the NEXT step (the DIE entry code
///     runs then), so a monster killed by a tower that steps later in the
///     same frame draws ONE frame below zero.
///
///     This bullet used to add "and scr_zomb_death only runs inside
///     scr_zombie_path, so a monster killed while EMERGING shows a badly
///     negative bar for up to 60 steps and then HEALS ITSELF".  The heal
///     went on 2026-10-18, and no state is exempt from the death check any
///     more - the emerge cannot outlive a kill (LL-080).
///   * `maxLife` is data - a zero row divides by zero.
///
/// An unclamped ratio makes lerp() EXTRAPOLATE: the fill was drawn to the
/// left of the bar with a negative width, which is what "the HP bar can
/// have negative width" looked like.  A dead monster is an EMPTY bar.
var _xa    = bbox_left - 4,
    _xb    = bbox_right + 4,
    _max   = data[MON.maxLife],
    _ratio = (_max > 0) ? clamp(data[MON.life] / _max, 0, 1) : 0,
    _y2    = bbox_bottom + 4;

if(data[MON.life] < 0 && !variable_instance_exists(id, "hp_under_reported")){
    /// one line per monster, the first time it is DRAWN BELOW ZERO: a tower
    /// is hitting something already dead, or the emerge reset is about to
    /// heal it (card emerge-resets-life).  Guarded so it cannot throw
    /// (LL-002), and once per instance so it cannot spam.
    hp_under_reported = true;
    print("MON   life<0  ", data[MON.name],
          "  life=", data[MON.life], "/", _max,
          "  bar=", round(_ratio*100), "%");
}

draw_set_alpha(0.75);
draw_set_colour(c_black);
draw_line_width(_xa,_y2,_xb,_y2,5);
draw_set_colour(c_orange);
/// only draw the fill when the bar has a measurable width: the emerge
/// starts at image scale 0, which collapses the bbox to a point
if(_xb - _xa >= 2){
    var _x2 = lerp(_xa+1, _xb-1, _ratio);
    draw_line_width(_xa+1,_y2+1,_x2,_y2+1,3);
}
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
