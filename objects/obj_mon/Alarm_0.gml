/// @description  restart

path_end();
path_clear_points(myPath);
path_free = mp_grid_path(LEVEL.path_grid,myPath,x,y,path_loc[0],path_loc[1],true);
path_start(myPath,1,0,true);
print(path_free);

if(!path_free){
    alarm[0] = room_speed*0.5;
}

