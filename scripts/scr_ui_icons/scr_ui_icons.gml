/// @description  The icon vocabulary - the art the UI draws, named once.
///
/// WHY THIS EXISTS (2026-10-21).  The art drop delivered 36 UI icons: four
/// currencies, four clover branches, two node pips, mastery I-V, five
/// blood-tree tiers, eight candy and seven medals plus a locked medal.  Most
/// of them have no screen yet, and the ones that do are split across
/// scr_meta_screen, scr_badges and whatever draws the blood tree next - so if
/// each screen spelled the sprite itself, the same name would be typed in four
/// files by the time all six sets are in use, and a redraw would be an edit in
/// all of them.
///
/// So: one function per KIND of icon, each returning a sprite or -1, and
/// icon_draw() as the only thing that draws one.  -1 means "no art for that",
/// and every reader survives it - which is what lets a screen ask for a set
/// that has not arrived without a stub sprite (LL-012 is the reason nothing
/// may be drawn unguarded; LL-023 is why an unused sprite is not content).
///
/// THE CANVASES ARE THE SIZE THE JOB NEEDS: 24 for the currency line, 48 for a
/// node row or a growth panel, 64 for a candy or a medal.  icon_draw() is told
/// the size it wants on SCREEN and works the scale out from the canvas, then
/// subtracts the origin - so the two blood-tree icons whose origin is (0,0)
/// instead of the centre land exactly where every other icon does instead of
/// half a tile up and left.

enum CURRENCY { SEEDS = 0, CLOVERS, SHARDS, CANDY };
enum BRANCH   { VITALITY = 0, OFFENSE, GROWTH, HARVEST };

/// A currency icon.  All four have art, but only Seeds and Clovers have a
/// system to count them today: Blood Shards arrive with shard-pity-and-drops
/// and Candy with candy-recipes, and until then nothing calls for them.
function icon_currency(_kind) {
	switch(_kind){
		case CURRENCY.SEEDS:   return spr_seeds;
		case CURRENCY.CLOVERS: return spr_clover;
		case CURRENCY.SHARDS:  return spr_blood_shard;
		case CURRENCY.CANDY:   return spr_candy_currency;
	}
	return -1;
}

/// A clover branch icon.  Offense is the only branch with nodes (Phase 1), so
/// it is the only one on screen - the other three are content for the trees
/// that roadmap 1.7 still owes, and their art is waiting.
function icon_branch(_branch) {
	switch(_branch){
		case BRANCH.VITALITY: return spr_vitality;
		case BRANCH.OFFENSE:  return spr_offense;
		case BRANCH.GROWTH:   return spr_growth;
		case BRANCH.HARVEST:  return spr_harvest;
	}
	return -1;
}

/// A node's pip: bronze while it has ranks left to buy, gold once it is maxed.
/// (The brief reserves gold for ranks 6-10; with five ranks a node, "gold" is
/// "nothing left to spend on" - the same meaning as the word "maxed" already
/// drawn on that row.)
function icon_node(_maxed) {
	if(is_bool(_maxed)) return _maxed ? spr_node_gold : spr_node_bronze;
	if(is_numeric(_maxed) && _maxed >= 1) return spr_node_gold;
	return spr_node_bronze;
}


/// Mastery I-V.  `_rank` is 1-based and out of range returns -1, because the
/// mastery panel that will draw it does not exist yet - do not guess a frame.
function icon_mastery(_rank) {
	switch(_rank){
		case 1: return spr_mastery1;
		case 2: return spr_mastery2;
		case 3: return spr_mastery3;
		case 4: return spr_mastery4;
		case 5: return spr_mastery5;
	}
	return -1;
}

/// A blood-tree tier, 1-5, in the order the tree spends them:
/// Magnet, Hemorrhagic Harvest, Crimson Appetite, Blood Moon, Crimson Garden.
function icon_blood(_tier) {
	switch(_tier){
		case 1: return spr_blood_magnet;
		case 2: return spr_hemorrhagic_harvest;
		case 3: return spr_crimson_appetite;
		case 4: return spr_blood_moon;
		case 5: return spr_crimson_garden;
	}
	return -1;
}

/// A candy, by its recipe name.  The names are the sprite suffixes so that the
/// art and the recipe table cannot drift apart silently: a name that is not
/// here returns -1 and draws nothing, which is visible, where a wrong frame
/// would look like a design choice.
function icon_candy(_name) {
	if(!is_string(_name)) return -1;
	switch(_name){
		case "red_licorice":    return spr_red_licorice;
		case "jawbreaker":      return spr_jawbreaker;
		case "gummy_worm":      return spr_gummy_worm;
		case "sour_drop":       return spr_sour_drop;
		case "fireball":        return spr_fireball_candy;
		case "frosted_flake":   return spr_frosted_flake;
		case "blood_bonbon":    return spr_blood_bonbon;
		case "everlasting_gob": return spr_everlasting_gob;
	}
	return -1;
}

/// A medal, by BADGE.  The art has seven medals and the enum has three, so the
/// four that are not named yet fall through to the locked medal ON PURPOSE:
/// showing the locked plate is honest, and showing the wrong medal is not.
/// Growing BADGE is region-badges' job, and this switch grows with it.
function icon_badge(_badge) {
	switch(_badge){
		case BADGE.UNTOUCHED:    return spr_badge_untouched;
		case BADGE.EXTERMINATOR: return spr_badge_exterminator;
		case BADGE.BRUTALIST:    return spr_badge_brutalist;
	}
	return spr_badge_locked;
}

/// Draw one icon with its CANVAS CENTRE at (_x,_y) and its longest side
/// `_size` pixels on screen.  Returns false when there is no art, which is the
/// signal a caller needs to not leave a gap for a picture that is not there.
///
/// The origin is subtracted rather than assumed: draw_sprite_ext scales around
/// the origin, so a 48x48 icon whose origin is (0,0) would otherwise hang half
/// a tile up and left of every other icon in the same row.
///
/// Alpha is inherited from the draw state, so an icon inside a fade fades with
/// it; the colour is not, because a tinted icon is not what any caller wants.
function icon_draw(_spr, _x, _y, _size) {
	if(!sprite_exists(_spr)) return false;                /// LL-012
	var _w = sprite_get_width(_spr),
	    _h = sprite_get_height(_spr);
	if(_w <= 0 || _h <= 0) return false;
	var _s = ((_size > 0) ? _size : max(_w, _h)) / max(_w, _h);
	draw_sprite_ext(_spr, 0,
	                _x - sprite_get_xoffset(_spr) * _s,
	                _y - sprite_get_yoffset(_spr) * _s,
	                _s, _s, 0, c_white, draw_get_alpha());
	return true;
}
