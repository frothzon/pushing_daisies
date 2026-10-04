action_inherited();
/// setup state
sprite_array = array(spr_mon,spr_mon);
scr_setupState();

/// generate path
/// mp_collider

myPath = path_add();

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

path_free = true;
data = scr_makeMonster(0,0,0,0,0,0);

/// show damage taken
damage_timer = irandom(3)*room_speed;
damage_amount = 0;

/// climb
z_climb = 0;
rot_angle = 0;

/// in water
inWater = false;

