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
cam_box = array(0,0,0,0);

/// tooltip location
tool_pos = array(16,display_get_gui_height()-32);

/// load bag data

scr_LoadBagSystem(global.saveName);

/// Create Main Game State Machine

// pause controller
instance_create(0,0,_mainControl);

