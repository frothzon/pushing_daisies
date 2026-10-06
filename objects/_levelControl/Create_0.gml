/// @description  draw grid opacity

/// placement grid
grid_opacity = 0;

/// tower list opacity
list_opacity = 1;

/// Grab Perlin Map from 
ground_w = room_width>>5;
ground_h = room_height>>5;
ground_map = _mainControl.ground_map;





/// setup spawns

scr_setupSpawning();

/// setup path finding grid
globalvar LEVEL;
LEVEL = id;


//------------- setup cell sizes and grid sizes
cell_w = 32;
cell_h = 32;
grid_w = room_width div cell_w;
grid_h = room_height div cell_h;

//-------------- create grids
path_grid = mp_grid_create(-cell_w,-cell_h,grid_w+2,grid_h+2,cell_w,cell_h);
placement_grid = mp_grid_create(-cell_w,-cell_h,grid_w+2,grid_h+2,cell_w,cell_h);
mp_grid_clear_all(path_grid);
mp_grid_clear_all(placement_grid);

/// setup static inventory
scr_setup_statinv();


/// set up score system
set_item_value(points,0);

/// set starting money.  economy.md 4.1 raises the base from 15 to 25 (a
/// rung costs less than a doubling now), and the difficulty column scales
/// it - Brutal starts with a quarter more.
set_item_value(money, round(25 * difficulty_start_money_mult()));

/// set starting life
set_item_value(life,20);

/// set starting wave
set_item_value(waves,1);

/// STATINV

/// setup tower editor

/// list of towers - the four the player brought this run
///
/// This used to be a literal array of the four towers that existed, which
/// made "which towers exist" and "which towers are in this run" the same
/// question.  It is now built from the loadout, so the shop can only ever
/// offer the towers the player chose, and a tower they have not unlocked
/// cannot appear at all - which is what the four-slot rule is for
/// (goal.md 3.1, roadmap 1.3).  The stats live in tower_roster() now.
tower_array = [];
var _load       = loadout_current(),
    _dmg_bonus  = clover_damage_bonus(),
    _rate_bonus = clover_firerate_bonus(),
    _floor      = tower_floor(),
    _armed      = 0;

for(var _ti = 0; _ti < array_length(_load); _ti++){
    var _entry = tower_entry_find(_load[_ti]);
    if(is_undefined(_entry)) continue;

    /// ONE resolver folds the tower's own data, the garden's permanent
    /// bonuses and the level ladder together in a fixed order
    /// (economy.md 4.3, tower_levels.gml).  A tower ARRIVES at the
    /// garden's floor, free; the four rungs above it are what money buys
    /// (goal.md 4).  The BASE data rides along on the entry as well,
    /// because a rung is measured against the base and an upgrade has to
    /// be able to re-resolve exactly the way a placement did.
    var _data = tower_data_at_level(_entry.data, _floor, _dmg_bonus, _rate_bonus);

    tower_array[_armed] = array(_entry.sprites, _entry.name, _entry.price,
                                _data, _entry.data);
    _armed++;
}
scr_meta_log("LOADOUT", "armed with ", _armed, " towers ", string(_load),
             " | clover damage +", _dmg_bonus*100, "%",
             " fire rate +", _rate_bonus*100, "%",
             " | floor ", _floor, " cap ", tower_cap());

/// ---- badge tracking (roadmap 1.8).  Untouched reads the life left at
/// the end, but Exterminator needs its own counters: "no life lost" and
/// "nothing reached the exit, and no straggler had to be force-cleared"
/// are different questions, and a stage that needed the safety valve in
/// scr_level_wait() should not earn the exterminator medal.
level_leaked = 0;
level_forced = false;

/// calculate position to draw towers
var _x = 16,
    _y = display_get_gui_height()-80;
    
//---------------------- builder variables
tower_draw = create_display_grid(_x,_y,64,64,4,1);  /// grid to display towers
tower_script = scr_drawBuilder;                     /// script to draw index
tower_index = -1;                                   /// currently selected tower
tower_hover = -1;                                   /// tower hovered over
tower_count = array_length(tower_array);         /// number of towers to draw
tower_box_sprite = spr_tower_box;                   /// sprite of box
tower_pos_free = false;
tower_price = 0;                                    /// save tower price on swap
tower_point = array(
    ((mouse_x >> 5) << 5),
    ((mouse_y >> 5) << 5)
);

/// setup tower modifier

tower_selection = noone;
tower_menu_selection = -1;
tower_menu_hover = -1;

/// ---- the tower card (roadmap 4.4.3) ----------------------------------
/// ONE fixed card, docked bottom-left, never under the mouse.  It replaced a
/// 256x256 panel centred on the screen (which competed with the range circle
/// for attention) plus two buttons floating in their own grid over the same
/// area.  Because the loadout UI in Phase 1 is a fixed panel too, building it
/// this way now means reusing the layout rather than rewriting it.
tower_card_w = 320;
tower_card_h = 148;
tower_card_x = 16;
tower_card_y = display_get_gui_height() - tower_card_h - 16;

/// the two buttons live INSIDE the card, so nothing floats over the world
tower_dgrid = create_display_grid(tower_card_x+10, tower_card_y+tower_card_h-48, 150, 38, 2, 1);

/// kept for the float-text popups that report a purchase
tower_display = array(tower_card_x + tower_card_w*0.5, tower_card_y + tower_card_h*0.5);

/// the band of the card that represents "range".  The range circle is shown
/// while the pointer is over it, so the number and the shape are explicitly
/// linked rather than merely adjacent.
tower_card_range_rect = array(tower_card_x, tower_card_y+34, tower_card_x+tower_card_w, tower_card_y+96);

/// the range circle is deliberately subordinate to the card
tower_range_alpha = 0.15;

//---------------- setup buttons
tower_price_save = array(
    0,
    0
);
tower_text = array("","");
tower_price_check = array(false,false);
tower_timer = 0;
/// the CAP comes from the garden, not a constant: a master node raises
/// the cap and the arrival floor together (goal.md 4/13, tower_levels.gml)
tower_max_level = tower_cap();

/// drawing a path 

path_show = path_add();
path_ready = false;
path_opacity = 0;
path_frame = 0;

/// setup mouse lighting

mouse_light = instance_create(0,0,_light);
mouse_light.image_blend = c_ltgray;
with(mouse_light){
    scr_scale_sprite(64,64);
}

/// setup the level flow (roadmap 0.4).  The Menu is the reference for
/// this shape: an enum, a pending change, and a timer.  The old
/// scr_setupState() held the state as a *function reference* and used
/// the number -1 for "none" - the LL-004 trap - and two numeric
/// sentinels cannot express a stage that has to deploy, fight, clear
/// and reward.
level_state      = LEVEL_STATE.NONE;
level_state_next = LEVEL_STATE.START;
level_state_time = 0;
level_cleared    = false;
wait_stuck       = 0;
is_boss_wave     = false;

show_start = false;
show_position = array(
    display_get_gui_width()*0.5,
    32
);
show_text = "Ready...";

