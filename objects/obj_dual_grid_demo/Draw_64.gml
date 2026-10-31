/// @description Show all 16 masks and the rendered terrain test map.
draw_set_color(c_white);
draw_set_alpha(1);
draw_set_font(fnt_size32);
draw_text(20, 14, "DUAL-GRID TERRAIN TEST");
draw_set_font(fnt_size16);
draw_text(20, 54, "Generated debug atlas | mask bits TL=1 TR=2 BL=4 BR=8");

/// Mask palette: each sample is one atlas frame at enlarged scale.
draw_set_color(make_colour_rgb(29, 35, 33));
draw_set_alpha(0.9);
draw_rectangle(12, 82, 330, 452, false);
draw_set_alpha(1);
draw_set_color(c_white);
draw_text(22, 86, "MASK FRAMES 0-15");
for(var _mask = 0; _mask <= 15; _mask++){
	var _col = _mask mod 4,
	    _row = floor(_mask / 4),
	    _tile_x = 22 + _col * 76,
	    _tile_y = 112 + _row * 78;
	draw_set_color(make_colour_rgb(47, 55, 50));
	draw_rectangle(_tile_x, _tile_y, _tile_x + 60, _tile_y + 60, false);
	if(sprite_exists(atlas_id)){
		draw_sprite_ext(atlas_id, _mask, _tile_x + 30, _tile_y + 30,
		                0.46, 0.46, 0, c_white, 1);
	}
	var _bits = string((_mask mod 2))
	          + string(floor(_mask / 2) mod 2)
	          + string(floor(_mask / 4) mod 2)
	          + string(floor(_mask / 8) mod 2);
	draw_set_color(c_white);
	draw_text(_tile_x + 2, _tile_y + 60, string(_mask) + "  " + _bits);
}

/// Rendered sample uses the same 32px cell spacing as the game.
draw_set_font(fnt_size20);
draw_set_color(c_white);
draw_text(360, 83, "RENDERED MAP | 32px CELLS");
draw_set_font(fnt_size16);
draw_text(360, 105, "Edge, hole, inner notch and diagonal-only pair");
draw_set_alpha(0.35);
draw_set_color(c_white);
for(var _gx = 0; _gx <= demo_grid_width; _gx++){
	var _line_x = demo_world_x + _gx * 32;
	draw_line(_line_x, demo_world_y, _line_x,
	          demo_world_y + demo_grid_height * 32);
}
for(var _gy = 0; _gy <= demo_grid_height; _gy++){
	var _line_y = demo_world_y + _gy * 32;
	draw_line(demo_world_x, _line_y,
	          demo_world_x + demo_grid_width * 32, _line_y);
}
draw_set_alpha(1);
draw_set_color(c_white);
draw_text(360, 466, "Map edge: x=0   Hole: (4,3)-(5,4)");
draw_text(360, 488, "Diagonal-only cells: (11,1) and (12,2) | tile count: "
	      + string(demo_tile_count));
if(!sprite_exists(atlas_id)){
	draw_set_color(c_red);
	draw_text(360, 512, "Debug atlas failed; check META [DGRID] ERROR.");
}
draw_set_color(c_white);
