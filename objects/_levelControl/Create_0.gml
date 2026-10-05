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

/// set starting money (15 start)
set_item_value(money,15);

/// set starting life
set_item_value(life,20);

/// set starting wave
set_item_value(waves,1);

/// STATINV

/// setup tower editor

/// list of towers
tower_array = array(
    /// 0 sprite, 1 name, 2 price, 3 data, 4 object
    array(array(spr_t1_idle,spr_t1_attack,spr_t1_return),"Daisy Pusher",5,scr_towerData(100,4,3,_eff_puff,1)), /// 240 d/$
    array(array(spr_t2_idle,spr_t2_attack,spr_t2_return),"Burning Ivy",15,scr_towerData(80,40,2,_eff_acid,1)), /// 426 d/$
    array(array(spr_t4_idle,spr_t4_attack,spr_t4_return),"Slender Mandrake",45,scr_towerData(125,125,1,_eff_spikes,3)), /// 1041 d/$
    array(array(spr_t3_idle,spr_t3_attack,spr_t3_return),"Pina Collider",100,scr_towerData(75,200,1,_eff_xplod,10))  /// 1500 d/$ -- AoE
);

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
tower_max_level = 5;

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

