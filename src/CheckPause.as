
/**
 * Check to see if more ms than the limit have passed since the last pause, and if so, yield.
 */
uint g_LastPause = Time::Now;
void CheckPause() {
    uint workMs = Time::Now < 20000 ? 1 : 2;
    if (g_LastPause + workMs < Time::Now) {
        yield();
        // trace('paused');
        g_LastPause = Time::Now;
    }
}
