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
        case MENU_STATE.RESULTS:
            for_array(menu_button,  scr_button_index_hide);
            for_array(menu_options, scr_button_index_hide);
            break;
    }
    scr_menu_debug(id, "state entered");
} else {
    menu_state_time++;
}

//--------------------------------------------------------------
// the backdrop: the four meta screens sit over a blurred room, the title and
// Options keep it sharp.  There is nothing to do here - the blur is a DRAW, so
// objects/Menu/Draw_64.gml calls menu_blur_draw() first, and it reads the state
// itself (scr_menu_blur, LL-076).  Switching anything from the Step is what the
// room layer version did, and it could not work once the layer stopped being an
// effect layer.

//--------------------------------------------------------------
// the canvas moved: re-place everything this screen takes from the tree.
// global.ui.gen is bumped by ui_screen_refresh() (a resize, or a fullscreen
// toggle), and comparing it here is what makes that ONE frame's work instead
// of a per-frame recompute.  -1 means "never placed", so the first frame -
// before the buttons exist - is skipped rather than errors.
if(!variable_instance_exists(id, "ui_gen_seen")) ui_gen_seen = -1;
var _gen = variable_global_exists("ui") ? global.ui.gen : 0;
if(_gen != ui_gen_seen){
    ui_gen_seen = _gen;
    if(buttons_loaded
    && (menu_state == MENU_STATE.START || menu_state == MENU_STATE.OPTIONS)){
        scr_menu_place_buttons();
    }
}

//--------------------------------------------------------------

var _back_id = layer_background_get_id("Background");
var _back_img = (menu_state == MENU_STATE.START || menu_state == MENU_STATE.OPTIONS) ? spr_title_background_sidewalk : spr_title_background_sidewalk_blurry;
layer_background_sprite(_back_id, _back_img);
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

            /// disable continue when there is nothing to continue FROM.  The
            /// button exists now, but the guard stays: a hole in the array
            /// reads as 0, which is OBJECT INDEX 0 (_button).
            /// The question is the META save, not test.data - nothing has
            /// written the legacy arcade file since the meta layer landed.
            var _continue = menu_button[1];
            if(!scr_run_started() && _continue != undefined && _continue != noone && _continue != 0 && instance_exists(_continue)){
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
            /// THE RUN CURSOR is the whole point of Continue: it is where
            /// the player actually was, not stage 1-1 (schema v2).  A save
            /// written before v2 has no cursor and run_get() answers with
            /// the opening stage, which is the right thing to do with it.
            var _run = run_get();
            global.region     = _run.region;
            global.stage      = _run.stage;
            global.difficulty = _run.difficulty;
            global.loadout    = loadout_stored();
            print("MENU  continue  ->  region ", global.region,
                  " stage ", global.stage, " ",
                  difficulty_name(global.difficulty),
                  " loadout ", string(global.loadout));
        }
        if(menu_state_time > room_speed*0.5){
            audio_stop_all();
            fadeout(game_room,c_black,1,0,0);
        }
        break;

    //----------------------------------- options screen
    case MENU_STATE.OPTIONS:

        if(menu_state_time == 0){
            for_array(menu_button,scr_button_index_hide);
            for_array(menu_options,scr_button_index_enable);
        }
        /// The sliders read the pointer HERE, not in the Draw event: a drag
        /// is modal and has to survive the pointer leaving the track, or
        /// reaching 0% / 100% takes a second pass (LL-051).
        scr_sliders_step();
        break;

    //----------------------------------- leaving the options screen
    case MENU_STATE.RETURN:
        
        if(menu_state_time == 0){
            for_array(menu_options,scr_button_index_hide);
            scr_resetSoundVolume();
            scr_saveOptions();
        }
        if(menu_state_time > room_speed*0.5){
            scr_music_start_menu();
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
            /// the world map IS the menu, so it keeps the menu theme.
            /// A stage clear stops the region theme and fades straight
            /// here, so without this the map would be the one silent
            /// screen in the game (roadmap 5.8).
            scr_music_start_menu();
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
                    /// a node with no authored level is inert, whatever the
                    /// unlock rules say - the map must not create a stage
                    if(!level_exists(_rgn, _stg)){
                        print("MENU  stage ", _rgn, "-", _stg, " has no level yet");
                    } else if(stage_unlocked(_rgn, _stg)){
                        global.region = _rgn;
                        global.stage  = _stg;
                        global.endless_setup = false;
                        scr_playSound(snd_button, false);
                        print("MENU  chose stage ", _rgn, "-", _stg);
                        scr_menu_changeState(MENU_STATE.DEPLOY);
                    } else {
                        print("MENU  stage ", _rgn, "-", _stg, " is locked");
                    }
                } else if(meta_button_clicked(_wgeom.garden, true)){
                    scr_menu_changeState(MENU_STATE.GARDEN);
                } else if(meta_button_clicked(_wgeom.endless, true)){
                    if(endless_is_unlocked()){
                        global.endless_setup = true;
                        scr_menu_changeState(MENU_STATE.DEPLOY);
                    } else {
                        print("MENU  Endless locked - clear Region 1 Stage 10 first");
                    }
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
                        if(global.endless_setup){
                            endless_begin();
                            print("MENU  deploy! Endless ",difficulty_name(global.difficulty),
                                  " with ",string(loadout_stored()));
                        } else {
                            /// remember WHERE, so a relaunch can resume here
                            /// and Retry comes back to this stage (schema v2)
                            run_set(global.region, global.stage, global.difficulty);
                            scr_save_meta();
                            print("MENU  deploy!  region ", global.region,
                                  " stage ", global.stage,
                                  " ", difficulty_name(global.difficulty),
                                  " with ", string(loadout_stored()));
                        }
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
                    global.endless_setup = false;
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
            var _ggeom = meta_garden_geom(),
                _gclick = mouse_check_button_pressed(mb_left),
                _mode = garden_view_mode(),
                _candy_view = (_mode == 2),
                _ghov = _candy_view ? -1 : meta_garden_shop_hit();
            if(_ghov >= 0) garden_focus = _ghov;
            var _garden_tab = -1;
            for(var _tab_check=0; _tab_check<array_length(_ggeom.tabs); _tab_check++){
                if(_garden_tab < 0 && meta_button_clicked(_ggeom.tabs[_tab_check],true)){
                    _garden_tab = _tab_check;
                }
            }
            var _branch_tab = -1;
            if(_mode == 0){
                for(var _branch_check=0; _branch_check<array_length(_ggeom.branch_tabs); _branch_check++){
                    if(_branch_tab < 0 && meta_button_clicked(_ggeom.branch_tabs[_branch_check],true)){
                        _branch_tab = _branch_check;
                    }
                }
            }
            var _focus_name = "";
            if(variable_instance_exists(id,"garden_focus") && is_real(garden_focus)){
                var _focus_roster = tower_roster();
                if(garden_focus >= 0 && garden_focus < array_length(_focus_roster)){
                    _focus_name = _focus_roster[garden_focus].name;
                }
            }

            if(_gclick){
                if(_garden_tab >= 0){
                    global.garden_view_mode = _garden_tab;
                    global.garden_blood_view = (_garden_tab == 1);
                    var _view_name = _garden_tab == 0 ? "Clover Tree"
                                   : (_garden_tab == 1 ? "Blood Alchemy"
                                     : (_garden_tab == 2 ? "Candy Shop" : "Garden Mastery"));
                    print("MENU  garden tab -> ",_view_name);
                } else if(_branch_tab >= 0){
                    global.garden_clover_branch = _branch_tab;
                    global.garden_clover_page = 0;
                    print("MENU  clover branch -> ",clover_branch_name());
                } else if(_candy_view){
                    if(meta_button_clicked(_ggeom.page,true)){
                        global.garden_candy_page = 1 - garden_candy_page_get();
                        var _page_nodes = candy_recipe_table();
                        global.garden_candy_focus = _page_nodes[global.garden_candy_page*5].id;
                        print("MENU  candy page -> ",garden_candy_page_get()+1,"/2");
                    } else {
                        var _gnode = meta_garden_hit(),
                            _nodes = garden_visible_nodes(),
                            _offset = garden_candy_page_get()*5;
                        if(_gnode >= 0 && _gnode < 5 && _offset+_gnode < array_length(_nodes)){
                            global.garden_candy_focus = _nodes[_offset+_gnode].id;
                            print("MENU  candy selected ",global.garden_candy_focus);
                        } else {
                            var _action = meta_garden_candy_action_hit(_ggeom),
                                _recipe = meta_garden_candy_selected(garden_candy_page_get()),
                                _success = false;
                            if(_action < 0 && meta_button_clicked(_ggeom.back,true)){
                                scr_menu_changeState(MENU_STATE.WORLD_MAP);
                            } else if(!is_struct(_recipe)){
                                print("MENU  candy action refused: catalog unavailable");
                            } else if(_action == 0){
                                _success = candy_recipe_unlocked(_recipe.id)
                                           ? candy_level_buy(_recipe.id)
                                           : candy_recipe_buy(_recipe.id);
                                if(_success) scr_save_meta();
                                else print("MENU  candy purchase refused ",_recipe.id,
                                           " shards=",shards_get()," gate=",candy_recipe_gate_reason(_recipe.id));
                                if(_success) scr_playSound(snd_button,false);
                            } else if(_action == 1){
                                _success = candy_stock_buy(_recipe.id,1);
                                if(_success) scr_save_meta();
                                else print("MENU  candy stock refused ",_recipe.id," shards=",shards_get());
                                if(_success) scr_playSound(snd_button,false);
                            } else if(_action == 2){
                                _success = candy_duration_buy();
                                if(_success) scr_save_meta();
                                else print("MENU  candy duration refused cost=",candy_duration_cost(),
                                           " clovers=",clovers_get());
                                if(_success) scr_playSound(snd_button,false);
                            }
                        }
                    }
                } else if(_mode == 0 && clover_branch_respec_fee(clover_branch_key()) >= 0
                          && meta_button_clicked(_ggeom.branch_respec,true)){
                    var _branch=clover_branch_key(),
                        _spent=clover_branch_invested(_branch),
                        _fee=clover_branch_respec_fee(_branch);
                    if(clover_branch_respec(_branch)){
                        var _save_ok=scr_save_meta();
                        print("MENU  respec clover branch ",_branch," spent=",_spent,
                              " fee=",_fee," refund=",_spent-_fee," saved=",_save_ok);
                    }
                } else if((_mode == 0 || _mode == 1)
                          && tower_spec_respec_cost(_focus_name) > 0
                          && clovers_get() >= tower_spec_respec_cost(_focus_name)
                          && meta_button_clicked(_ggeom.spec_respec,true)){
                    var _spec_cost=tower_spec_respec_cost(_focus_name);
                    if(tower_spec_respec(_focus_name)){
                        var _spec_saved=scr_save_meta();
                        print("MENU  respec specialization ",_focus_name,
                              " cost=",_spec_cost," saved=",_spec_saved);
                    }
                } else if(_mode == 0 && meta_button_clicked(_ggeom.clover_page,true)){
                    clover_page_cycle();
                    print("MENU  clover page -> ",clover_page_get()+1,"/2");
                } else {
                    var _gnode = meta_garden_hit(),
                        _nodes = garden_visible_nodes(),
                        _offset = (_mode == 0) ? clover_page_get()*5 : 0;
                    if(_gnode >= 0 && _gnode < 5 && _offset+_gnode < array_length(_nodes)){
                        var _nid = _nodes[_offset+_gnode].id,
                            _blood_view = (_mode == 1),
                            _mastery_view = (_mode == 3),
                            _bought = _blood_view ? blood_node_buy(_nid)
                                      : (_mastery_view ? clover_master_node_buy(_nid) : clover_buy(_nid));
                        if(_bought){
                            scr_playSound(snd_button,false);
                            scr_save_meta();
                            if(_blood_view){
                                print("MENU  unlocked blood node ",_nid,
                                      " shards left ",shards_get());
                            } else if(_mastery_view){
                                print("MENU  bought ",_nid," cap ",tower_cap(),
                                      " floor ",tower_floor()," clovers left ",clovers_get());
                            } else {
                                print("MENU  bought ",_nid,
                                      " rank ",clover_rank(_nid),
                                      " clovers left ",clovers_get());
                            }
                        } else if(_blood_view){
                            print("MENU  cannot buy blood node ",_nid,
                                  " (next cost ",blood_node_cost(_nid),
                                  ", have ",shards_get()," shards; previous tier required)");
                        } else if(_mastery_view){
                            var _mn=clover_master_node_find(_nid);
                            print("MENU  cannot buy ",_nid," cost ",clover_master_node_cost(_nid),
                                  " clovers ",clovers_get(),
                                  " region_gate=",is_struct(_mn) ? _mn.region : 0);
                        } else {
                            print("MENU  cannot buy ",_nid,
                                  " (next rank ",clover_cost(_nid),
                                  ", have ",clovers_get(),")");
                        }
                    } else {
                        var _all = tower_roster();
                        if(_ghov >= 0 && _ghov < array_length(_all)){
                            var _sname = _all[_ghov].name;
                            if(tower_unlock(_sname)){
                                scr_playSound(snd_button,false);
                                scr_save_meta();
                                print("MENU  unlocked '",_sname,"' seeds left ",seeds_get());
                            } else if(!tower_owned(_sname)){
                                print("MENU  cannot unlock '",_sname,"' (cost ",tower_unlock_cost(_sname),
                                      ", have ",seeds_get(),")");
                            }
                        } else if(meta_button_clicked(_ggeom.back,true)){
                            scr_menu_changeState(MENU_STATE.WORLD_MAP);
                        }
                    }
                }
            }
        }
        break;

    //----------------------------------- the results screen (goal.md 27.2)
    case MENU_STATE.RESULTS:
        if(menu_state_time == 0){
            results_leaving = false;
            /// A result is ALWAYS here: both stage exits write it before
            /// they ask for this screen.  If it is missing, the entry
            /// request is stale (a relaunch carrying an old menu_entry),
            /// and the map is the only honest place to send the player.
            if(!variable_global_exists("level_result") || !is_struct(global.level_result)){
                print("MENU  RESULTS with no level_result - going to the map");
                scr_menu_changeState(MENU_STATE.WORLD_MAP);
            } else {
                var _lr = global.level_result;
                if(_lr.outcome == "ENDLESS"){
                    print("MENU  results Endless wave ",_lr.waves," score ",_lr.score,
                          " boxes ",_lr.boxes," best ",_lr.best_wave);
                } else {
                    print("MENU  results ", _lr.outcome, " ", _lr.region, "-", _lr.stage,
                          " lives ", _lr.lives, " leaked ", _lr.leaked,
                          " seeds +", _lr.seeds, " clovers +", _lr.clovers);
                }
                /// the results screen is part of the menu, so it keeps the
                /// menu theme; a stage exit stopped the region theme (5.8)
                scr_music_start_menu();
            }
        }
        /// once an action is taken the screen is done.  Without this, a
        /// second click during the fade would start a SECOND fade and the
        /// player would land wherever the last one pointed.
        if(results_leaving) break;
        if(menu_state_time > 5 && is_struct(global.level_result)){
            var _rgeom = meta_results_geom(),
                _res   = global.level_result,
                _next  = (_res.outcome == "CLEAR")
                         ? meta_results_next(_res.region, _res.stage) : undefined;

            if(meta_button_clicked(_rgeom.retry, true)){
                /// Retry: the SAME stage, difficulty and loadout.  The menu
                /// room is not the stage room, so this is an ordinary fade
                /// to a DIFFERENT room - the restart argument is for a retry
                /// that stays put, and is not needed here.
                results_leaving   = true;
                global.difficulty = _res.difficulty;
                loadout_set(loadout_stored());
                if(_res.outcome == "ENDLESS"){
                    endless_begin();
                    print("MENU  retry Endless");
                } else {
                    global.region = _res.region;
                    global.stage = _res.stage;
                    run_set(_res.region, _res.stage, _res.difficulty);
                    scr_save_meta();
                    print("MENU  retry ", _res.region, "-", _res.stage);
                }
                audio_stop_all();
                fadeout(global.startRoom, c_black, 1, 0, 0);
            } else if(meta_button_clicked(_rgeom.next, !is_undefined(_next))){
                results_leaving = true;
                global.region = _next.region;
                global.stage  = _next.stage;
                print("MENU  next stage ", global.region, "-", global.stage);
                scr_menu_changeState(MENU_STATE.DEPLOY);
            } else if(meta_button_clicked(_rgeom.map, true)){
                results_leaving = true;
                global.endless_active = false;
                global.endless_setup = false;
                scr_menu_changeState(MENU_STATE.WORLD_MAP);
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
