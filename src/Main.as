void Main() {
    startnew(WatchEditorAndValues);
}

bool lastEditorOpen = false;
uint lastVertexCount = 0;

UI::Font@ largerFont = UI::LoadFont("DroidSans.ttf", 20.0);
UI::Font@ regularFont = UI::LoadFont("DroidSans.ttf", 16.0, -1, -1, true, true, true);

void WatchEditorAndValues() {
    while (true) {
        yield();
        if (lastEditorOpen != (cast<CGameCtnEditorFree>(GetApp().Editor) !is null)) {
            lastEditorOpen = !lastEditorOpen;
            if (lastEditorOpen)
                // do this in a coro so we update vertex count first.
                startnew(Editor::Refresh);
        }
        if (lastEditorOpen) {
            auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
            if (editor.Challenge !is null) {
                if (S_AutoRefresh && editor.Challenge.VertexCount != lastVertexCount)
                    startnew(Editor::Refresh);
                lastVertexCount = editor.Challenge.VertexCount;
            }
        }
    }
}



void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}

// const string PluginIcon = Icons::Kenney::SortHorizontal;
const string PluginIcon = Icons::AngleDoubleRight;
const string MenuTitle = "\\$2bf" + PluginIcon + "\\$z " + Meta::ExecutingPlugin().Name;

// show the window immediately upon installation
[Setting hidden]
bool ShowWindow = true;

/** Render function called every frame intended only for menu items in `UI`. */
void RenderMenu() {
    if (UI::MenuItem(MenuTitle, "", ShowWindow)) {
        ShowWindow = !ShowWindow;
    }
}

float lastBtnWidth = 30;
void Render() {
    if (!ShowWindow) return;
    if (cast<CGameCtnEditorFree>(GetApp().Editor) is null) return;
    if (GetApp().CurrentPlayground !is null) return;
    int2 wh = int2(400, 600);
    // auto cond = UI::Cond::Appearing;
    auto cond = UI::Cond::FirstUseEver;
    UI::SetNextWindowSize(wh.x, wh.y, cond);
    UI::SetNextWindowPos(Draw::GetWidth() - wh.x * 5 / 4, (Draw::GetHeight() - wh.y) / 2, cond);
    UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
    UI::PushFont(largerFont);
    if (UI::Begin(MenuTitle, ShowWindow, UI::WindowFlags::None)) {
        UI::PushFont(regularFont);
        // UI::Columns(3, "", false);
        auto initPos = UI::GetCursorPos();
        auto width = UI::GetWindowContentRegionWidth();
        UI::BeginDisabled(Editor::refreshing);
        if (UI::Button(Icons::Refresh)) startnew(Editor::Refresh);
        UI::EndDisabled();
        if (!S_AutoRefresh && Editor::vCountAtRefresh != lastVertexCount) {
            UI::SameLine();
            UI::Text("\\$888Mb outdated.");
        }

        // UI::NextColumn();
        UI::SetCursorPos(initPos + vec2(width / 2. - 30. - lastBtnWidth / 2., 0));
        if (UI::Button(Icons::Kenney::Previous)) Editor::SelectPrevious();
        lastBtnWidth = UI::GetItemRect().z;
        UI::SetCursorPos(initPos + vec2(width / 2. + 30. - lastBtnWidth / 2., 0));
        // UI::SameLine();
        if (UI::Button(Icons::Kenney::Next)) Editor::SelectNext();
        if (UI::BeginChild("cp table child", UI::GetContentRegionAvail())) {
            if (UI::BeginTable("checkpoints table", 6, UI::TableFlags::SizingFixedFit)) {
                UI::TableSetupColumn("ix", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("blockOrItem", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("type", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("linked", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("target", UI::TableColumnFlags::WidthFixed);
                UI::ListClipper wpClip(Editor::Waypoints.Length);
                while (wpClip.Step()) {
                    for (int i = wpClip.DisplayStart; i < wpClip.DisplayEnd; i++) {
                        Editor::Waypoints[i].DrawTableRow(i);
                    }
                }
                UI::EndTable();
            }
        }
        UI::EndChild();
        UI::PopFont();
    }
    UI::End();
    UI::PopFont();
    UI::PopStyleVar();
}


void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(msg);
        UI::EndTooltip();
    }
}
