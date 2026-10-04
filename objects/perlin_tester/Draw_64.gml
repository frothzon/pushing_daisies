/// @description draw map

for(var j = 0; j < ww; j++){
	for(var i = 0; i < hh; i++){
		var val = map[# j,i];
		var x1 = i*4;
		var y1 = j*4;
		var x2 = x1+4;
		var y2 = y1+4;
		var cc = merge_color(c_white, c_black, val/values);
		draw_rectangle_color(x1,y1,x2,y2,cc,cc,cc,cc,0);
	}
}

draw_set_color(c_black);
draw_text(16,16, "Press G to generate new map.");
draw_set_color(c_lime);
draw_text(16,15, "Press G to generate new map.");



