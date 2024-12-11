enum WaypointType {
    Start,
    Finish,
    Checkpoint,
    None,
    StartFinish,
    Dispenser
}

enum MEColor {
    Default = 0, White, Green, Blue, Red, Black
}

int lastTargeted = -1;

class Waypoint {
    vec3 Position;
    nat3 GridPos;
    vec3 Direction;
    vec3 SpawnLoc;
    WaypointType type;
    bool NoRespawn;
    bool IsItem = false;
    bool IsLinked = false;
    bool IsCheckpoint = false;
    uint Order;
    string Name;
    string Nonce = Crypto::RandomBase64(5);
    CMwNod@ nod;
    MEColor MapElemColor;
    string BlockOrItemIcon;

    Waypoint(CGameCtnAnchoredObject@ item) {
        @nod = item;
        type = WaypointType(int(item.ItemModel.WaypointType));
        Position = item.AbsolutePositionInMap;
        GridPos = item.BlockUnitCoord;
        IsItem = true;
        MapElemColor = MEColor(int(item.MapElemColor));
        Name = item.ItemModel.Name; // also .Description, .NameE, .ArticlePointer.Name, .AritclePointer.NameOrDisplayName
        SpawnLoc = GetItemModelSpawnLoc(item.ItemModel);
        if (SpawnLoc.LengthSquared() > 0) SpawnLoc = Position + (EulerToMat(GetItemRotation(item)) * SpawnLoc).xyz;
        // NoRespawn = item.
        OnSpecialProperty(item.WaypointSpecialProperty);
        SetOtherProps();
    }

    Waypoint(CGameCtnBlock@ block) {
        @nod = block;
        Position = GetBlockPosition(block);
        type = WaypointType(int(block.BlockInfo.EdWaypointType));
        NoRespawn = block.BlockInfo.NoRespawn;
        Name = block.BlockInfo.Name;
        MapElemColor = MEColor(int(block.MapElemColor));
        SpawnLoc = GetBlockSpawnLoc(block);
        if (SpawnLoc.LengthSquared() > 0) SpawnLoc = Position + (GetBlockRotationMatrix(block) * SpawnLoc).xyz;
        OnSpecialProperty(block.WaypointSpecialProperty);
        SetOtherProps();
    }

    void SetOtherProps() {
        IsCheckpoint = type == WaypointType::Checkpoint;
        BlockOrItemIcon = IsItem ? Icons::Tree : Icons::Cube;
        string col = "\\$";
        switch (MapElemColor) {
            case MEColor::White: col += "fff"; break;
            case MEColor::Green: col += "2f2"; break;
            case MEColor::Blue: col += "19f"; break;
            case MEColor::Red: col += "f22"; break;
            case MEColor::Black: col += "666"; break;
            default: col += "ccc"; break;
        }
        BlockOrItemIcon = col + BlockOrItemIcon;
    }

    void OnSpecialProperty(CGameWaypointSpecialProperty@ wsp) {
        // todo: linked cps, etc
        IsLinked = wsp.Tag.StartsWith("Linked");
        Order = wsp.Order;
    }

    int opCmp(const Waypoint &in other) {
        if (other is null) return -1;
        return other.type > type ? -1
            : other.type < type ? 1
            : IsLinked != other.IsLinked ? (IsLinked ? 1 : -1)
            : Order < other.Order ? -1
            : Order > other.Order ? 1 : 0;
    }

    void Draw() {
        UI::AlignTextToFramePadding();
        UI::Text(Name + " " + (IsLinked ? Icons::Link : Icons::ChainBroken) + " " + tostring(type));
    }

    const string TypeIcon() {
        switch (type) {
            case WaypointType::Start: return "\\$1f1" + Icons::Flag;
            case WaypointType::Finish: return "\\$f11" + Icons::FlagCheckered;
            case WaypointType::Checkpoint: return "\\$1bfCP"; // return Icons::HourglassHalf;
            // case WaypointType::None: return Icons::QuestionCircle;
            case WaypointType::StartFinish: return "\\$ff1" + Icons::FlagO;
            // case WaypointType::Dispenser: return Icons::QuestionCircle;
        }
        return Icons::QuestionCircle;
    }

    const string DistanceIcon() {
        return "\\$f90" + Icons::ThermometerFull;
        "\\$fb0" + Icons::ThermometerThreeQuarters;
        "\\$da5" + Icons::ThermometerHalf;
        "\\$765" + Icons::ThermometerQuarter;
        "\\$555" + Icons::ThermometerEmpty;
    }

    // assumes 6 columns
    void DrawTableRow(int i) {
        bool targeted = i == lastTargeted;
        UI::PushID(Nonce);

        UI::TableNextRow();
        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        if (targeted)
            UI::PushStyleColor(UI::Col::Button, vec4(.6, .2, .1, .7));
        if (UI::Button(tostring(i+1) + ".")) {
            lastTargeted = i;
            TargetMe();
        }
        UI::PopStyleColor(targeted ? 1 : 0);

        UI::TableNextColumn();
        UI::Text(Name);

        UI::TableNextColumn();
        UI::Text(BlockOrItemIcon);

        UI::TableNextColumn();
        UI::Text(TypeIcon());

        UI::TableNextColumn();
        // if (IsCheckpoint)
        UI::Text((IsLinked ? GroupColor() + LinkedIcon : UnlinkedIcon) + " " + Order);

        UI::TableNextColumn();
        if (UI::Button(Icons::Crosshairs)) {
            lastTargeted = i;
            TargetMe();
        }
        // UI::SameLine();
        // if (UI::Button(Icons::PlusCircle)) {
        //     AddToCurrentSelection();
        // }

#if SIG_DEVELOPER
        UI::SameLine();
        if (S_ShowNodExploreBtn && UI::Button(Icons::Cube)) {
            ExploreNod(nod);
        }
#endif

        UI::PopID();
    }

    string _grpColor;
    const string GroupColor() {
        if (_grpColor.Length == 0) {
            _grpColor = "\\$000";
            _grpColor[2] = ToSingleHexCol(15.999 * (Math::Sin(1.0 * float(Order) + 1. + Order) / 4. + .75));
            _grpColor[3] = ToSingleHexCol(15.999 * (Math::Sin(1.1 * float(Order) + 3. + Order) / 4. + .75));
            _grpColor[4] = ToSingleHexCol(15.999 * (Math::Sin(0.9 * float(Order) + 5. + Order) / 4. + .75));
            // print((_grpColor).Replace("\\$", "$") + "Group + " + Order);
            // print((_grpColor) + "Group + " + Order);
        }
        return _grpColor;
    }

    void TargetMe() {
        auto pos = S_WarpToSpawnLoc && SpawnLoc.LengthSquared() > 0 ? SpawnLoc : Position;
        Editor::SetTargetedPosition(pos, false);
        Editor::SetOrbitalAngle(Math::ToRad(45), Math::ToRad(45));
    }

    // sorta works most of the time, but not very well in dense situations
    // void AddToCurrentSelection() {
    //     auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    //     auto coords = PositionToCoords(Position);
    //     editor.PluginMapType.CopyPaste_AddOrSubSelection(coords, coords);
    //     editor.PluginMapType.ShowCustomSelection();
    // }
}

const string UnlinkedIcon = "\\$888" + Icons::ChainBroken;
const string LinkedIcon = Icons::Link;

uint8 ToSingleHexCol(float v) {
    if (v < 0) { v = 0; }
    if (v > 15.9999) { v = 15.9999; }
    int u = uint8(Math::Floor(v));
    if (u < 10) { return 48 + u; }  /* 48 = '0' */
    return 87 + u;  /* u>=10 and 97 = 'a' */
}
