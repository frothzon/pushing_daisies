/// @description  show damage
scr_showMonDamage();

/// free the two paths Create_0 made.  Neither was ever destroyed, so every
/// zombie leaked a path resource for the life of the level.  Guarded, because
/// a Destroy can in principle run on an instance whose Create did not finish,
/// and reading an unset variable would itself throw (LL-002).
if(variable_instance_exists(id, "myPath") && path_exists(myPath)){
    path_delete(myPath);
}
if(variable_instance_exists(id, "path_probe") && path_exists(path_probe)){
    path_delete(path_probe);
}


