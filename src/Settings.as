[Setting category="General" name="Auto-refresh Waypoints List"]
bool S_AutoRefresh = true;

[Setting category="General" name="Warp to Spawn Loc instead of block location?" description="Useful for checking standing respawns."]
bool S_WarpToSpawnLoc = true;

#if SIG_DEVELOPER
[Setting category="General" name="Show Button to open in Nod Explorer"]
bool S_ShowNodExploreBtn = true;
#else
bool S_ShowNodExploreBtn = false;
#endif
