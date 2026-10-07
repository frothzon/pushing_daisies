action_inherited();
/// setup state
sprite_array = array(spr_mon,spr_mon);
scr_setupState();

/// generate path
/// mp_collider

myPath = path_add();

/// a SCRATCH path, used to TEST a route before committing it to
/// myPath: an attempt that might fail must never destroy the route the
/// monster is already walking, so every re-path goes through
/// scr_path_replace() and leaves this one alone (LL-025).
path_probe = path_add();

//--------------------- get randomized spawn location
var _count = instance_number(obj_spawn),
    _rand = irandom(_count - 1);

spawn_object = instance_find(obj_spawn,_rand);
start_pos = array(spawn_object.x,spawn_object.y);

//---------------------------------------------------//
path_loc = array(obj_despawn.x,obj_despawn.y);
x = spawn_object.x;
y = spawn_object.y;
pos_save = array(x,y);

/// path_free starts true, but scr_zombie_path now OVERWRITES it from the
/// real mp_grid_path result - the two must never disagree (roadmap
/// 4.4.1, defect 4)
path_free = true;
path_retry = 0;      /// failed re-path attempts since the last success
path_escape = false; /// true once we stop politely waiting for a route
data = scr_makeMonster(0,0,0,0,0,0);

/// show damage taken
damage_timer = irandom(3)*game_get_speed(gamespeed_fps);
damage_amount = 0;

/// climb
z_climb = 0;
rot_angle = 0;

/// in water
inWater = false;

