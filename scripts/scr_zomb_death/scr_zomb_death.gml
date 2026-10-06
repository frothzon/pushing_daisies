/// @description  scr_zomb_death();
/// death
function scr_zomb_death() {
	if(data[MON.life] <= 0){

	    // add points and score
	    /// the difficulty column scales what a kill pays (goal.md 2: Brutal
	    /// pays 1.5x).  Rounded, because money is a count, not a fraction.
	    add_item_value(STATINV.money,
	                   round(data[MON.kill_money]*difficulty_money_mult()));
	    var _points = floor(sqrt(data[MON.maxLife]))+1;
	    add_item_value(STATINV.points,_points);
	    float_text(x,y-32,concat("+",_points," Pts"),c_ltgray);
    
	    ///----------------- add debree to screen
	    var _x = x + irandom_range(-8,8),
	        _y = y-(z_climb*2-12) + irandom_range(-8,8);
	    scr_addDebree(bck_debree_blood,32,32,irandom(8),0,_x,_y,clamp(depth+5,-49,1));
	    scr_burstPartSelf(ENGINE.pt_bloody,5,30);
	    /// remove
	    instance_destroy();
	}



}
