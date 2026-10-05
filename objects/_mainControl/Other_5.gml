/// @description  release the pause snapshot
/// pause_surf holds a SPRITE (sprite_create_from_surface returns one),
/// not a surface.  Testing surface_exists() on a sprite id could never
/// match, so the sprite was never released.  It has been a sprite since
/// the snapshot was first written, so this is a long-standing confusion
/// rather than a new leak - but it is the same one that produced the
/// black pause screen, so it is worth removing.
if(sprite_exists(pause_surf)){
    sprite_delete(pause_surf);
}

