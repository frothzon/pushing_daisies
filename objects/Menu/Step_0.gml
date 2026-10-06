/// @description  menu state machine (plain switch) + cursor

//--------------------------------------------------------------
// timing: a change requested earlier is applied here, so every state
// always gets exactly one frame with menu_state_time == 0
if(menu_state_next != -1){
    menu_state_prev = menu_state;
    menu_state       = menu_state_next;
    menu_state_next  = -1;
    menu_state_time  = 0;
    print("MENU  now ", scr_menu_state_name(menu_state));
    /// The entry request is one-shot.  Consume it, so a later return to
    /// the menu does not bounce straight back to the world map.
    if(variable_global_exists("menu_entry")) global.menu_entry = MENU_STATE.START;

    /// The title buttons belong to the START screen alone.  Hide them the
    /// moment a meta screen takes the input, or a click aimed at a stage
    /// node lands on Start / Options / Quit underneath it.  This is what
    /// scr_button_index_hide was always meant to do: the buttons' Draw
    /// event used to ignore `visible`, so hiding one never worked.
    switch(menu_state){
        case MENU_STATE.WORLD_MAP:
        case MENU_STATE.DEPLOY:
        case MENU_STATE.GARDEN:
            for_array(menu_button,  scr_button_index_hide);
            for_array(menu_options, scr_button_index_hide);
            break;
    }
    scr_menu_debug(id, "state entered");
} else {
    menu_state_time++;
}

//--------------------------------------------------------------
// states
switch(menu_state){

    //----------------------------------- title screen
    case MENU_STATE.START:
        /// load the buttons the first time the menu is entered
        if(menu_state_time == 0){
            if(!buttons_loaded){
                scr_setup_menuStates();
                buttons_loaded = true;
            }
        }
        if(menu_state_time == 1){
            for_array(menu_button,scr_button_index_enable);
            for_array(menu_options,scr_button_index_disable);
            scr_menu_debug(id, "after enable");

            /// disable continue - only if that button actually exists.
            /// menu_button[1] is a hole while the Continue button is
            /// commented out in scr_setup_menuStates.
            var _continue = menu_button[1];
            if(!file_exists(global.saveName) && _continue != undefined && _continue != noone && _continue != 0 && instance_exists(_continue)){
                with(_continue){
                    active = false;
                    scr_button_greyout();
                }
            }
        }
        break;

    //----------------------------------- start a new game
    case MENU_STATE.NEW_GAME:
        if(menu_state_time == 0){
            for_array(menu_button,scr_button_index_disable);
        }
        if(menu_state_time > room_speed*0.5){
            audio_stop_all();
            fadeout(game_room,c_black,1,0,0);
        }
        break;

    //----------------------------------- load a saved game
    case MENU_STATE.CONTINUE:
        if(menu_state_time == 0){
            for_array(menu_button,scr_button_index_disable);
        }
        if(menu_state_time > room_speed*0.5){
            fadeout(game_room,c_black,1,0,0);
        }
        break;

    //----------------------------------- options screen
    case MENU_STATE.OPTIONS:
        if(menu_state_time == 0){
            for_array(menu_button,scr_button_index_hide);
            for_array(menu_options,scr_button_index_enable);
        }
        break;

    //----------------------------------- leaving the options screen
    case MENU_STATE.RETURN:
        if(menu_state_time == 0){
            for_array(menu_options,scr_button_index_hide);
            scr_resetSoundVolume();
            scr_saveOptions();
        }
        if(menu_state_time > room_speed*0.5){
            scr_playMusic(snd_music_title,true);
            scr_menu_changeState(MENU_STATE.START);
        }
        break;

    //----------------------------------- quit
    case MENU_STATE.QUIT:
        if(menu_state_time == 0){
            for_array(menu_button,scr_button_index_disable);
        }
        if(menu_state_time > room_speed*0.5){
            audio_stop_all();
            game_end();
        }
        break;

    //----------------------------------- the world map (roadmap 1.1)
    case MENU_STATE.WORLD_MAP:
        if(menu_state_time == 0){
            print("MENU  world map  ->  region ", global.region,
                  " stage ", global.stage, " seeds ", seeds_get());
        }
        {
            var _wgeom = meta_worldmap_geom(),
                _wclick = mouse_check_button_pressed(mb_left);

            /// a stage node first: it is the biggest target on the screen
            if(_wclick){
                var _wnode = meta_worldmap_hit();
                if(_wnode >= 0){
                    var _rgn = 1 + (_wnode div 10),
                        _stg = 1 + (_wnode mod 10);
                    if(stage_unlocked(_rgn, _stg)){
                        global.region = _rgn;
                        global.stage  = _stg;
                        scr_playSound(snd_button, false);
                        print("MENU  chose stage ", _rgn, "-", _stg);
                        scr_menu_changeState(MENU_STATE.DEPLOY);
                    } else {
                        print("MENU  stage ", _rgn, "-", _stg, " is locked");
                    }
                } else if(meta_button_clicked(_wgeom.garden, true)){
                    scr_menu_changeState(MENU_STATE.GARDEN);
                } else if(meta_button_clicked(_wgeom.title, true)){
                    /// "Title" returns to the start menu, which is the state
                    /// that owns Start / Options / Quit
                    scr_menu_changeState(MENU_STATE.START);
                }
            }
        }
        break;

    //----------------------------------- the deploy screen (roadmap 1.2)
    case MENU_STATE.DEPLOY:
        if(menu_state_time == 0){
            /// Re-read what the player actually owns.  loadout_stored(),
            /// NOT loadout_current(): the editor must see the selection as
            /// it is, empty slots and all.  Padding it here is exactly what
            /// used to undo a removal the moment the screen reopened.
            global.loadout = loadout_stored();
            print("MENU  deploy  ->  region ", global.region,
                  " stage ", global.stage,
                  " ", difficulty_name(global.difficulty),
                  " loadout ", string(global.loadout));
        }
        {
            var _dgeom  = meta_deploy_geom(),
                _dclick = mouse_check_button_pressed(mb_left);

            if(_dclick){
                var _dm   = points_to_gui(mouse_x, mouse_y, 0),
                    _done = false;

                /// 1. difficulty
                for(var _di = 0; _di < array_length(_dgeom.diffs); _di++){
                    if(meta_in_rect(_dgeom.diffs[_di], _dm[0], _dm[1])){
                        global.difficulty = _di;
                        scr_playSound(snd_button, false);
                        print("MENU  difficulty -> ", difficulty_name(_di));
                        _done = true;
                        break;
                    }
                }

                /// 2. the tower wall: toggle a tower in / out of the loadout
                if(!_done){
                    var _wrects = meta_deploy_wall();
                    for(var _wi = 0; _wi < array_length(_wrects); _wi++){
                        if(meta_in_rect(_wrects[_wi], _dm[0], _dm[1])){
                            var _roster = tower_roster();
                            if(_wi < array_length(_roster)){
                                var _tname = _roster[_wi].name;
                                if(loadout_toggle(_tname)){
                                    scr_playSound(snd_button, false);
                                } else if(!loadout_unlocked(_tname)){
                                    print("MENU  '", _tname, "' is locked");
                                } else if(loadout_selected(_tname)){
                                    print("MENU  loadout is full (",
                                          loadout_size(), " towers)");
                                }
                            }
                            _done = true;
                            break;
                        }
                    }
                }

                /// 3. the slots: clicking a slotted tower takes it back out
                if(!_done){
                    var _srects = meta_deploy_slots(),
                        _sload  = loadout_stored();
                    for(var _si = 0; _si < array_length(_srects); _si++){
                        if(_si < array_length(_sload)
                           && meta_in_rect(_srects[_si], _dm[0], _dm[1])){
                            loadout_toggle(_sload[_si]);
                            scr_playSound(snd_button, false);
                            _done = true;
                            break;
                        }
                    }
                }

                /// 4. the two actions.  Deploy needs a FULL loadout, so
                ///    clearing a slot and walking away cannot start an
                ///    unwinnable run.  A greyed button still answers a
                ///    click - with a reason - so it is never silent.
                if(!_done){
                    if(loadout_ready()
                       && meta_button_clicked(_dgeom.deploy, true)){
                        loadout_set(loadout_stored());
                        scr_save_meta();
                        print("MENU  deploy!  region ", global.region,
                              " stage ", global.stage,
                              " ", difficulty_name(global.difficulty),
                              " with ", string(loadout_stored()));
                        audio_stop_all();
                        fadeout(global.startRoom, c_black, 1, 0, 0);
                        _done = true;
                    } else if(!loadout_ready()
                       && meta_button_clicked(_dgeom.deploy, true)){
                        print("MENU  deploy blocked - ",
                              array_length(loadout_stored()), "/",
                              loadout_size(), " slots filled ",
                              string(loadout_stored()));
                        _done = true;
                    }
                }
                if(!_done && meta_button_clicked(_dgeom.back, true)){
                    scr_menu_changeState(MENU_STATE.WORLD_MAP);
                }
            }
        }
        break;

    //----------------------------------- the garden book (roadmap 1.7)
    case MENU_STATE.GARDEN:
        if(menu_state_time == 0){
            print("MENU  garden book  ->  seeds ", seeds_get(),
                  " clovers ", clovers_get(),
                  " towers ", tower_owned_count(), "/", array_length(tower_roster()));
        }
        {
            var _ggeom  = meta_garden_geom(),
                _gclick = mouse_check_button_pressed(mb_left);

            if(_gclick){
                var _gnode = meta_garden_hit();
                if(_gnode >= 0){
                    var _nodes = clover_nodes();
                    if(_gnode < array_length(_nodes)){
                        var _nid = _nodes[_gnode].id;
                        if(clover_buy(_nid)){
                            scr_playSound(snd_button, false);
                            scr_save_meta();
                            print("MENU  bought ", _nid,
                                  " rank ", clover_rank(_nid),
                                  " clovers left ", clovers_get());
                        } else {
                            print("MENU  cannot buy ", _nid,
                                  " (next rank ", clover_cost(_nid),
                                  ", have ", clovers_get(), ")");
                        }
                    }
                } else {
                    var _shop = meta_garden_shop_hit(),
                        _all  = tower_roster();
                    if(_shop >= 0 && _shop < array_length(_all)){
                        var _sname = _all[_shop].name;
                        if(tower_unlock(_sname)){
                            scr_playSound(snd_button, false);
                            scr_save_meta();
                            print("MENU  unlocked '", _sname,
                                  "' seeds left ", seeds_get());
                        } else if(!tower_owned(_sname)){
                            print("MENU  cannot unlock '", _sname,
                                  "' (cost ", tower_unlock_cost(_sname),
                                  ", have ", seeds_get(), ")");
                        }
                    } else if(meta_button_clicked(_ggeom.back, true)){
                        scr_menu_changeState(MENU_STATE.WORLD_MAP);
                    }
                }
            }
        }
        break;

    default:
        print("MENU  unknown state ", menu_state);
        break;
}

//--------------------------------------------------------------
// custom cursor
cursor_sprite = ico_cursor;
var _hit = position_meeting(mouse_x,mouse_y,_button);
if(_hit){
    cursor_sprite = ico_cursor_interact;
}
