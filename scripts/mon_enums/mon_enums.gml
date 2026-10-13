/// @description  mon_enums
function mon_enums() {

	/// MON.portrait is a whole portrait SPRITE for the message box
	/// (the 'Up Next...' popup).  It is set in scr_setupSpawning AFTER
	/// scr_makeMonster(), whose positional arguments are fragile -
	/// MON.maxLife sits at index 7.
	enum MON{
	    name, speed, life, sprite_data, kill_score, kill_money, spawn_count, maxLife, debree, portrait
	}



}
