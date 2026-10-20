/// @description  scr_zomb_death();
/// death
function scr_zomb_death() {
	if(data[MON.life] <= 0){

	    // add points and score
	    /// WHAT a kill pays - the wave ramp, the difficulty column and the
	    /// carried fraction - is one rule and it lives in scr_kill_money
	    /// (difficulty_data.gml, LL-042).
	    ///
	    /// The arguments are evaluated HERE, in the monster's scope, where `data`
	    /// means this creature; only the carry is the run's, and that belongs to
	    /// _levelControl, so it is read and written inside with() - never from
	    /// outside (AGENTS.md 1 rule 6).
	    var _base = data[MON.kill_money],
	        _pay  = 0;
	    with(_levelControl){
	        /// A BOSS's payout is already `wave + 1` (scr_level_spawn), so the
	        /// wave ramp is for the regular kills - on a boss the same wave would
	        /// be counted twice.
	        _pay = scr_kill_money(_base, wave_count, !is_boss_wave);
	    }
	    add_item_value(STATINV.money, _pay);
	    var _points = floor(sqrt(data[MON.maxLife]))+1;
	    add_item_value(STATINV.points,_points);
	    float_text(x,y-32,concat("+",_points," Pts"),c_ltgray);

	    /// One line per kill, so every monster's fate is labelled exactly
	    /// once - kill / leak / valve - and "why did it disappear?" is
	    /// answerable from the log instead of from an argument (LL-011).
	    /// the SAME number that was just paid, not a second opinion about it -
	    /// a log that re-derives a payout can disagree with the purse
	    scr_meta_log("LEVEL", "kill ", data[MON.name], " +money=",
	                 _pay,
	                 " +pts=", _points, " (life ",
	                 get_item_value(STATINV.life), " left)");
    
	    ///----------------- add debree to screen
	    var _x = x + irandom_range(-8,8),
	        _y = y-(z_climb*2-12) + irandom_range(-8,8);
	    scr_addDebree(bck_debree_blood,32,32,irandom(8),0,_x,_y,clamp(depth+5,-49,1));
	    scr_burstPartSelf(ENGINE.pt_bloody,5,30);
	    /// remove
	    instance_destroy();
	}



}
