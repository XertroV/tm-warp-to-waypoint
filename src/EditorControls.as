namespace Editor {
    // main waypoints
    Waypoint@[]@ _Waypoints = array<Waypoint@>();
    Waypoint@[]@ _CachedWaypoints;
    uint vCountAtRefresh = 0;

    Waypoint@[]@ Waypoints {
        get {
            if (_CachedWaypoints !is null)
                return _CachedWaypoints;
            return _Waypoints;
        }
    }

    bool refreshing = false;
    void Refresh() {
        if (refreshing) return;
        refreshing = true;
        lastTargeted = -1;
        vCountAtRefresh = lastVertexCount;
        // prep new waypoints array
        @_CachedWaypoints = _Waypoints;
        @_Waypoints = array<Waypoint@>();

        GetItems();
        GetCpBlocks();
        yield();
        _Waypoints.SortAsc();
        @_CachedWaypoints = null;
        refreshing = false;
    }

    void GetItems() {
        auto map = GetApp().RootMap;
        if (map is null) return;
        for (uint i = 0; i < map.AnchoredObjects.Length; i++) {
            CheckPause();
            auto item = map.AnchoredObjects[i];
            if (item.ItemModel.IsCheckpoint || item.ItemModel.IsFinish || item.ItemModel.IsStart || item.ItemModel.IsStartFinish) {
                _Waypoints.InsertLast(Waypoint(item));
            }
        }
    }

    void GetCpBlocks() {
        auto map = GetApp().RootMap;
        if (map is null) return;
        for (uint i = 0; i < map.Blocks.Length; i++) {
            CheckPause();
            auto item = map.Blocks[i];
            if (item.WaypointSpecialProperty is null) continue;
            _Waypoints.InsertLast(Waypoint(item));
        }
    }

    void SetTargetedPosition(vec3 pos, bool updateCam = true) {
        cast<CGameCtnEditorFree>(GetApp().Editor).OrbitalCameraControl.m_TargetedPosition = pos;
        if (updateCam) UpdateCamera();
    }

    void SetOrbitalAngle(float h, float v, bool updateCam = true) {
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        editor.OrbitalCameraControl.m_CurrentHAngle = h;
        editor.OrbitalCameraControl.m_CurrentVAngle = v;
        if (updateCam) UpdateCamera();
    }

    void UpdateCamera() {
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        editor.ButtonZoomInOnClick();
        editor.ButtonZoomOutOnClick();
    }

    void SelectNext() {
        lastTargeted = (lastTargeted + 1) % Waypoints.Length;
        Waypoints[lastTargeted].TargetMe();
    }

    void SelectPrevious() {
        lastTargeted = (Waypoints.Length + Math::Max(-1, lastTargeted - 1)) % Waypoints.Length;
        Waypoints[lastTargeted].TargetMe();
    }
}
