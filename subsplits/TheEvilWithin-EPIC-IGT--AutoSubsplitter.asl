// The Evil Within — IGT (seconds) + Chapter + Subsplit autosplitter
// Fix v3 (per user request):
// - Only use `current` and `old`; remove prevSub storage entirely.
// - Treat EXACTLY these as "first-of-next-chapter" markers:
//     * "player_start"
//     * "st06_asylummain_player_start_chapter4_division"
// - Split early on subsection flip to a marker while chapterNumber is unchanged.
// - Suppress duplicate split when chapterNumber increments on the score screen.

state("EvilWithin")
{
    // Chapter number (adjust type if needed: int/short/byte)
    int chapterNumber : 0x225DCE8;

    // IGT (stored in SECONDS)
    int inGameTime    : 0x02258E00, 0x68, 0x28, 0x8D8C;

    // Quicksave subsection string (update size if your string can exceed 128 bytes)
    string128 subSection : 0x09C83638;
}

// ---- CONFIG -----
startup
{
    // EXACT markers used by the game for the first subsection of a chapter (case-insensitive compare)
    vars.firstSubMarkers = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
    {
        "player_start",
        "st06_asylummain_player_start_chapter4_division"
    };

    // Whether we've already split early for the upcoming chapter increment
    vars.suppressedNextChapterInc = false;
}

init
{
    vars.suppressedNextChapterInc = false;
}

// Start the timer when we first see IGT begin or on the very first valid subsection.
start
{
    return (old.inGameTime <= 0 && current.inGameTime > 0)
        || (string.IsNullOrEmpty(old.subSection) && !string.IsNullOrEmpty(current.subSection));
}

// No autoreset  
reset
{
    return false;
}

// Core split logic
split
{
    // Has the subsection changed (non-empty) since last frame?
    bool subChanged = !string.IsNullOrEmpty(current.subSection)
                   && !string.Equals(current.subSection, old.subSection, StringComparison.Ordinal);

    // Is the new subsection one of the known "first-of-next-chapter" markers?
    bool isFirstOfNext = subChanged && vars.firstSubMarkers.Contains(current.subSection);

    // Case A: normal subsplits within the same chapter (any non-marker subsection change)
    bool doSubSplit = subChanged && !isFirstOfNext && (current.chapterNumber == old.chapterNumber);

    // Case B: chapter end detected early via subsection jump to next-chapter marker
    bool doChapterSplitEarly = subChanged && isFirstOfNext && (current.chapterNumber == old.chapterNumber);

    // Case C: when the score screen bumps chapterNumber by +1,
    // suppress a second split if we already split early in Case B.
    bool chapterNumberIncreased = current.chapterNumber > old.chapterNumber;
    bool doChapterSplitLate = chapterNumberIncreased && !vars.suppressedNextChapterInc;

    // Bookkeeping for suppression flag
    if (doChapterSplitEarly)
        vars.suppressedNextChapterInc = true;
    else if (chapterNumberIncreased)
        vars.suppressedNextChapterInc = false; // clear after the bump

    return doSubSplit || doChapterSplitEarly || doChapterSplitLate;
}

isLoading
{
    // Drive timing purely by IGT below; keep loads ignored.
    return true;
}

gameTime
{
    if (current.inGameTime >= 0)
        return TimeSpan.FromSeconds(current.inGameTime);
}
