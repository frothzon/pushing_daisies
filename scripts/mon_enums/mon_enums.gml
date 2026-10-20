/// @description  mon_enums
function mon_enums() {

	/// MON.portrait is a whole portrait SPRITE for the message box
	/// (the 'Up Next...' popup).  It is set in scr_setupSpawning AFTER
	/// scr_makeMonster(), whose positional arguments are fragile -
	/// MON.maxLife sits at index 7.  scr_makeMonster now defaults EVERY slot
	/// the enum names (MON.debree = 0, MON.portrait = -1 = none), so a row
	/// read before scr_setupSpawning has filled it cannot be missing one.
	enum MON{
	    name, speed, life, sprite_data, kill_score, kill_money, spawn_count, maxLife, debree, portrait
	}



}
