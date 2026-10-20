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
/// loop_in / loop_out ARE THE LOOP SECTION, IN SECONDS.  The track plays its
/// intro once and then repeats loop_in -> loop_out for as long as the stage
/// runs - the "Intro & Outro" shape in the GameMaker Audio Loop Points manual.
///
/// WHY loop_out EXISTS (and not just loop_in).  The first cut of this table
/// looped "chorus -> end of file", which is what the GameMaker manual's
/// Intro & Outro example does - but every one of these seven tracks was written
/// intro / body / breakdown / body / OUTRO FADE, so a loop to the end of the
/// file went through the fade, sat in silence for a moment and restarted the
/// body.  That is the "music fades out in the middle of a stage" symptom: not a
/// stopped track, a loop that includes the ending.  A section has TWO ends.
///
/// The points are measured, not guessed: a 20 ms RMS envelope is compared with
/// the track's median level (0.9x it), the intro ends at the first bar that
/// reaches it and the outro starts at the last bar that falls below it, both
/// snapped to the bar grid at the track's BPM.  The body between them is the
/// loop; the intro and the outro are played once and never again.
///
/// -1 MEANS "NO POINT AT THAT END": loop_out = -1 loops to the end of the file,
/// loop_in = -1 is read as 0.  loop_in = 0 is a legitimate START - mus_world5
/// begins at full level and has no intro - so 0 cannot double as "unset" here.
///
/// sound = -1 MEANS "NOT GENERATED YET": such a region plays nothing and says
/// so in the log, instead of silently borrowing a track that is not its own.
/// Every region has its own track today - mus_world1..mus_world6, in region
/// order - so no row is -1; the sentinel stays for the day a region is added
/// before its music is.
///
/// The titles here are the ones notes/Music-Generation/Music-Generation.md
/// briefs, and the two files must agree - that note is where the prompts live.

function music_row(_region, _sound, _title, _loop_in, _loop_out) {
	return {
		region   : _region,    /// 1..6, or 0 for the title / menu theme
		sound    : _sound,     /// the sound asset, or -1 for "not made yet"
		title    : _title,     /// the track's name, as the note titles it
		loop_in  : _loop_in,   /// section start in seconds; -1 = 0
		loop_out : _loop_out   /// section end in seconds; -1 = end of file
	};
}

/// The table.  Region order is the biome order of region_data():
/// 1 Grass, 2 Swamp, 3 Desert, 4 Jungle, 5 Graveyard, 6 Blood Fields.
function music_data() {
	return [
		music_row(1, mus_world1, "Wilted Sprouts",         14.63, 152.20),
		music_row(2, mus_world2, "Mires of the Undead",    13.33, 153.33),
		music_row(3, mus_world3, "Rust in the Sun",        32.73, 169.09),
		music_row(4, mus_world4, "Vines Take the Ruins",   73.85, 169.23),
		music_row(5, mus_world5, "Toll for the Nameless",  0.00, 157.71),
		music_row(6, mus_world6, "Where the Garden Ends",  20.00, 173.33)
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
///
/// IT NEEDS A LOOP SECTION TOO.  The title screen and every menu screen after
/// it play this track, and the menu used to set no loop points at all - so it
/// repeated the whole file, including a 7 s outro fade, and went quiet for a
/// few seconds every 177 s.  On a screen the player can sit on for minutes,
/// that is the most-heard version of the bug.
function music_menu() {
	return music_row(0, mus_title, "Pushing Daisies", 24.71, 169.41);
}
