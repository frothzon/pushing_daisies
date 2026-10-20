/// @description  setup systems


//---------------------- Create Input Object
if(instance_number(Input) == 0){
    instance_create_depth(0,0,0,Input);
}
//---------------------- Setup Systems
setup_partsys();        /// particles
scr_setupCollider();    /// collisions
scr_iniDebree();        /// debree collection
scr_SetupBagSystem();   /// inventory system
scr_iniTooltip(1.5);       /// setup tooltip

/// camera box
cam_box = [0,0,0,0];

/// tooltip location
tool_pos = [16,display_get_gui_height()-32];

/// load bag data

scr_LoadBagSystem(global.saveName);

/// The main game state machine is NOT created here any more.
///
/// It used to be, and that was the whole "the second level does not
/// load" bug: Control is PERSISTENT and is the first instance in
/// rm_test's creation order, so this Create event ran once per launch -
/// while _mainControl is non-persistent and dies on Room End.  The
/// second visit to the room therefore had no main controller, so the
/// terrain was never generated and no waves ever started.
///
/// scr_level_boot() creates it from rm_test ROOM CREATION CODE, which
/// runs on every entry to the room.  Control is non-persistent now as
/// well, so this Create - and every system below it - runs again for
/// every stage instead of once per launch.
scr_meta_log("LEVEL", "systems  collider/partsys/bag/debree/tooltip");

