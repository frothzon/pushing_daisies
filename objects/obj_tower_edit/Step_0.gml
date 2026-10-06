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
        /// Rebuild the placement grid as the world would be AFTER this tower
        /// exists, then ask three questions in order of cost.
        /// (roadmap 4.4.1: the old check asked only about the SPAWN, which is
        /// how a tower could leave the spawn connected and still pocket a
        /// monster that was already on the map.)
        path_clear_points(path_test);
        mp_grid_clear_all(LEVEL.placement_grid);
        mp_grid_add_instances(LEVEL.placement_grid, id, false);
        mp_grid_add_instances(LEVEL.placement_grid, obj_tower, false);
        mp_grid_add_instances(LEVEL.placement_grid, obj_wall, false);

        var _to_x = obj_despawn.x,
            _to_y = obj_despawn.y,
            _reject = "";

        /// 1. a monster standing in this cell would be sealed in by the very
        ///    tower placed on it - the cheapest test, and the one the old code
        ///    had no equivalent of at all
        if(scr_path_cell_blocked_by_monster(x,y,24)){
            _reject = "a monster is standing in this cell";
        }

        /// 2. does the route from the spawn still exist at all?
        if(_reject == "" && !scr_path_try(LEVEL.placement_grid,obj_spawn.x,obj_spawn.y,_to_x,_to_y,path_test)){
            _reject = "that would seal the route from the spawn";
        }

        /// 3. can EVERY monster already on the map still reach the despawn
        ///    from where it stands?  This is the check that makes a pocket
        ///    impossible by construction.
        if(_reject == "" && !scr_path_all_monsters_ok(LEVEL.placement_grid,path_test,_to_x,_to_y)){
            _reject = "that would trap a monster already on the map";
        }

        if(_reject != ""){
            scr_meta_log("PATH", "placement refused: ", _reject);
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
        /// the ladder is measured against the BASE and a rung's price is a
        /// multiple of the BASE price, so both travel with the tower
        /// (tower_levels.gml, economy.md 4.4)
        _tObj.base_data  = base_data;
        _tObj.base_price = base_price;
        _tObj.invested   = invested;
        _tObj.tower_string = tower_string;
        _tObj.sprite_list = sprite_list;
        _tObj.image_blend = c_gray;
        path_delete(path_test);
        scr_playSound(snd_placement,false);
        instance_destroy();
    }
}

