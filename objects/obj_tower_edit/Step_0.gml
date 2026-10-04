/// @description  match player mouse position
x = ((mouse_x>>5)<<5)+16;
y = ((mouse_y>>5)<<5)+16;

blocked = position_meeting(x,y,obj_tower) || position_meeting(x,y,_spawn);

if(mouse_check_button_released(mb_left)){
    if(blocked){
        path_delete(path_test);
        instance_destroy();
        scr_playSound(snd_unable,false);
    } else {
        //--------------------------- check if clear
        /// reset grid
        path_clear_points(path_test);
        mp_grid_clear_all(LEVEL.placement_grid);
        mp_grid_add_instances(LEVEL.placement_grid, id, false);
        mp_grid_add_instances(LEVEL.placement_grid, obj_tower, false);
        mp_grid_add_instances(LEVEL.placement_grid, obj_wall, false);
        
        /// get path data
        var path_loc = array(obj_despawn.x,obj_despawn.y);
        var path_begin = array(obj_spawn.x,obj_spawn.y);
        var _check = mp_grid_path(LEVEL.placement_grid,path_test,path_begin[0],path_begin[1],path_loc[0],path_loc[1],true);
        if(!_check){
            scr_playSound(snd_unable,false);
            path_delete(path_test);
            instance_destroy();
            exit;
        }
        //--------------------------- place object
        add_item_value(STATINV.money,-price);
        ///
        var _dd = -60 - (y>>5);
        var _tObj = instance_create_depth(x,y,_dd,obj_tower);
        _tObj.name = name;
        _tObj.sprite_index = sprite_index;
        _tObj.data = data;
        _tObj.price = price;
        _tObj.tower_string = tower_string;
        _tObj.sprite_list = sprite_list;
        _tObj.image_blend = c_gray;
        path_delete(path_test);
        scr_playSound(snd_placement,false);
        instance_destroy();
    }
}

