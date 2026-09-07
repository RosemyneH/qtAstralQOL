local Q = qtAstralQOL

local function EnsurePip(socket)
    if socket._qolPip then return socket._qolPip end
    local pip = socket:CreateTexture(nil, "OVERLAY")
    pip:SetSize(7, 7)
    pip:SetPoint("TOPRIGHT", 1, 1)
    pip:SetTexture("Interface\\Buttons\\WHITE8X8")
    socket._qolPip = pip
    return pip
end

function Q.PaintSockets(panel, source)
    if not (panel and panel.boxes) then return end
    source = source or {}
    local catalog = Q.Catalog()
    for schemaIdx = 1, 6 do
        local box = panel.boxes[schemaIdx]
        local schema = Q.SLOT_SCHEMA[schemaIdx]
        if box and box.sockets then
            for i, s in ipairs(box.sockets) do
                local data = source[schema.ord] and source[schema.ord][i - 1]
                local gemId = data and data.gemId
                local pip = EnsurePip(s)
                if gemId and gemId > 0 then
                    local cat = catalog[gemId]
                    local ev = (cat and tonumber(cat.eventType)) or 6
                    Q.SetGemIcon(s.icon, gemId)
                    local rgb = Q.EVENT_RGB[ev]
                    pip:SetVertexColor(rgb[1], rgb[2], rgb[3], 1)
                    pip:Show()
                else
                    if s.icon then s.icon:SetVertexColor(1, 1, 1, 1) end
                    pip:Hide()
                end
            end
        end
    end
end

local function Loadout()
    local PA = Q.PA()
    return (PA and PA.AstralGems and PA.AstralGems.loadout) or {}
end

local function InspectLoadout()
    local PA = Q.PA()
    return (PA and PA.AstralGems and PA.AstralGems.inspect) or {}
end

local function EquipSlotFor(ord)
    for _, sc in ipairs(Q.SLOT_SCHEMA) do
        if sc.ord == ord then return sc.equipSlot end
    end
end

local function UnsocketGem(equipSlot, idx)
    if _G.AIO and _G.AIO.Handle then
        _G.AIO.Handle("AstralgemServer", "Unsocket", equipSlot, idx)
    else
        SendChatMessage(string.format(".gem unsocket %d %d", equipSlot, idx), "SAY")
    end
end

local function BindSocket(s, readonly)
    s:HookScript("OnEnter", function(self)
        local src = readonly and InspectLoadout() or Loadout()
        local data = src[self._ord] and src[self._ord][self._idx]
        local gemId = data and data.gemId
        if gemId and gemId > 0 then
            local cat = Q.Cat(gemId)
            if cat then
                GameTooltip:AddLine(" ")
                Q.AddEventTooltip(cat.eventType)
                if cat.family and cat.family ~= "" and not readonly then
                    local n = Q.FamilyTierCount(cat.family, cat.tier)
                    GameTooltip:AddLine(string.format("Stash fusion: %d/3 (T%d %s)",
                        Q.FusionPips(n), cat.tier or 0, cat.family), 0.8, 0.85, 1)
                end
                GameTooltip:Show()
            end
        end
    end)
    if not readonly and not s._qolPickHook then
        s._qolPickHook = true
        s:HookScript("OnClick", function(self)
            local data = Loadout()[self._ord] and Loadout()[self._ord][self._idx]
            if data and data.gemId and data.gemId > 0 then return end
            if data and not data.active then return end
            local equip = EquipSlotFor(self._ord)
            if equip and Q.OpenGemPicker then
                Q.OpenGemPicker(equip, self._idx)
            end
        end)
    end
end

local function FillDockFromSource(dock, source)
    if not dock then return end
    source = source or {}
    for schemaIdx, schema in ipairs(Q.SLOT_SCHEMA) do
        local box = dock.boxes[schemaIdx]
        if box then
            for i, s in ipairs(box.sockets) do
                local data = source[schema.ord] and source[schema.ord][i - 1]
                    if data and data.gemId and data.gemId > 0 then
                    Q.SetGemIcon(s.icon, data.gemId)
                    s.icon:Show()
                else
                    s.icon:Hide()
                end
            end
        end
    end
    Q.PaintSockets(dock, source)
end

local function HookAstralPanel()
    local PA = Q.PA()
    local AG = PA and PA.AstralGems
    if not AG or AG._qolHooked then return end
    AG._qolHooked = true

    local origRenderTo = AG.RenderTo
    if origRenderTo then
        AG.RenderTo = function(panel, source)
            origRenderTo(panel, source)
            if panel and panel ~= Q.charDock and panel ~= Q.inspectDock then
                Q.PaintSockets(panel, source)
            end
        end
    end

    local origRender = AG.Render
    AG.Render = function()
        if origRender then origRender() end
        if AG.panel then
            Q.PaintSockets(AG.panel, AG.loadout)
            Q.EnhanceGemTab(AG.panel)
        end
        if AG.inspectFramePanel then
            Q.PaintSockets(AG.inspectFramePanel, AG.inspect)
        end
        if Q.charDock then FillDockFromSource(Q.charDock, AG.loadout) end
        if Q.inspectDock then FillDockFromSource(Q.inspectDock, AG.inspect) end
    end
end

function Q.EnhanceGemTab(panel)
    if not panel or panel._qolTab then return end
    panel._qolTab = true

    local dep = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    dep:SetSize(150, 22)
    dep:SetPoint("TOPLEFT", 16, -16)
    dep:SetText("Deposit All Gems")
    dep:SetScript("OnClick", Q.DepositAll)

    local legend = CreateFrame("Frame", nil, panel)
    legend:SetSize(220, 72)
    legend:SetPoint("TOPLEFT", dep, "BOTTOMLEFT", 0, -8)
    local ly = 0
    for _, ev in ipairs({ 0, 1, 2, 3 }) do
        local eventId = ev
        local btn = CreateFrame("Button", nil, legend)
        btn:SetSize(220, 14)
        btn:SetPoint("TOPLEFT", 0, ly)
        local line = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line:SetAllPoints()
        line:SetJustifyH("LEFT")
        local rgb = Q.EVENT_RGB[eventId]
        line:SetTextColor(rgb[1], rgb[2], rgb[3])
        line:SetText("Proc on " .. Q.EVENT_NAME[eventId])
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            Q.AddEventTooltip(eventId)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", GameTooltip_Hide)
        ly = ly - 14
    end

    if panel.boxes then
        for _, box in pairs(panel.boxes) do
            if box.sockets then
                for _, s in ipairs(box.sockets) do
                    BindSocket(s, s._readonly)
                end
            end
        end
    end
end

local function MakeMiniSocket(parent, ord, idx, size, readonly)
    local s = CreateFrame("Button", nil, parent)
    s:SetSize(size, size)
    s._ord, s._idx = ord, idx
    s._readonly = readonly

    local ring = s:CreateTexture(nil, "BORDER")
    ring:SetAllPoints()
    ring:SetTexture("Interface\\Buttons\\WHITE8X8")
    ring:SetVertexColor(0.15, 0.18, 0.28, 0.95)
    s.ring = ring

    local icon = s:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    s.icon = icon
    icon:Hide()

    s:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local src = readonly and InspectLoadout() or Loadout()
        local data = src[self._ord] and src[self._ord][self._idx]
        if data and data.gemId and data.gemId > 0 then
            GameTooltip:SetHyperlink("item:" .. data.gemId)
            local cat = Q.Cat(data.gemId)
            if cat then
                GameTooltip:AddLine(" ")
                Q.AddEventTooltip(cat.eventType)
            end
            if not data.active then
                GameTooltip:AddLine("Inactive — item quality too low.", 1, 0.4, 0.4)
            end
        else
            GameTooltip:AddLine(readonly and "Empty" or "Empty — click to socket", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    s:SetScript("OnLeave", GameTooltip_Hide)

    if not readonly then
        s:SetScript("OnClick", function(self)
            local data = Loadout()[self._ord] and Loadout()[self._ord][self._idx]
            local schema
            for _, sc in ipairs(Q.SLOT_SCHEMA) do
                if sc.ord == self._ord then schema = sc break end
            end
            if not schema then return end
            if data and data.gemId and data.gemId > 0 then
                UnsocketGem(schema.equipSlot, self._idx)
            else
                if data and not data.active then
                    UIErrorsFrame:AddMessage("Slot inactive — item quality too low.", 1, 0.5, 0.5, 53, 4)
                    return
                end
                Q.OpenGemPicker(schema.equipSlot, self._idx)
            end
        end)
    end
    return s
end

local function BuildDock(parent, name, readonly)
    local dock = CreateFrame("Frame", name, parent)
    dock:SetWidth(108)
    dock:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    dock:SetBackdropColor(0.04, 0.05, 0.10, 0.92)
    dock:SetBackdropBorderColor(0.32, 0.42, 0.70, 1)
    dock.boxes = {}

    local title = dock:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", 0, -5)
    title:SetText(readonly and "Gems" or "Astral Gems")
    dock.title = title

    local help = CreateFrame("Button", nil, dock)
    help:SetSize(100, 14)
    help:SetPoint("TOP", title, "TOP", 0, 0)
    help:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Astral gem procs", 1, 0.82, 0)
        for _, ev in ipairs({ 0, 1, 2, 3 }) do
            Q.AddEventTooltip(ev)
            GameTooltip:AddLine(" ")
        end
        GameTooltip:Show()
    end)
    help:SetScript("OnLeave", GameTooltip_Hide)

    local y = -18
    local size, gap, rowH = 18, 1, 20
    for schemaIdx, schema in ipairs(Q.SLOT_SCHEMA) do
        local box = CreateFrame("Frame", nil, dock)
        box.sockets = {}
        box:SetSize(100, rowH)
        box:SetPoint("TOP", 0, y)
        local lbl = box:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        lbl:SetPoint("LEFT", 4, 0)
        lbl:SetWidth(34)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(schema.label)
        for i = 1, schema.n do
            local s = MakeMiniSocket(box, schema.ord, i - 1, size, readonly)
            s:SetPoint("LEFT", 38 + (i - 1) * (size + gap), 0)
            box.sockets[i] = s
        end
        dock.boxes[schemaIdx] = box
        y = y - rowH
    end

    if not readonly then
        local dep = CreateFrame("Button", nil, dock, "UIPanelButtonTemplate")
        dep:SetSize(96, 18)
        dep:SetPoint("BOTTOM", 0, 4)
        dep:SetText("Deposit All")
        dep:SetScript("OnClick", Q.DepositAll)
        y = y - 22
    end

    dock:SetHeight(math.abs(y) + 8)
    return dock
end

function Q.RefreshCharDock()
    local dock = Q.charDock
    if not dock then return end
    if Q.DB().charDock and CharacterFrame and CharacterFrame:IsShown() then
        dock:Show()
        FillDockFromSource(dock, Loadout())
    else
        dock:Hide()
    end
end

local function AttachCharDock()
    if Q.charDock or not CharacterFrame then return end
    local dock = BuildDock(CharacterFrame, "qtAstralQOL_CharGems", false)
    dock:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", -20, -12)
    Q.charDock = dock
    CharacterFrame:HookScript("OnShow", function()
        Q.RequestGemData()
        Q.RefreshCharDock()
    end)
    CharacterFrame:HookScript("OnHide", function()
        if Q.charDock then Q.charDock:Hide() end
    end)
    Q.RefreshCharDock()
end

local function RequestInspect(name)
    if not name or name == "" then return end
    if _G.AIO and _G.AIO.Handle then
        _G.AIO.Handle("AstralgemServer", "RequestInspect", name)
    else
        SendChatMessage(".gem inspect " .. name, "SAY")
    end
end

local function AttachInspectDock()
    if Q.inspectDock or not InspectFrame then return end
    local dock = BuildDock(InspectFrame, "qtAstralQOL_InspectGems", true)
    dock:SetPoint("TOPLEFT", InspectFrame, "TOPRIGHT", -20, -12)
    Q.inspectDock = dock
    dock:Hide()

    InspectFrame:HookScript("OnShow", function()
        if not Q.DB().inspectTab then return end
        dock:Show()
        local unit = InspectFrame.unit or "target"
        local name = UnitName(unit)
        dock.title:SetText((name or "Inspect") .. " Gems")
        RequestInspect(name)
        FillDockFromSource(dock, InspectLoadout())
    end)
    InspectFrame:HookScript("OnHide", function()
        dock:Hide()
    end)
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_InspectUI" then
            AttachInspectDock()
        end
        return
    end
    Q.DB()
    HookAstralPanel()
    AttachCharDock()
    local origAstral = SlashCmdList["ASTRAL"]
    SlashCmdList["ASTRAL"] = function(msg)
        local m = (msg or ""):lower()
        if m:find("gem", 1, true) then
            SlashCmdList["QTASTRALQOL"]("")
            return
        end
        if origAstral then origAstral(msg) end
    end
    if IsAddOnLoaded("Blizzard_InspectUI") then
        AttachInspectDock()
    end
    Q.RequestGemData()
    local acc = 0
    boot:SetScript("OnUpdate", function(self, dt)
        acc = acc + dt
        HookAstralPanel()
        if Q.StealStockPicker then Q.StealStockPicker() end
        local PA = Q.PA()
        if PA and PA.AstralGems and PA.AstralGems.panel then
            Q.EnhanceGemTab(PA.AstralGems.panel)
        end
        if acc > 8 then self:SetScript("OnUpdate", nil) end
    end)

    local PA = Q.PA()
    if PA and PA.GemStash and PA.GemStash.Refresh and not PA.GemStash._qolIconHook then
        PA.GemStash._qolIconHook = true
        local orig = PA.GemStash.Refresh
        PA.GemStash.Refresh = function(...)
            orig(...)
            local f = _G.PA_GemStashFrame
            if not (f and f.rows) then return end
            for _, row in ipairs(f.rows) do
                if row:IsShown() and row.entry then
                    local tex = row.icon or (row.iconFrame and row.iconFrame.icon)
                    Q.SetGemIcon(tex, row.entry)
                end
            end
        end
    end
end)
