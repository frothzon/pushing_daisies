/// @description  Draw the frame this effect is on.  The instance has no
/// sprite_index of its own on purpose - the picture is a variable, so one
/// object can play any of the eight.
if(!sprite_exists(spr)) exit;                       /// LL-012

var _f = floor(t * fps);
if(_f < 0) _f = 0;
if(_f >= frames) _f = frames - 1;                   /// the last frame, not a wrap

/// fade out over the life, so an effect that ends on a bright frame does not
/// pop off the screen
var _a = fade ? (1 - clamp(t * fps / max(frames, 1), 0, 1)) : 1;

draw_sprite_ext(spr, _f, x, y, scale, scale, 0, c_white, _a);

