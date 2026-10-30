/// @description  tower_enums();
function tower_enums() {

	enum TOWER{
	    range, damage, fire_rate, effect, level, targets,
	    crit_chance, crit_damage
	};

	/// The three slots of a tower's sprite_list, in the order the roster
	/// hands them over (tower_roster.gml: idle, attack, return). These were
	/// 0/1/2 literals spread through three state scripts.
	enum TOWER_ANIM {
	    idle, attack, return
	};
}
