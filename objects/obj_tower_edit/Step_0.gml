/// @description  match player mouse position
x = ((mouse_x>>5)<<5)+16;
y = ((mouse_y>>5)<<5)+16;

/// Which cell is this ghost standing in?  Worked out exactly the way
/// obj_tower/Create_0 and scr_grid_block_instances work it out - the grid
/// origin is (-cell_w,-cell_h), so a point's cell index is
/// (x + cell_w) div cell_w.  ONE source for "which cell is this", which
/// is the point of LL-027.
var _col = (x + LEVEL.cell_w) div LEVEL.cell_w,
    _row = (y + LEVEL.cell_h) div LEVEL.cell_h;

/// Ask the GRID, never the towers' collision masks.  A tower carries the
/// 32x64 spr_tower_click_region mask - its own cell PLUS the one above it
/// (LL-033) - so position_meeting(x,y,obj_tower) reported the cell ABOVE a
/// tower as taken, while obj_tower/Create_0 blocks exactly ONE cell in
/// this same grid and two towers are perfectly allowed to stand one above
/// the other.  Reading the grid the writer writes means the two cannot
/// disagree (LL-021), and it is the grid the monsters walk on - so "you
/// cannot build where they cannot walk" is now true by construction
/// rather than by the two tests happening to agree.
///
/// mp_grid_get_cell() answers -1 for a cell that is occupied AND for one
/// outside the grid, so a ghost pushed off the edge reads as blocked too.
///
/// The spawn stays a mask test: it is not in the grid at all.  _spawn is
/// also the parent of obj_wall, whose 32x32 art covers exactly one cell,
/// which makes this a free backstop for the part of the deploy countdown
/// that runs before scr_resetDrawPath has put the walls into the grid.
blocked_reason = "";
if(mp_grid_get_cell(LEVEL.path_grid, _col, _row) != 0){
    blocked_reason = "that cell already holds something";
} else if(position_meeting(x, y, _spawn)){
    blocked_reason = "that is the spawn (or a wall)";
}
blocked = (blocked_reason != "");

if(mouse_check_button_released(mb_left)){
    if(blocked){
        /// Say WHY.  This used to refuse in silence - a click, a thud and
        /// a vanished ghost - which leaves nothing in the log to read,
        /// and the two reasons are different bugs if either is ever wrong
        /// (LL-011).  The route checks further down log in this same voice.
        scr_meta_log("PATH", "placement refused: ", blocked_reason);
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
        /// block EXACTLY the ONE cell the tower will stand in - the same
        /// cell obj_tower/Create_0 blocks, so the check reasons about the
        /// real footprint.  The grid origin is (-cell_w,-cell_h), so a
        /// point's cell index is (x + cell_w) div cell_w (LL-027).
        mp_grid_add_cell(LEVEL.placement_grid,
                         (x + LEVEL.cell_w) div LEVEL.cell_w,
                         (y + LEVEL.cell_h) div LEVEL.cell_h);
        /// one cell per existing tower and per wall - the same footprint
        /// the live grid gives them (scr_grid_block_instances, LL-027)
        scr_grid_block_instances(LEVEL.placement_grid, obj_tower);
        scr_grid_block_instances(LEVEL.placement_grid, obj_wall);
        /// Keep scenery footprints unavailable to towers and path probes.
        with(LEVEL){
            biome_props_block_grid(placement_grid,grid_w,grid_h);
        }

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
        badge_record_purchase(LEVEL,price,name);
        ///
        var _dd = scr_depth_y(y);   /// the one depth rule (LL-059)
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

