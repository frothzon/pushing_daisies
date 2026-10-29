action_inherited();

debug_tracker_name = "";

/// setup state
/// THE PLACEHOLDER, and nothing more.  obj_mon's own sprite is spr_mon: ONE
/// 32x32 frame, so a monster drawn before anything names its art showed the
/// same still picture as its walk AND as its death - the "every monster spawns
/// with one sprite for both animations" report (LL-082).
///
/// This array is not the art.  scr_level_spawn overwrites it with the class's
/// four slots and mon_rig_dress() puts the class's WALK sheet on the instance
/// in the same breath, and scr_zomb_step re-dresses any monster whose sprite
/// is not its class's.  It stays here because zomb_rig() rebuilds a rig from
/// it when the roster has no answer for this creature - a last resort, not a
/// default.
///
/// image_speed = 0 because a one-frame sprite that drifts its image_index
/// looks like a broken walk cycle rather than the placeholder it is.
sprite_array = [spr_mon,spr_mon];
image_speed  = 0;

/// ---- the creature's RIG (scr_mon_roster) ------------------------------
/// This monster's four animations - walk, idle, attack, die - as ONE struct
/// with those names, pulled from the roster by the creature's name instead of
/// copied here as a bare array that every state then indexed by number.
///
/// It used to be a positional read of `sprite_array[3]`, and a slot that was
/// missing answered -1 with no error at all: a dying monster kept its walk
/// frames and looked like broken art rather than a missing slot (LL-079,
/// LL-081).  scr_level_spawn fills this when it spawns the monster; declared
/// HERE because a read must never be the first writer (LL-002), and because a
/// monster that is on screen before a wave reaches it still draws - zomb_rig()
/// answers undefined by pulling the roster and, failing that, by rebuilding
/// the rig from this instance's own sprite_array.
rig = undefined;
/// the full size the emerge grows to (scr_zombie_emerge);
/// scr_level_spawn overwrites this for each monster
base_scale = 1;
/// ---- the monster's own STATE (scr_zomb_state) ----------------------
/// An enum, not a script reference: scr_setupState's `state = -1` was the
/// LL-004 sentinel, and "the first state" was named in obj_mon/Step_0.
/// NONE is the "no request pending" sentinel; every monster is born
/// EMERGing, and the emerge's 60-step grow is that state's entry clock.
zomb_state      = ZOMB_STATE.NONE;
zomb_state_next = ZOMB_STATE.EMERGE;
zomb_state_time = 0;

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
/// the depth from BIRTH: the monster enters at the spawn point feet, so
/// the first frame is already sorted instead of sitting at the spawner's
/// default depth.  obj_mon/Step_0 keeps it current as it walks (LL-059).
depth = scr_depth_y(y);
pos_save = array(x,y);

/// path_free starts true, but scr_zombie_path now OVERWRITES it from the
/// real mp_grid_path result - the two must never disagree (roadmap
/// 4.4.1, defect 4)
path_free = true;
path_retry = 0;      /// failed re-path attempts since the last success
path_escape = false; /// true once we stop politely waiting for a route
path_pos_last = 0;   /// path_position one step ago - the valve's evidence
stuck_frames  = 0;   /// steps the path follower has NOT advanced (LL-031)
data = scr_makeMonster(0,0,0,0,0,0);

/// show damage taken
damage_timer = irandom(3)*game_get_speed(gamespeed_fps);
damage_amount = 0;

/// climb
z_climb = 0;
rot_angle = 0;

/// in water
inWater = false;
/// one line, once, naming the waterline this monster got - see
/// water_line_report (draw_water_shader.gml).  A diagnostic, not mechanics.
water_reported = false;

/// ---- Phase 2: the statuses ON this monster (scr_status) -------------
/// ONE struct, one entry per kind, created HERE so a read can never be the
/// first writer (LL-002) - obj_mon/Step_0's clock and every reader in
/// scr_status guard for it, but a guard that fires every step for every
/// monster is a guard that is doing the work the Create event should have
/// done.  `status_count` is the fast exit: a monster carrying nothing pays
/// one comparison a step instead of walking the struct.
statuses     = {};
status_count = 0;

/// ---- the death beat (scr_zomb_death -> ZOMB_STATE.DIE) -------------
/// `dying` is what stops a corpse from being paid for twice, targeted
/// again or leaked.  Declared HERE because every reader (find_all_range,
/// scr_zomb_updatePosition, Alarm_0) asks before the first death in the
/// room has happened - a read must never be the first writer (LL-002).
dying      = false;
dying_time = 0;

/// ---- and the fall's own state (scr_zombie_die) ---------------------
/// zomb_die_art is the switch between the TWO clocks: TRUE when the kill
/// really put a die sheet on this monster - one it can advance - so the
/// animation itself says when the body is done.  FALSE when the rig has
/// no die slot and the corpse keeps the art it died in (LL-079); then
/// ZOMB_DIE_SECS in steps is the only clock there is.  Declared here for
/// the same reason as `dying`: the DIE entry code is not the only reader.
zomb_die_steps  = 0;     /// the duration the art was asked for, in steps
zomb_die_art    = false; /// is there a sheet to watch?
/// TRUE when the kill put a die CLIP on the Spriter player instead of a
/// sheet (scr_scml_rig): the player's playing going FALSE at the clip's
/// end is then the exit clock, and the sheet-wrap logic does not run.
/// Declared here for the same reason as zomb_die_art: the DIE entry code
/// is not the only reader (LL-002).
zomb_die_scml   = false; /// is the fall a Spriter clip?
zomb_die_prev   = 0;     /// the frame drawn last, to see the sheet wrap
zomb_die_warned = false; /// has the backstop already said its piece?

