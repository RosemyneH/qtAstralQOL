local Q = qtAstralQOL

local ROW_H = 22
local hookedImport = false
local gearSetItems = {}

local function SkipMap()
    local db = Q.DB()
    if type(db.extractSkip) ~= "table" then db.extractSkip = {} end
    return db.extractSkip
end

local function Presets()
    local db = Q.DB()
    if type(db.extractPresets) ~= "table" then db.extractPresets = {} end
    return db.extractPresets
end

function Q.RefreshEquipmentSetSkip()
    for id in pairs(gearSetItems) do gearSetItems[id] = nil end
    if type(GetNumEquipmentSets) ~= "function" or type(GetEquipmentSetItemIDs) ~= "function" then return end
    for i = 1, GetNumEquipmentSets() do
        local name = GetEquipmentSetInfo(i)
        if name then
            local ids = GetEquipmentSetItemIDs(name)
            if ids then
                for _, itemId in pairs(ids) do
                    itemId = tonumber(itemId)
                    if itemId and itemId > 0 then gearSetItems[itemId] = true end
                end
            end
        end
    end
end

function Q.IsExtractSkipped(itemId)
    itemId = tonumber(itemId)
    if not itemId then return false end
    if SkipMap()[itemId] then return true end
    if Q.DB().extractSkipGearSets and gearSetItems[itemId] then return true end
    return false
end

local pendingAnchor
local openWait

local function PresentAstralDisenchant()
    local f = _G.ProjectAstralAstralDisenchant
    if not f then return false end
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    local anchor = pendingAnchor
    if type(anchor) == "table" and anchor.IsShown and anchor:IsShown() then
        f:ClearAllPoints()
        f:SetPoint("LEFT", anchor, "RIGHT", 12, 0)
    end
    f:Show()
    f:Raise()
    if not f._qolRaiseHook then
        f._qolRaiseHook = true
        f:HookScript("OnShow", function(self)
            self:SetFrameStrata("FULLSCREEN_DIALOG")
            self:Raise()
        end)
    end
    return true
end

function Q.ToggleAstralDisenchant(anchor)
    local f = _G.ProjectAstralAstralDisenchant
    if f and f:IsShown() then
        f:Hide()
        if openWait then openWait:SetScript("OnUpdate", nil) end
        return
    end
    Q.OpenAstralDisenchant(anchor)
end

function Q.OpenAstralDisenchant(anchor)
    pendingAnchor = anchor
    local PA = Q.PA()
    if PA and PA.disenchant and PA.disenchant.Open then
        PA.disenchant.Open()
    end
    if _G.AIO and _G.AIO.Handle then
        _G.AIO.Handle("AstralDisenchantServer", "Open")
    end
    if PresentAstralDisenchant() then return end
    if openWait then openWait:SetScript("OnUpdate", nil) end
    openWait = CreateFrame("Frame")
    local t = 0
    openWait:SetScript("OnUpdate", function(self, dt)
        t = t + dt
        if PresentAstralDisenchant() or t > 4 then
            self:SetScript("OnUpdate", nil)
        end
    end)
end

local function ItemIdFromLink(link)
    if not link then return nil end
    return tonumber(tostring(link):match("item:(%d+)"))
end

local function CursorItemId()
    local typ, id, link = GetCursorInfo()
    if typ == "item" then
        return tonumber(id) or ItemIdFromLink(link)
    end
end

local function AddSkip(itemId)
    itemId = tonumber(itemId)
    if not itemId then return end
    SkipMap()[itemId] = true
    if GetItemInfo then GetItemInfo(itemId) end
end

local function RemoveSkip(itemId)
    SkipMap()[tonumber(itemId) or 0] = nil
end

local function SortedIds()
    local ids = {}
    for id in pairs(SkipMap()) do
        ids[#ids + 1] = tonumber(id)
    end
    table.sort(ids)
    return ids
end

local pop
local rows = {}

local function RefreshSkipList()
    if not pop then return end
    local ids = SortedIds()
    local n = math.max(#ids, 1)
    for i = 1, math.max(n, #rows) do
        local r = rows[i]
        if not r then
            r = CreateFrame("Button", nil, pop.list)
            r:SetHeight(ROW_H)
            r:SetPoint("LEFT", 4, 0)
            r:SetPoint("RIGHT", -4, 0)
            if i == 1 then
                r:SetPoint("TOP", pop.list, "TOP", 0, 0)
            else
                r:SetPoint("TOP", rows[i - 1], "BOTTOM", 0, 0)
            end
            r.icon = r:CreateTexture(nil, "ARTWORK")
            r.icon:SetSize(18, 18)
            r.icon:SetPoint("LEFT", 2, 0)
            r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
            r.name:SetPoint("RIGHT", -4, 0)
            r.name:SetJustifyH("LEFT")
            r:SetScript("OnEnter", function(self)
                if not self._id then return end
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetHyperlink("item:" .. self._id)
                GameTooltip:AddLine("Click to remove from skip list.", 0.7, 0.8, 1, true)
                GameTooltip:Show()
            end)
            r:SetScript("OnLeave", GameTooltip_Hide)
            r:SetScript("OnClick", function(self)
                if self._id then
                    RemoveSkip(self._id)
                    RefreshSkipList()
                end
            end)
            rows[i] = r
        end
        local id = ids[i]
        if id then
            r._id = id
            local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(id)
            r.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
            r.name:SetText(name or ("Item " .. id))
            r:Show()
        else
            r._id = nil
            r:Hide()
        end
    end
    pop.list:SetHeight(math.max(#ids, 1) * ROW_H)
    local db = Q.DB()
    if pop.preset then
        pop.preset:SetText(db.extractPreset or "")
    end
    if pop.count then
        local n = #ids
        local gear = 0
        if Q.DB().extractSkipGearSets then
            for id in pairs(gearSetItems) do gear = gear + 1 end
        end
        if gear > 0 then
            pop.count:SetText(n .. " skipped  ·  " .. gear .. " from gear sets")
        else
            pop.count:SetText(n .. " skipped")
        end
    end
    if pop.gearChk then
        pop.gearChk:SetChecked(Q.DB().extractSkipGearSets and true or false)
    end
end

local function SavePreset()
    local name = pop.preset:GetText() or ""
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        UIErrorsFrame:AddMessage("Name the skip preset first.", 1, 0.8, 0.3, 1)
        return
    end
    local copy = {}
    for id in pairs(SkipMap()) do
        copy[#copy + 1] = tonumber(id)
    end
    Presets()[name] = copy
    Q.DB().extractPreset = name
    UIErrorsFrame:AddMessage("Saved skip preset: " .. name, 0.5, 1, 0.6, 1)
    RefreshSkipList()
end

local function LoadPreset()
    local name = pop.preset:GetText() or ""
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    local list = Presets()[name]
    if not list then
        UIErrorsFrame:AddMessage("No skip preset named " .. (name ~= "" and name or "(blank)"), 1, 0.5, 0.4, 1)
        return
    end
    local map = SkipMap()
    for k in pairs(map) do map[k] = nil end
    for i = 1, #list do
        local id = tonumber(list[i])
        if id then map[id] = true end
    end
    Q.DB().extractPreset = name
    RefreshSkipList()
end

local function DeletePreset()
    local name = pop.preset:GetText() or ""
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" or not Presets()[name] then return end
    Presets()[name] = nil
    if Q.DB().extractPreset == name then Q.DB().extractPreset = "" end
    RefreshSkipList()
end

local function CyclePreset(dir)
    local names = {}
    for n in pairs(Presets()) do names[#names + 1] = n end
    table.sort(names)
    if #names == 0 then return end
    local cur = Q.DB().extractPreset or ""
    local idx = 1
    for i = 1, #names do
        if names[i] == cur then idx = i break end
    end
    idx = idx + dir
    if idx < 1 then idx = #names end
    if idx > #names then idx = 1 end
    pop.preset:SetText(names[idx])
    LoadPreset()
end

local function BuildPopup(parent)
    if pop then return pop end
    pop = CreateFrame("Frame", "qtAstralQOL_ExtractSkip", parent)
    pop:SetSize(220, 342)
    pop:SetPoint("TOPLEFT", parent, "TOPRIGHT", 8, 0)
    pop:SetFrameStrata("HIGH")
    pop:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    pop:Hide()
    pop:EnableMouse(true)
    pop:SetScript("OnShow", function()
        Q.RefreshEquipmentSetSkip()
        RefreshSkipList()
    end)
    pop:SetScript("OnReceiveDrag", function()
        local id = CursorItemId()
        if id then
            AddSkip(id)
            ClearCursor()
            RefreshSkipList()
        end
    end)
    pop:SetScript("OnMouseUp", function()
        local id = CursorItemId()
        if id then
            AddSkip(id)
            ClearCursor()
            RefreshSkipList()
        end
    end)

    local title = pop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -16)
    title:SetText("Skip on Import")

    local hint = pop:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOP", title, "BOTTOM", 0, -4)
    hint:SetWidth(180)
    hint:SetText("Drop or shift-click an item to skip it. Click a row to remove.")
    hint:SetTextColor(0.7, 0.78, 0.9)

    pop.count = pop:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    pop.count:SetPoint("TOP", hint, "BOTTOM", 0, -6)

    pop.gearChk = CreateFrame("CheckButton", nil, pop, "UICheckButtonTemplate")
    pop.gearChk:SetPoint("TOPLEFT", pop.count, "BOTTOMLEFT", -4, -2)
    pop.gearChk:SetScale(0.72)
    local gearLbl = pop:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    gearLbl:SetPoint("LEFT", pop.gearChk, "RIGHT", 0, 0)
    gearLbl:SetText("Skip equipment set items")
    gearLbl:SetTextColor(0.82, 0.90, 0.98)
    pop.gearChk:SetScript("OnClick", function(self)
        Q.DB().extractSkipGearSets = self:GetChecked() and true or false
        RefreshSkipList()
    end)
    pop.gearChk:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Equipment sets")
        GameTooltip:AddLine("Items saved in any equipment manager set are not auto-imported.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    pop.gearChk:SetScript("OnLeave", GameTooltip_Hide)

    local sf = CreateFrame("ScrollFrame", "qtAstralQOL_ExtractSkipScroll", pop, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 16, -98)
    sf:SetPoint("BOTTOMRIGHT", -36, 78)
    pop.list = CreateFrame("Frame", nil, sf)
    pop.list:SetWidth(160)
    pop.list:SetHeight(ROW_H)
    sf:SetScrollChild(pop.list)

    pop.preset = CreateFrame("EditBox", "qtAstralQOL_ExtractPreset", pop, "InputBoxTemplate")
    pop.preset:SetSize(120, 20)
    pop.preset:SetPoint("BOTTOMLEFT", 20, 48)
    pop.preset:SetAutoFocus(false)
    pop.preset:SetMaxLetters(24)

    local prev = CreateFrame("Button", nil, pop, "UIPanelButtonTemplate")
    prev:SetSize(22, 20)
    prev:SetPoint("LEFT", pop.preset, "RIGHT", 4, 0)
    prev:SetText("<")
    prev:SetScript("OnClick", function() CyclePreset(-1) end)

    local nxt = CreateFrame("Button", nil, pop, "UIPanelButtonTemplate")
    nxt:SetSize(22, 20)
    nxt:SetPoint("LEFT", prev, "RIGHT", 2, 0)
    nxt:SetText(">")
    nxt:SetScript("OnClick", function() CyclePreset(1) end)

    local save = CreateFrame("Button", nil, pop, "UIPanelButtonTemplate")
    save:SetSize(52, 20)
    save:SetPoint("BOTTOMLEFT", 18, 18)
    save:SetText("Save")
    save:SetScript("OnClick", SavePreset)

    local load = CreateFrame("Button", nil, pop, "UIPanelButtonTemplate")
    load:SetSize(52, 20)
    load:SetPoint("LEFT", save, "RIGHT", 4, 0)
    load:SetText("Load")
    load:SetScript("OnClick", LoadPreset)

    local del = CreateFrame("Button", nil, pop, "UIPanelButtonTemplate")
    del:SetSize(52, 20)
    del:SetPoint("LEFT", load, "RIGHT", 4, 0)
    del:SetText("Del")
    del:SetScript("OnClick", DeletePreset)

    return pop
end

local function HookShiftClick(frame)
    if frame._qolSkipShift then return end
    frame._qolSkipShift = true
    hooksecurefunc("PickupContainerItem", function(bag, slot)
        if not pop or not pop:IsShown() then return end
        if not IsShiftKeyDown() then return end
        local id = GetContainerItemID and GetContainerItemID(bag, slot)
        if not id then id = ItemIdFromLink(GetContainerItemLink(bag, slot)) end
        if id then
            AddSkip(id)
            ClearCursor()
            RefreshSkipList()
        end
    end)
end

local function WrapImport(frame)
    if hookedImport or not frame.importBtn then return end
    hookedImport = true
    local orig = frame.importBtn:GetScript("OnClick")
    if not orig then return end
    frame.importBtn:SetScript("OnClick", function(self, ...)
        Q.RefreshEquipmentSetSkip()
        local real = GetContainerItemID
        GetContainerItemID = function(bag, slot)
            local id
            if real then id = real(bag, slot) end
            if not id then id = ItemIdFromLink(GetContainerItemLink(bag, slot)) end
            if id and Q.IsExtractSkipped(id) then return nil end
            return id
        end
        orig(self, ...)
        GetContainerItemID = real
    end)
end

function Q.HookExtract(frame)
    if not frame then return end
    WrapImport(frame)
    HookShiftClick(frame)
    if frame.qolSkipBtn then return end

    local btn = CreateFrame("Button", "qtAstralQOL_ExtractSkipBtn", frame, "UIPanelButtonTemplate")
    btn:SetSize(160, 28)
    btn:SetText("Skip list")
    local PA = Q.PA()
    if PA and PA.UI and PA.UI.CosmicButton then
        PA.UI.CosmicButton(btn)
    end
    btn:SetScript("OnClick", function()
        local p = BuildPopup(frame)
        if p:IsShown() then p:Hide() else p:Show() end
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Skip list")
        GameTooltip:AddLine("Items on this list are not Auto Imported into gem extraction. Equipment set items can be auto-skipped. Save named presets and cycle them with < >.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)
    frame.qolSkipBtn = btn
    if Q.LayoutAstralTableButtons then Q.LayoutAstralTableButtons(frame) end
end

local gearBoot = CreateFrame("Frame")
gearBoot:RegisterEvent("PLAYER_LOGIN")
gearBoot:RegisterEvent("EQUIPMENT_SETS_CHANGED")
gearBoot:SetScript("OnEvent", function()
    Q.RefreshEquipmentSetSkip()
end)
