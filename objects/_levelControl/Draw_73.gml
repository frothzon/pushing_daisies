/// @description  draw grid
if(instance_exists(obj_tower_edit)){
    grid_opacity = lerp(grid_opacity,0.5,0.1);
} else {
    grid_opacity = lerp(grid_opacity,0,0.1);
}

if(grid_opacity > 0.1){
    draw_set_blend_mode(bm_add);
    draw_background_tiled_ext(bck_drawGrid,0,0,1,1,c_white,grid_opacity);
    draw_set_blend_mode(bm_normal);
}
/// ---- the tower the pointer is over: its CELL, and its LEVEL -----------
/// THE CELL, not the art.  A tower's footprint is ONE 32x32 cell (LL-027)
/// while its art is up to 96px across at draw_scale 0.5 - so the square
/// under a plant is the grid it is standing on, which is also the cell a
/// click selects.  Both come from grid_col/grid_row, the indices the tower
/// itself blocked in Create_0, so this cannot drift from the grid (LL-021).
/// The grid origin is (-cell_w,-cell_h), so cell c spans ((c-1)*cell_w) to
/// (c*cell_w) - and a placed tower sits at its cell's centre.
///
/// ADDITIVE, the same as the placement grid just above, so the highlight IS
/// the grid brightening rather than a second thing laid over it.  The LEVEL
/// is drawn after it with bm_normal: a black outline adds NOTHING under
/// additive blending, so the number would come out as bare white over
/// whatever it happened to sit on (LL-046).
///
/// Guarded because a DRAW path must not throw (LL-002) - a control object
/// that outlived its level, or a tower that exists but has not been given
/// its data yet, must draw nothing rather than take the frame down.
var _hov = noone;
/// max(), not TOWER.level on its own: the block below reads the level (the
/// number) AND the range (the ring), so the test has to cover the LAST field
/// it reaches for.  Today range is 0 and level is 4, so this is 4 either way
/// - it is written like this so that reordering the enum cannot turn a guard
/// into a crash (LL-002).
var _data_need = max(TOWER.level, TOWER.range);
if(scr_isValidInstance(tower_hovered)
   && variable_instance_exists(tower_hovered, "grid_col")
   && variable_instance_exists(tower_hovered, "data")
   && is_array(tower_hovered.data)
   && array_length(tower_hovered.data) > _data_need){
    _hov = tower_hovered;
}

if(_hov != noone){
    /// the two knobs, and both are "how much light is ADDED", not opacity.
    /// The fill says "this cell"; the edge says "cell" rather than "glow".
    /// Halved once the range ring arrived (2026-10-15): the ring is now the
    /// loud cue, so the cell only has to say "this one" without lifting the
    /// plant off the ground it is standing on.
    var _fill = 0.10,
        _edge = 0.25,
        _cx = (_hov.grid_col - 1) * cell_w,
        _cy = (_hov.grid_row - 1) * cell_h;

    draw_set_colour(c_white);
    draw_set_blend_mode(bm_add);
    draw_set_alpha(_fill);
    draw_rectangle(_cx, _cy, _cx + cell_w, _cy + cell_h, false);
    draw_set_alpha(_edge);
    draw_rectangle(_cx, _cy, _cx + cell_w, _cy + cell_h, true);
    draw_set_blend_mode(bm_normal);
    draw_set_alpha(1);

    /// The LEVEL, above the plant's head.  The top of the ART rather than a
    /// guessed offset, so a tall daisy and a short Tulip each get the number
    /// clear of their own art - and sprite_get_bbox_top() is in SPRITE
    /// pixels, so it scales with draw_scale.
    ///
    /// sprite_get_bbox_top() IS MEASURED FROM THE CANVAS, NOT THE ORIGIN
    /// ("relative to the upper left corner of the base sprite asset being
    /// 0,0"), and these sprites put their origin at the plant's FEET -
    /// spr_tulip_idle_192x is 192x192 with origin (96,136) and bbox_top 11,
    /// so the top of its art is 125px above the origin.  The top of
    /// the art relative to the origin is therefore the DIFFERENCE, which is
    /// negative; bbox_top on its own would put the number down in the middle
    /// of the plant.  The break below is inside an unclosed bracket on
    /// purpose - a newline after a COMPLETE expression ends the statement.
    ///
    /// sprite_exists() first, because sprite_get_bbox_top(-1) is fatal
    /// (LL-012).  White with a black outline, which is the project's
    /// on-world text (the banner and the spawn countdown).
    var _top = _hov.y - 6;
    if(sprite_exists(_hov.sprite_index)){
        _top = _hov.y + (sprite_get_bbox_top(_hov.sprite_index)
                         - sprite_get_yoffset(_hov.sprite_index)) * abs(_hov.draw_scale) - 6;
    }
    draw_set_font(fnt_size20);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_text_outline(_hov.x, _top, string(_hov.data[TOWER.level]),
                      c_white, c_black, 2);
    /// put the text state back: the range ring and the path below draw
    /// in this same event, and so does whatever follows it
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fnt_size16);
}


/// draw tower range

/// ---- the range is a RING, not a decal (2026-10-15) -------------------
/// spr_towerRange filled the whole circle with a soft decal at 15%, and it
/// was driven by tower_selection - so a CLICK put a wash over a large part of
/// the garden and the ground underneath stopped being readable.  In its
/// place: a 3px additive white ring, which says "this tower reaches here" and
/// leaves everything inside AND outside it legible.
///
/// Three draw_circle calls, because draw_circle draws a 1px outline and takes
/// no width argument - and the same call, at radius TOWER.range, is what the
/// placement circle already uses (obj_tower_edit/Draw_0).
///
/// Shown for the tower the POINTER IS OVER: the same _hov the cell highlight
/// above uses, so the ring, the cell and the level cannot name different
/// towers (LL-021).  NOT for a selection - asking about a tower is hovering
/// it.  One exception is kept: while the pointer is over the card's range
/// band the SELECTED tower is ringed, because the band exists to name a
/// tower's reach and would otherwise be a promise with nothing behind it.
var _ring = noone;
if(_hov != noone){
    _ring = _hov;
} else if(scr_isValidInstance(tower_selection)
          && variable_instance_exists(tower_selection, "data")
          && is_array(tower_selection.data)
          && array_length(tower_selection.data) > TOWER.range){
    var _m = points_to_gui(mouse_x,mouse_y,0);
    if(point_in_rectangle(_m[0],_m[1],
                          tower_card_range_rect[0],tower_card_range_rect[1],
                          tower_card_range_rect[2],tower_card_range_rect[3])){
        _ring = tower_selection;
    }
}

if(_ring != noone){
    var _range = _ring.data[TOWER.range];
    draw_set_colour(c_white);
    draw_set_blend_mode(bm_add);
    draw_set_alpha(tower_range_alpha);
    draw_circle(_ring.x, _ring.y, _range - 1, true);
    draw_circle(_ring.x, _ring.y, _range, true);
    draw_circle(_ring.x, _ring.y, _range + 1, true);
    draw_set_blend_mode(bm_normal);
    draw_set_alpha(1);
}

/// draw path before spawn

var _vx1 = __view_get( e__VW.XView, 0 )-8,
    _vy1 = __view_get( e__VW.YView, 0 )-8,
    _vx2 = _vx1 + __view_get( e__VW.WView, 0 )+16,
    _vy2 = _vy1 + __view_get( e__VW.HView, 0 )+16;
    
    
if(path_opacity > 0.1 && path_ready){
    var _size = path_get_length(path_show),
        _ds = 16/_size;
    if(path_get_length(path_show) > 8){
        for (var i=0; i<1-_ds; i+=_ds)
        {
            var _x1 = path_get_x(path_show,i),
                _y1 = path_get_y(path_show,i),
                _x2 = path_get_x(path_show,i+_ds),
                _y2 = path_get_y(path_show,i+_ds),
                _dr = point_direction(_x1,_y1,_x2,_y2);
            if(point_in_rectangle(_x1,_y1,_vx1,_vy1,_vx2,_vy2)){
                draw_sprite_ext(spr_path,path_frame,_x1,_y1,1,1,_dr,c_white,path_opacity);
            }
                
        };
        
    }
}

