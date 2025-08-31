state("EvilWithin")
{
    int chapterNumber: 0x225DCE8;
    int inGameTime: 0x02258E00, 0x68, 0x28, 0x8D8C;
    //int isPaused: 0x1D42490, 0x2C; // 2 while paused, 1 in game
    //int inGame: 0x89EF698; // 0 == game; 2 == main menu/loading screen, 3 == choice(?) screens
}

startup
{
    // Force Game Time
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
        timer.CurrentTimingMethod = TimingMethod.GameTime;
}

update
{
    // (Optional) put debug or mapping here if needed
    // e.g., vars.Log(chapterNumber, inGameTime);
}

start
{
    // Start when we enter Chapter 1 AND IGT begins ticking from 0
    return old.chapterNumber == 0
        && current.chapterNumber == 1
        && old.inGameTime == 0
        && current.inGameTime > 0;
}

split
{
    // Split whenever chapter increases (covers +1 and any skips)
    return current.chapterNumber > old.chapterNumber
        && old.chapterNumber > 0;
}

reset
{
    // Optional: reset if we go back to "no chapter" after having one
    return old.chapterNumber > 0 && current.chapterNumber == 0;
}

isLoading
{
    // We’re driving the timer purely by gameTime() below.
    // Keeping this true ensures loads/RT are ignored.
    return true;
}

gameTime
{
    // IMPORTANT: If inGameTime is milliseconds, switch to FromMilliseconds.
    // If it's seconds, keep FromSeconds.
    if (current.inGameTime > 0)
    {
        // return TimeSpan.FromMilliseconds(current.inGameTime); // ← use if IGT is ms
        return TimeSpan.FromSeconds(current.inGameTime);         // ← use if IGT is s
    }
}
