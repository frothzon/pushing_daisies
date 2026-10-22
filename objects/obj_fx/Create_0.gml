/// @description  One-shot sprite effect - see scr_fx, which owns the table and
/// is the only thing that creates one of these.
///
/// The defaults are a SAFETY NET, not the real values: fx_play() writes spr,
/// frames, scale, fps, fade and t immediately after instance_create_depth().
/// They exist so that a Step or a Draw that somehow runs first reads a number
/// rather than an undefined (LL-002).
spr    = -1;
frames = 0;
scale  = 1;
fpsec    = 12;
fade   = true;
t      = 0;

/// Sort with the world it sits in rather than on top of it: one depth unit IN
/// FRONT of the ground at this y (smaller draws in front), so a muzzle puff is
/// not hidden behind the tower that fired it and an impact is not hidden
/// behind the monster that took it.
depth = scr_depth_y(y) - 1;

