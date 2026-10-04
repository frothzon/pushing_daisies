/// @description reset

ds_grid_destroy(map);

randomize();
var seed = random_get_seed();

map = create_perlin_grid(ww, hh, 20, values, seed);





