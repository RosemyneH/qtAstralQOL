local Q = qtAstralQOL

local STACK = {}
local knownFamilies = {}
local hookedDE = false

local TOAST_W, TOAST_H = 248, 52
local GAP = 6

local function DEFrame()
    local f = _G.ProjectAstralAstralDisenchant
    if f and f:IsShown() then return f end
end

local function Relayout()
    local live = {}
    for _, t in ipairs(STACK) do
        if t.frame:IsShown() then live[#live + 1] = t end
    end
    STACK = live
    local de = DEFrame()
    for i, t in ipairs(STACK) do
        local rise = (i - 1) * (TOAST_H + GAP)
        t.frame:ClearAllPoints()
        if de then
            t.frame:SetPoint("BOTTOMLEFT", de, "BOTTOMRIGHT", 8, rise)
        else
            t.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -18, 18 + rise)
        end
    end
end

local function HookDE()
    local de = _G.ProjectAstralAstralDisenchant
    if hookedDE or not de then return end
    hookedDE = true
    de:HookScript("OnShow", Relayout)
    de:HookScript("OnHide", Relayout)
    de:HookScript("OnDragStop", Relayout)
end

function Q.RememberOwnedFamilies()
    local catalog = Q.Catalog()
    if not next(catalog) then return end
    local stock = Q.Stock()
    for entry, cat in pairs(catalog) do
        local family = cat and cat.family
        if family and family ~= "" and not knownFamilies[family] then
            local owned = (tonumber(stock[entry]) or 0) > 0 or (GetItemCount(entry) or 0) > 0
            if owned then knownFamilies[family] = true end
        end
    end
    local PA = Q.PA()
    local loadout = PA and PA.AstralGems and PA.AstralGems.loadout or {}
    for ord = 0, 5 do
        local slot = loadout[ord]
        if slot then
            for idx = 0, 3 do
                local id = slot[idx] and slot[idx].gemId
                local c = id and catalog[id]
                if c and c.family and c.family ~= "" then
                    knownFamilies[c.family] = true
                end
            end
        end
    end
end

function Q.GemToast(opts)
    if not Q.DB().notify then return end
    opts = opts or {}
    HookDE()

    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(TOAST_W, TOAST_H)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    local rgb = Q.EVENT_RGB[opts.eventType or 6] or Q.EVENT_RGB[6]
    f:SetBackdropColor(0.04, 0.05, 0.10, 0.94)
    if opts.isNew then
        f:SetBackdropBorderColor(1.00, 0.82, 0.20, 1)
    else
        f:SetBackdropBorderColor(rgb[1], rgb[2], rgb[3], 0.95)
    end

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetTexture(opts.texture or "Interface\\Icons\\INV_Misc_Gem_Variety_01")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 2)
    title:SetPoint("RIGHT", -10, 0)
    title:SetJustifyH("LEFT")
    if opts.isNew then
        title:SetText("|cffffd200NEW|r  " .. (opts.title or "Gem"))
    else
        title:SetText(opts.title or "Gem")
    end

    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, -1)
    sub:SetJustifyH("LEFT")
    local evName = Q.EVENT_NAME[opts.eventType or 6] or "Any"
    sub:SetText(string.format("T%d  ·  %s", opts.tier or 1, evName))

    f:SetAlpha(0)
    f:Show()
    STACK[#STACK + 1] = { frame = f }
    Relayout()

    local holdFor = opts.isNew and 4.6 or 3.2
    local phase, t = "in", 0
    f:SetScript("OnUpdate", function(self, dt)
        t = t + dt
        if phase == "in" then
            local k = math.min(1, t / 0.22)
            self:SetAlpha(k)
            if k >= 1 then phase, t = "hold", 0 end
        elseif phase == "hold" then
            if t >= holdFor then phase, t = "out", 0 end
        else
            local k = math.min(1, t / 0.35)
            self:SetAlpha(1 - k)
            if k >= 1 then
                self:Hide()
                Relayout()
            end
        end
    end)
end

function Q.OnDisenchantGem(entry, tier)
    entry = tonumber(entry) or 0
    if entry <= 0 then return end
    local cat = Q.Cat(entry)
    local family = cat and cat.family or ""
    if not next(knownFamilies) then Q.RememberOwnedFamilies() end
    local isNew = family ~= "" and not knownFamilies[family]
    if family ~= "" then knownFamilies[family] = true end
    Q.GemToast({
        title     = Q.GemShortName(entry),
        texture   = Q.GemTexture(entry),
        eventType = (cat and tonumber(cat.eventType)) or 6,
        tier      = tonumber(tier) or (cat and cat.tier) or 1,
        isNew     = isNew,
    })
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    local acc = 0
    self:SetScript("OnUpdate", function(me, dt)
        acc = acc + dt
        if acc < 2.0 then return end
        me:SetScript("OnUpdate", nil)
        Q.RememberOwnedFamilies()
        HookDE()
    end)
end)
