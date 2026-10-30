/// @description  mon_enums
function mon_enums() {

	/// MON.portrait is the whole portrait sprite shown in the "Up Next" box.
	/// MON.combat_class is appended after all legacy slots so MON.maxLife,
	/// debree and portrait retain their established indices (LL-057).
	enum MON{
	    name, speed, life, sprite_data, kill_score, kill_money, spawn_count,
	    maxLife, debree, portrait, combat_class
	}

	enum MON_CLASS { NORMAL, ELITE, BOSS }
}
