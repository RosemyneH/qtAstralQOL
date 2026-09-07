local Q = qtAstralQOL

local function EnsurePip(socket)
    if socket._qolPip then return socket._qolPip end
    local pip = socket:CreateTexture(nil, "OVERLAY")
    pip:SetSize(socket._pipSize or 7, socket._pipSize or 7)
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

local SOCK, SOCK_GAP, ROW_GAP = 18, 2, 3

local function QualityUnlocks(schema, idx, unit)
    if not unit then return false end
    local need = schema.colors and schema.colors[idx + 1]
    if not need then return false end
    local q = GetInventoryItemQuality(unit, schema.invSlot)
    return q and q >= need
end

-- ʕ •ᴥ•ʔ✿ empty sockets stay hidden until the equipped item actually unlocks them ✿ ʕ •ᴥ•ʔ
local function SocketOpen(schema, idx, source, unit)
    local slot = source and source[schema.ord]
    if slot then
        local data = slot[idx]
        if not data then return false end
        if data.gemId and data.gemId > 0 then return true end
        return data.active and true or false
    end
    return QualityUnlocks(schema, idx, unit)
end

local function PaintSocketChrome(s, color)
    local rgb = Q.QUALITY_RGB[color] or Q.QUALITY_RGB[3]
    s._qr = rgb
    if s.ring then s.ring:SetVertexColor(rgb[1], rgb[2], rgb[3], 0.95) end
end

local function SchemaByOrd(ord)
    for _, sc in ipairs(Q.SLOT_SCHEMA) do
        if sc.ord == ord then return sc end
    end
end

local function DockAnchor(dock)
    local a = dock.anchor and _G[dock.anchor]
    if a then return a end
    return dock.fallback and _G[dock.fallback]
end

local function FillDockFromSource(dock, source)
    if not dock then return end
    source = source or {}
    local unit = dock.unit
    local prev, maxW, height = nil, SOCK, 0

    for schemaIdx, schema in ipairs(Q.SLOT_SCHEMA) do
        local box = dock.boxes[schemaIdx]
        if box then
            local vis = {}
            for i, s in ipairs(box.sockets) do
                local idx = i - 1
                local data = source[schema.ord] and source[schema.ord][idx]
                if SocketOpen(schema, idx, source, unit) then
                    vis[#vis + 1] = s
                    if data and data.gemId and data.gemId > 0 then
                        Q.SetGemIcon(s.icon, data.gemId)
                        s.icon:Show()
                        if s.inner then s.inner:Hide() end
                    else
                        s.icon:Hide()
                        if s.inner then s.inner:Show() end
                    end
                    PaintSocketChrome(s, schema.colors and schema.colors[i])
                else
                    s:Hide()
                end
            end

            if #vis == 0 then
                box:Hide()
            else
                local w = #vis * (SOCK + SOCK_GAP) - SOCK_GAP
                box:Show()
                box:ClearAllPoints()
                if prev then
                    box:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -ROW_GAP)
                    height = height + ROW_GAP
                else
                    box:SetPoint("TOPLEFT", dock, "TOPLEFT", 0, 0)
                end
                for i, s in ipairs(vis) do
                    s:ClearAllPoints()
                    s:SetPoint("LEFT", box, (i - 1) * (SOCK + SOCK_GAP), 0)
                    s:Show()
                end
                box:SetSize(w, SOCK)
                if w > maxW then maxW = w end
                height = height + SOCK
                prev = box
            end
        end
    end

    local anchor = DockAnchor(dock)
    dock:ClearAllPoints()
    if anchor then
        dock:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
        dock:SetFrameLevel((anchor:GetFrameLevel() or 1) + 8)
    else
        dock:SetPoint("TOPLEFT", dock:GetParent(), "TOPLEFT", 16, -80)
    end
    dock:SetSize(maxW, math.max(height, 1))

    Q.PaintSockets(dock, source)
    for schemaIdx, schema in ipairs(Q.SLOT_SCHEMA) do
        local box = dock.boxes[schemaIdx]
        if box then
            for i, s in ipairs(box.sockets) do
                local data = source[schema.ord] and source[schema.ord][i - 1]
                if s.icon and s.icon:IsShown() and data and data.active == false then
                    s.icon:SetVertexColor(0.45, 0.45, 0.45, 1)
                end
            end
        end
    end
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
    if not panel then return end
    if not panel._qolTab then
        panel._qolTab = true

        local dep = CreateFrame("Button", "qtAstralQOL_GemDeposit", panel, "UIPanelButtonTemplate")
        dep:SetSize(150, 22)
        dep:SetPoint("TOPLEFT", 16, -16)
        dep:SetText("Deposit All Gems")
        dep:SetScript("OnClick", Q.DepositAll)
        dep:SetFrameLevel(panel:GetFrameLevel() + 8)

        local legend = CreateFrame("Frame", nil, panel)
        panel._qolDeposit = dep
        panel._qolLegend = legend
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
    if Q.AttachLoadoutUI then Q.AttachLoadoutUI(panel) end
    Q.LayoutGemTab(panel)
end

-- ʕ •ᴥ•ʔ✿ left column: equipped list + loadouts, sockets keep the right ✿ ʕ •ᴥ•ʔ
function Q.LayoutGemTab(panel)
    if not panel then return end
    local list = panel.equippedList
    local bar = panel._qolLoadoutBar
    local legend = panel._qolLegend
    local topInset = 108
    if legend then
        local depH = (panel._qolDeposit and panel._qolDeposit:GetHeight()) or 22
        topInset = 16 + depH + 8 + (legend:GetHeight() or 72) + 10
    end

    if list then
        list:ClearAllPoints()
        list:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -topInset)
        local ph = panel:GetHeight() or 0
        if ph < 80 then ph = 564 end
        local listH = ph - topInset - 8 - 58 - 12
        if listH < 220 then listH = 220 end
        list:SetSize(240, listH)
    end

    if bar then
        bar:ClearAllPoints()
        if list then
            bar:SetWidth(240)
            bar:SetPoint("TOPLEFT", list, "BOTTOMLEFT", 0, -8)
        else
            bar:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 22, 12)
        end
    end
end

local function MakeMiniSocket(parent, ord, idx, size, readonly, color)
    local s = CreateFrame("Button", nil, parent)
    s:SetSize(size, size)
    s._ord, s._idx, s._color = ord, idx, color
    s._readonly = readonly

    local ring = s:CreateTexture(nil, "BORDER")
    ring:SetAllPoints()
    ring:SetTexture("Interface\\Buttons\\WHITE8X8")
    s.ring = ring

    local inner = s:CreateTexture(nil, "ARTWORK")
    inner:SetPoint("TOPLEFT", 1, -1)
    inner:SetPoint("BOTTOMRIGHT", -1, 1)
    inner:SetTexture("Interface\\Buttons\\WHITE8X8")
    inner:SetVertexColor(0.06, 0.07, 0.11, 1)
    s.inner = inner

    local icon = s:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetDrawLayer("ARTWORK", 1)
    s.icon = icon
    icon:Hide()

    PaintSocketChrome(s, color)

    s:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local src = readonly and InspectLoadout() or Loadout()
        local data = src[self._ord] and src[self._ord][self._idx]
        local schema = SchemaByOrd(self._ord)
        local qName = Q.QUALITY_NAME[self._color] or "Gem"
        local rgb = Q.QUALITY_RGB[self._color] or Q.QUALITY_RGB[3]
        local slotLine = (schema and schema.label or "Gem") .. " — " .. qName .. " socket"
        if data and data.gemId and data.gemId > 0 then
            GameTooltip:SetHyperlink("item:" .. data.gemId)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(slotLine, rgb[1], rgb[2], rgb[3])
            local cat = Q.Cat(data.gemId)
            if cat then
                Q.AddEventTooltip(cat.eventType)
            end
            if not data.active then
                GameTooltip:AddLine("Inactive — item quality too low.", 1, 0.4, 0.4)
            end
        else
            GameTooltip:AddLine(slotLine, rgb[1], rgb[2], rgb[3])
            GameTooltip:AddLine(readonly and "Empty" or "Empty — click to socket", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    s:SetScript("OnLeave", GameTooltip_Hide)

    if not readonly then
        s:SetScript("OnClick", function(self)
            local data = Loadout()[self._ord] and Loadout()[self._ord][self._idx]
            local schema = SchemaByOrd(self._ord)
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

local function BuildDock(parent, name, readonly, anchor, fallback)
    local dock = CreateFrame("Frame", name, parent)
    dock:SetSize(1, 1)
    dock:EnableMouse(false)
    dock.boxes = {}
    dock.readonly = readonly
    dock.anchor = anchor
    dock.fallback = fallback

    for schemaIdx, schema in ipairs(Q.SLOT_SCHEMA) do
        local box = CreateFrame("Frame", nil, dock)
        box:EnableMouse(false)
        box.sockets = {}
        for i = 1, schema.n do
            local color = schema.colors and schema.colors[i] or 3
            local s = MakeMiniSocket(box, schema.ord, i - 1, SOCK, readonly, color)
            s._pipSize = 5
            box.sockets[i] = s
        end
        dock.boxes[schemaIdx] = box
    end
    return dock
end

function Q.RefreshCharDock()
    local dock = Q.charDock
    if not dock then return end
    local host = dock:GetParent()
    if Q.DB().charDock and host and host:IsShown() then
        dock:Show()
        FillDockFromSource(dock, Loadout())
    else
        dock:Hide()
    end
end

local function AttachCharDock()
    if Q.charDock or not CharacterFrame then return end
    local host = _G.PaperDollFrame or CharacterFrame
    local dock = BuildDock(host, "qtAstralQOL_CharGems", false,
        "CharacterModelFrameRotateLeftButton", "CharacterModelFrame")
    dock.unit = "player"
    Q.charDock = dock
    CharacterFrame:HookScript("OnShow", function()
        Q.RequestGemData()
        Q.RefreshCharDock()
    end)
    if host ~= CharacterFrame then
        host:HookScript("OnShow", Q.RefreshCharDock)
    end
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
    local host = _G.InspectPaperDollFrame or InspectFrame
    local dock = BuildDock(host, "qtAstralQOL_InspectGems", true,
        "InspectModelRotateLeftButton", "InspectModelFrame")
    Q.inspectDock = dock
    dock:Hide()

    InspectFrame:HookScript("OnShow", function()
        if not Q.DB().inspectTab then return end
        dock:Show()
        dock.unit = InspectFrame.unit or "target"
        RequestInspect(UnitName(dock.unit))
        FillDockFromSource(dock, InspectLoadout())
    end)
    InspectFrame:HookScript("OnHide", function()
        dock:Hide()
    end)
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("UNIT_INVENTORY_CHANGED")
boot:SetScript("OnEvent", function(_, event, arg1)
    if event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" then Q.RefreshCharDock() end
        return
    end
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
        local panel = PA and PA.AstralGems and PA.AstralGems.panel
        if panel then
            Q.EnhanceGemTab(panel)
            if not panel._qolShowLoadout then
                panel._qolShowLoadout = true
                panel:HookScript("OnShow", function(p)
                    Q.EnhanceGemTab(p)
                end)
            end
        end
        if acc > 30 and panel and panel._qolLoadout then
            self:SetScript("OnUpdate", nil)
        end
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
