/// @description setup

randomize();
var seed = random_get_seed();

values = 10;
ww = display_get_gui_width() div 4;
hh = display_get_gui_height() div 4;
//map = perlin_map(ww, hh, 10, seed, values);
map = create_perlin_grid(ww, hh, 20, values, seed);



