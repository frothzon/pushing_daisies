/// @description  The music table - one row per region, plus the menu theme.
///
/// Roadmap 5.8 ("Audio - region music").  This is the ONLY place a track is
/// NAMED, so adding a region's music is a table row and never an edit to the
/// level flow.
///
/// WHY A TABLE, AND WHY HERE.  A stage already knows its region
/// (GameLevelData.region), so the music it plays is a property of the REGION,
/// exactly like the difficulty curve next door in region_data.gml.  It is a
/// separate table rather than two more fields on region_row() because that
/// constructor already takes ten positional arguments, and the MON enum is the
/// standing lesson in what happens to a table that keeps growing rightwards.
///
/// loop_in IS THE CHORUS START, IN SECONDS.  The track plays its intro once and
/// then loops from there to the end of the file - the "Intro & Outro" shape in
/// the GameMaker Audio Loop Points manual.  0 means "loop the whole track".
///
/// sound = -1 MEANS "NOT GENERATED YET": such a region plays nothing and says
/// so in the log, instead of silently borrowing a track that is not its own.
/// Every region has its own track today - mus_world1..mus_world6, in region
/// order - so no row is -1; the sentinel stays for the day a region is added
/// before its music is.
///
/// The titles here are the ones notes/Music-Generation/Music-Generation.md
/// briefs, and the two files must agree - that note is where the prompts live.

function music_row(_region, _sound, _title, _loop_in) {
	return {
		region  : _region,   /// 1..6, or 0 for the title / menu theme
		sound   : _sound,    /// the sound asset, or -1 for "not made yet"
		title   : _title,    /// the track's name, as the note titles it
		loop_in : _loop_in   /// chorus start in seconds; 0 = whole track
	};
}

/// The table.  Region order is the biome order of region_data():
/// 1 Grass, 2 Swamp, 3 Desert, 4 Jungle, 5 Graveyard, 6 Blood Fields.
function music_data() {
	return [
		music_row(1, mus_world1, "Wilted Sprouts",            0),
		music_row(2, mus_world2, "Mires of the Undead",       0),
		music_row(3, mus_world3, "Rust in the Sun",           0),
		music_row(4, mus_world4, "Vines Take the Ruins",      0),
		music_row(5, mus_world5, "Toll for the Nameless",     0),
		music_row(6, mus_world6, "Where the Garden Ends",     0)
	];
}

/// One region's row, or undefined.  Never throws (LL-002), so a reader does not
/// have to guard the call - it guards the result.
function music_for_region(_region) {
	var _rows = music_data();
	for(var _i = 0; _i < array_length(_rows); _i++){
		if(_rows[_i].region == _region) return _rows[_i];
	}
	return undefined;
}

/// The title / menu theme.  ONE row, so pointing the title screen at a
/// different track is a one-line change HERE - obj_title and the Menu both
/// read this instead of naming a sound themselves.
///
/// It replaced the legacy snd_music_title, which nothing references any more.
function music_menu() {
	return music_row(0, mus_title, "Pushing Daisies", 0);
}
