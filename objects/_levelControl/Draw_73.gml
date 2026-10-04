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

/// draw tower range

if(scr_isValidInstance(tower_selection)){
    var _range = tower_selection.data[TOWER.range],
        _x1 = tower_selection.x - _range,
        _y1 = tower_selection.y - _range;
    draw_sprite_stretched(spr_towerRange,0,_x1,_y1,_range<<1,_range<<1);
    /// draw text
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_size20);
    draw_text_outline(_x1+_range,_y1+_range,"Tower Range",c_yellow,c_black,2);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    
    /// draw stats
    with(tower_selection){
        scr_drawTowerStats(c_lime);
    }
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

