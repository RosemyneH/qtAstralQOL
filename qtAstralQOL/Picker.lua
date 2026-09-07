local Q = qtAstralQOL

local picker
local pickerCtx
local searchText = ""
local filterEvent = -1
local filterTier  = 0

local ROW_H = 52
local ROW_W = 390

local function ActiveFamilies()
    local active = {}
    local PA = Q.PA()
    local loadout = PA and PA.AstralGems and PA.AstralGems.loadout or {}
    local catalog = Q.Catalog()
    for ord = 0, 5 do
        local slot = loadout[ord]
        if slot then
            for idx = 0, 3 do
                local data = slot[idx]
                local id = data and data.gemId
                if id and id > 0 then
                    local cat = catalog[id]
                    if cat and cat.family and cat.family ~= "" then
                        active[cat.family] = true
                    end
                end
            end
        end
    end
    return active
end

local function CollectRows()
    local stock = Q.Stock()
    local catalog = Q.Catalog()
    local catalogReady = next(catalog) ~= nil
    local used = ActiveFamilies()
    local q = searchText:lower()
    local out = {}

    for entry, count in pairs(stock) do
        if count and count > 0 and entry ~= 99998 and entry ~= 99999 then
            local cat = catalog[entry]
            if not catalogReady or cat then
                local family = cat and cat.family or ""
                if family == "" or not used[family] then
                    local ev = cat and tonumber(cat.eventType) or 6
                    local tier = cat and cat.tier or 0
                    local passEvt  = (filterEvent < 0) or (ev == filterEvent)
                    local passTier = (filterTier == 0) or (tier == filterTier)
                    local short = Q.GemShortName(entry)
                    local hay = (short .. " " .. tostring(family) .. " t" .. tostring(tier) .. " " ..
                        (Q.EVENT_NAME[ev] or "") .. " " .. (select(1, GetItemInfo(entry)) or "")):lower()
                    local passQ = (q == "") or hay:find(q, 1, true)
                    if passEvt and passTier and passQ then
                        out[#out + 1] = {
                            entry = entry, count = count, cat = cat,
                            short = short, ev = ev, tier = tier, family = family,
                        }
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if a.tier ~= b.tier then return a.tier > b.tier end
        if a.ev ~= b.ev then return a.ev < b.ev end
        return (a.short or "") < (b.short or "")
    end)
    return out
end

local function SetFusionBar(r, gem)
    local cat = gem.cat
    local maxed = (not cat) or cat.isMythic or (gem.tier or 0) >= 8
    if maxed then
        r.bar:SetValue(0)
        r.bar:SetStatusBarColor(0.25, 0.25, 0.3, 0.8)
        r.barText:SetText((cat and cat.isMythic) and "Mythic" or "Max tier")
        return
    end
    local total = Q.FamilyTierCount(gem.family, gem.tier)
    local filled = Q.FusionPips(total)
    r.bar:SetMinMaxValues(0, 3)
    r.bar:SetValue(filled)
    local rgb = Q.EVENT_RGB[gem.ev] or Q.EVENT_RGB[6]
    r.bar:SetStatusBarColor(rgb[1], rgb[2], rgb[3], 1)
    if filled >= 3 then
        r.barText:SetText("3/3  fuse to T" .. (gem.tier + 1))
    else
        r.barText:SetText(filled .. "/3  to T" .. (gem.tier + 1))
    end
end

local function MakeRow(parent, i)
    local r = CreateFrame("Button", nil, parent)
    r:SetSize(ROW_W, ROW_H - 3)

    local bg = r:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.07, 0.09, 0.14, 0.72)
    r.bg = bg
    r:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")

    local stripe = r:CreateTexture(nil, "ARTWORK")
    stripe:SetWidth(4)
    stripe:SetPoint("TOPLEFT", 0, 0)
    stripe:SetPoint("BOTTOMLEFT", 0, 0)
    stripe:SetTexture("Interface\\Buttons\\WHITE8X8")
    r.stripe = stripe

    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(36, 36)
    r.icon:SetPoint("LEFT", 10, 0)
    r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    r.tier = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.tier:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, 2)

    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.name:SetPoint("LEFT", r.tier, "RIGHT", 6, 0)
    r.name:SetPoint("RIGHT", r, "RIGHT", -52, 8)
    r.name:SetJustifyH("LEFT")

    r.meta = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.meta:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -12)
    r.meta:SetJustifyH("LEFT")

    r.count = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.count:SetPoint("TOPRIGHT", -8, -6)

    local bar = CreateFrame("StatusBar", nil, r)
    bar:SetSize(ROW_W - 62, 8)
    bar:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 8, 2)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 3)
    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    barBg:SetVertexColor(0.12, 0.12, 0.16, 0.9)
    r.bar = bar

    r.barText = bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.barText:SetPoint("CENTER", bar, "CENTER", 0, 0)

    r:SetScript("OnEnter", function(self)
        self.bg:SetVertexColor(0.12, 0.16, 0.24, 0.9)
        if self._entry then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. self._entry)
            Q.AddEventTooltip(self._ev)
            GameTooltip:Show()
        end
    end)
    r:SetScript("OnLeave", function(self)
        self.bg:SetVertexColor(0.07, 0.09, 0.14, 0.72)
        GameTooltip_Hide()
    end)
    return r
end

local Rebuild

local function MakeChip(parent, label, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(58, 18)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    return b
end

local function PaintChips()
    if not picker then return end
    for ev, chip in pairs(picker.eventChips) do
        local on = (filterEvent == ev)
        if ev == -1 then on = (filterEvent == -1) end
        chip:SetAlpha(on and 1 or 0.55)
    end
    for t, chip in pairs(picker.tierChips) do
        chip:SetAlpha((filterTier == t) and 1 or 0.55)
    end
end

Rebuild = function()
    if not picker then return end
    local content = picker.content
    for _, r in ipairs(content._rows) do r:Hide() end
    local rows = CollectRows()
    content:SetHeight(math.max(1, #rows * ROW_H))
    for i, gem in ipairs(rows) do
        local r = content._rows[i]
        if not r then
            r = MakeRow(content, i)
            content._rows[i] = r
        end
        local capture = gem
        r._entry = gem.entry
        r._ev = gem.ev
        Q.SetGemIcon(r.icon, gem.entry)
        local rgb = Q.EVENT_RGB[gem.ev] or Q.EVENT_RGB[6]
        r.stripe:SetVertexColor(rgb[1], rgb[2], rgb[3], 1)
        r.tier:SetText("|cffffd200T" .. (gem.tier or "?") .. "|r")
        r.name:SetText(gem.short)
        r.meta:SetText("Proc on " .. (Q.EVENT_NAME[gem.ev] or "?"))
        r.meta:SetTextColor(rgb[1], rgb[2], rgb[3])
        r.count:SetText("x" .. gem.count)
        SetFusionBar(r, gem)
        r:SetScript("OnClick", function()
            if not pickerCtx then return end
            if _G.AIO and _G.AIO.Handle then
                local AG = Q.PA() and Q.PA().AstralGems
                if AG then AG._pendingGemEntry = capture.entry end
                _G.AIO.Handle("AstralgemServer", "Socket",
                    pickerCtx.equipSlot, pickerCtx.idx, capture.entry)
            else
                SendChatMessage(string.format(".gem socket %d %d %d",
                    pickerCtx.equipSlot, pickerCtx.idx, capture.entry), "SAY")
            end
            picker:Hide()
        end)
        r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
        r:Show()
    end
    if picker.empty then
        if #rows == 0 then
            picker.empty:SetText("No gems match this search.")
            picker.empty:Show()
        else
            picker.empty:Hide()
        end
    end
end

local function BuildPicker()
    if picker then return picker end
    local f = CreateFrame("Frame", "qtAstralQOL_GemPicker", UIParent)
    f:SetSize(430, 520)
    f:SetPoint("CENTER", 200, 20)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0.04, 0.05, 0.10, 0.97)
    f:SetBackdropBorderColor(0.38, 0.50, 0.82, 1)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Socket a gem")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    local search
    local PA = Q.PA()
    if PA and PA.UI and PA.UI.MakeSearchBox then
        search = PA.UI.MakeSearchBox(f, {
            width = 400, placeholder = "Search Avenger's Shield, melee, T2…",
            onChanged = function(text)
                searchText = (text or ""):lower()
                Rebuild()
            end,
        })
        search:SetPoint("TOPLEFT", 14, -40)
    else
        search = CreateFrame("EditBox", "qtAstralQOL_PickerSearch", f, "InputBoxTemplate")
        search:SetSize(390, 20)
        search:SetPoint("TOPLEFT", 18, -42)
        search:SetAutoFocus(false)
        search:SetScript("OnTextChanged", function(self)
            searchText = (self:GetText() or ""):lower()
            Rebuild()
        end)
    end
    f.search = search

    f.eventChips = {}
    local evOrder = { { -1, "All" }, { 0, "Melee" }, { 1, "Cast" }, { 2, "Heal" }, { 3, "Struck" } }
    local x = 14
    for _, pair in ipairs(evOrder) do
        local id, label = pair[1], pair[2]
        local chip = MakeChip(f, label, function()
            filterEvent = id
            PaintChips()
            Rebuild()
        end)
        chip:SetPoint("TOPLEFT", x, -68)
        f.eventChips[id] = chip
        x = x + 62
    end

    f.tierChips = {}
    x = 14
    for t = 0, 8 do
        local tierId = t
        local chip = MakeChip(f, t == 0 and "T*" or ("T" .. t), function()
            filterTier = tierId
            PaintChips()
            Rebuild()
        end)
        chip:SetWidth(36)
        chip:SetPoint("TOPLEFT", x, -90)
        f.tierChips[t] = chip
        x = x + 38
    end

    local scroll = CreateFrame("ScrollFrame", "qtAstralQOL_GemPickerScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -114)
    scroll:SetPoint("BOTTOMRIGHT", -32, 12)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(ROW_W, 1)
    content._rows = {}
    scroll:SetScrollChild(content)
    f.content = content

    f.empty = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    f.empty:SetPoint("CENTER", scroll, "CENTER", 0, 0)
    f.empty:Hide()

    picker = f
    PaintChips()
    return f
end

function Q.OpenGemPicker(equipSlot, idx)
    pickerCtx = { equipSlot = equipSlot, idx = idx }
    if _G.AstralGemsPicker then _G.AstralGemsPicker:Hide() end
    BuildPicker()
    Rebuild()
    picker:Show()
    picker:Raise()
end

function Q.StealStockPicker()
    local f = _G.AstralGemsPicker
    if f and not f._qolStolen then
        f._qolStolen = true
        f:HookScript("OnShow", function(self)
            self:Hide()
        end)
    end
end
