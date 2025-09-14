// The Evil Within — IGT (seconds) + Chapter + Subsplit autosplitter

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
    // Minimal IGT stabilization vars
    vars.lastGoodSec = 0;
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

    // Case B: special “early split” if subsection changed to a marker but chapterNumber has not yet incremented
    bool doEarlySplit = isFirstOfNext && (current.chapterNumber == old.chapterNumber);

    // Case C: chapter increment detected; suppress if we just did an early split
    bool doChapterSplit = (current.chapterNumber > old.chapterNumber) && !vars.suppressedNextChapterInc;

    if (doEarlySplit)
    {
        vars.suppressedNextChapterInc = true;
        return true;
    }

    if (doChapterSplit)
    {
        vars.suppressedNextChapterInc = false;
        return true;
    }

    return doSubSplit;
}

gameTime
{
    // Minimal stabilization: ignore zero/backwards/absurd; keep last good seconds.
    var t = current.inGameTime;
    int last = (int)vars.lastGoodSec;

    if (t > 0)
    {
        vars.lastGoodSec = t;
        last = t;
    }

    return TimeSpan.FromSeconds(last);
}

// Do NOT pause — we just want a clean, monotonic IGT on the main timer.
isLoading
{
    return false;
}
