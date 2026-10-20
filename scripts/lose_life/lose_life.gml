/// @description  lose_life();
function lose_life() {

	/// stop path
	path_end();

	/// destroy path
	path_delete(myPath);

	/// remove life points
	add_item_value(STATINV.life,-1);

	/// ---- A LEAK PAYS HALF (decided 2026-10-18, economy.md 4.5) --------
	/// It used to pay NOTHING, so a leak cost a life AND the income the
	/// kill would have paid - the starvation spiral in the 2026-10-12 log.
	/// Half is still strictly worse than a kill, so nothing rewards
	/// leaking, and the purse no longer falls off a cliff on the first one.
	///
	/// `scr_kill_money` is the ONE payout rule (LL-042: ramp, difficulty
	/// column, carried fraction), so a leak pay is the same number a kill
	/// would have paid, halved - never a second opinion about it.
	/// `data` is read HERE because this runs in the monster scope; the
	/// level's wave_count is read inside with() (AGENTS 1 rule 6).
	var _base = data[MON.kill_money],
	    _leak_pay = 0;
	with(_levelControl){
	    /// the scale goes INTO the rule, before its floor: half of a 1-money
	    /// kill is 0 after a floor, and two such leaks must still pay 1
	    /// (money_carry carries the other half - LL-042)
	    _leak_pay = scr_kill_money(_base, wave_count, !is_boss_wave, 0.5);
	}
	add_item_value(STATINV.money, _leak_pay);

	/// Log every leak.  This line did not exist, so "the zombies vanished
	/// and my lives never moved" could not be answered from a run: the
	/// leak -> life -> game over mechanic was invisible (LL-031, LL-011).
	/// get_item_value is a pure read of the STATINV array, so it is safe
	/// from the monster's scope (LL-003).
	scr_meta_log("LEVEL", "leak - life ", get_item_value(STATINV.life),
	             " left, +money=", _leak_pay, " (half a kill; monster ", id,
	             " reached the despawn at ", round(x), ",", round(y), ")");

	/// and count it, for the badges (roadmap 1.8).  lose_life runs in the
	/// MONSTER's scope, so the level has to be reached with with() - and
	/// guarded, in case a monster outlives the level that spawned it.
	/// variable_global_exists first: instance_exists() on a global that was
	/// never declared is not a safe test, and a guard that can throw is not
	/// a guard (LL-002).
	if(variable_global_exists("LEVEL")){
		var _lvl = LEVEL;
		if(instance_exists(_lvl)){
			with(_lvl){
				if(variable_instance_exists(id, "level_leaked")) level_leaked++;
			}
		}
	}

	/// destroy instance
	instance_destroy();



}
