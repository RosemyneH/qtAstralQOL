local ADDON = ...
qtAstralQOL = qtAstralQOL or {}
local Q = qtAstralQOL

Q.EVENT = {
    MELEE  = 0,
    HIT    = 0,
    CAST   = 1,
    HEAL   = 2,
    STRUCK = 3,
    CRIT   = 4,
    DOT    = 5,
    ANY    = 6,
}

Q.EVENT_RGB = {
    [0] = { 1.00, 0.28, 0.22 },
    [1] = { 0.28, 0.68, 1.00 },
    [2] = { 0.28, 0.95, 0.48 },
    [3] = { 0.98, 0.72, 0.18 },
    [4] = { 1.00, 0.42, 0.82 },
    [5] = { 0.72, 0.42, 1.00 },
    [6] = { 0.92, 0.92, 0.96 },
}

Q.EVENT_NAME = {
    [0] = "Melee", [1] = "Cast", [2] = "Heal",
    [3] = "Struck", [4] = "Crit", [5] = "DoT/HoT", [6] = "Any",
}

Q.EVENT_DESC = {
    [0] = "All physical events: bleeds, hits, physical spells, and physical Astral gems.",
    [1] = "All magic-school damage (holy, shadow, frost, fire), DoTs, channels, and magic Astral gems.",
    [2] = "All healing and overhealing, plus healing Astral gems.",
    [3] = "All incoming damage, plus parry, block, and dodge.",
}

function Q.AddEventTooltip(ev)
    ev = tonumber(ev) or 6
    local rgb = Q.EVENT_RGB[ev] or Q.EVENT_RGB[6]
    GameTooltip:AddLine("Proc on " .. (Q.EVENT_NAME[ev] or "Any"), rgb[1], rgb[2], rgb[3])
    local desc = Q.EVENT_DESC[ev]
    if desc then
        GameTooltip:AddLine(desc, 0.72, 0.76, 0.88, true)
    end
end

Q.QUALITY_RGB = {
    [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.00, 0.55, 1.00 },
    [4] = { 0.64, 0.21, 0.93 },
    [5] = { 1.00, 0.50, 0.00 },
}

Q.QUALITY_NAME = {
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
}

Q.SLOT_SCHEMA = {
    { ord = 0, equipSlot = 0,  invSlot = 1,  paperdoll = "HeadSlot",     corner = "BOTTOMRIGHT", label = "Head",   colors = { 3 },          n = 1 },
    { ord = 1, equipSlot = 1,  invSlot = 2,  paperdoll = "NeckSlot",     corner = "BOTTOMRIGHT", label = "Neck",   colors = { 4 },          n = 1 },
    { ord = 2, equipSlot = 4,  invSlot = 5,  paperdoll = "ChestSlot",    corner = "BOTTOMRIGHT", label = "Chest",  colors = { 2, 3, 4 },    n = 3 },
    { ord = 3, equipSlot = 6,  invSlot = 7,  paperdoll = "LegsSlot",     corner = "BOTTOMLEFT",  label = "Legs",   colors = { 2, 3, 4 },    n = 3 },
    { ord = 4, equipSlot = 7,  invSlot = 8,  paperdoll = "FeetSlot",     corner = "BOTTOMLEFT",  label = "Boots",  colors = { 2 },          n = 1 },
    { ord = 5, equipSlot = 15, invSlot = 16, paperdoll = "MainHandSlot", corner = "TOPLEFT",     label = "Weapon", colors = { 2, 3, 4, 5 }, n = 4 },
}

function Q.Defaults()
    return {
        notify     = true,
        charDock   = true,
        inspectTab = true,
        extractSkip = {},
        extractPresets = {},
        extractPreset = "",
        gemLoadouts = {},
        gemLoadoutLast = "PvE",
        gemLoadoutBestRank = true,
    }
end

function Q.DB()
    if type(qtAstralQOL_DB) ~= "table" then
        qtAstralQOL_DB = Q.Defaults()
    end
    local d = Q.Defaults()
    for k, v in pairs(d) do
        if qtAstralQOL_DB[k] == nil then qtAstralQOL_DB[k] = v end
    end
    if qtAstralQOL_DB._notifyDefault ~= 1 then
        qtAstralQOL_DB.notify = true
        qtAstralQOL_DB._notifyDefault = 1
    end
    if qtAstralQOL_DB._dockPaperdoll ~= 1 then
        qtAstralQOL_DB.charDock = true
        qtAstralQOL_DB._dockPaperdoll = 1
    end
    return qtAstralQOL_DB
end

function Q.PA()
    return _G.ProjectAstral
end

function Q.Catalog()
    local PA = Q.PA()
    return (PA and PA.GemFusion and PA.GemFusion.catalog) or {}
end

function Q.Stock()
    local PA = Q.PA()
    if PA and PA.GemStash and PA.GemStash.GetStock then
        return PA.GemStash.GetStock() or {}
    end
    return {}
end

function Q.Cat(entry)
    return Q.Catalog()[entry]
end

function Q.EventOf(entry)
    local c = Q.Cat(entry)
    return (c and tonumber(c.eventType)) or 6
end

function Q.Tint(tex, eventType)
    if not tex then return end
    local rgb = Q.EVENT_RGB[tonumber(eventType) or 6] or Q.EVENT_RGB[6]
    tex:SetVertexColor(rgb[1], rgb[2], rgb[3], 1)
end

local spellIconCache = {}
local spellByKey = {}
local wantedKeys = {}
local scanTip
local spellIndexReady = false
local scanStarted = false

local function CleanLabel(s)
    if not s or s == "" then return nil end
    s = tostring(s)
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("|H.-|h", ""):gsub("|h", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("^%a+%s+Astral%s+Gem%s+of%s+", "")
    s = s:gsub("^Astral%s+Gem%s+of%s+", "")
    s = s:gsub("Astral%s+Gem[:%s]+", "")
    s = s:gsub("^[Tt]ier%s*%d+%s+", "")
    s = s:gsub("^T%d+%s+", "")
    s = s:gsub("^Astral%s+", "")
    s = s:gsub("%s+[Gg]em%s*$", "")
    s = s:gsub("^[Gg]em%s+of%s+", "")
    s = s:gsub("%s*%b()", "")
    s = s:gsub("%s+%(%d+%)$", "")
    if s == "" then return nil end
    return s
end

local function NormKey(s)
    s = CleanLabel(s)
    if not s then return nil end
    s = s:lower()
    s = s:gsub("'", "")
    s = s:gsub("_", " ")
    s = s:gsub("%-", " ")
    s = s:gsub("%s+", " ")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    return s
end

local function IconScore(path)
    if not path or path == "" then return -1 end
    local p = path:lower()
    if p:find("questionmark") or p:find("inv_misc_gem") or p:find("inv_jewelcrafting")
       or p:find("inv_misc_bag") then
        return 0
    end
    if p:find("ability_") or p:find("spell_") then return 3 end
    if p:find("inv_sword") or p:find("inv_axe") or p:find("inv_weapon") then return 2 end
    return 1
end

local function RememberSpell(name, icon)
    if not name or not icon or IconScore(icon) <= 0 then return end
    local k = NormKey(name)
    if not k or not wantedKeys[k] then return end
    local cur = spellByKey[k]
    if not cur or IconScore(icon) > IconScore(cur) then
        spellByKey[k] = icon
        spellByKey[k:gsub(" ", "")] = icon
    end
end

local function LookupByName(label)
    local k = NormKey(label)
    if not k then return nil end
    return spellByKey[k] or spellByKey[k:gsub(" ", "")]
end

local function RebuildWanted()
    for k in pairs(wantedKeys) do wantedKeys[k] = nil end
    for _, cat in pairs(Q.Catalog()) do
        local a = NormKey(cat.family)
        local b = NormKey(CleanLabel(cat.name))
        if a then wantedKeys[a] = true end
        if b then wantedKeys[b] = true end
    end
end

local function WantedFilled()
    for k in pairs(wantedKeys) do
        if not spellByKey[k] then return false end
    end
    return next(wantedKeys) ~= nil
end

function Q.RefreshAllGemIcons()
    local PA = Q.PA()
    if PA and PA.AstralGems and PA.AstralGems.Render then
        PA.AstralGems.Render()
    end
    if PA and PA.GemStash and PA.GemStash.Refresh then
        PA.GemStash.Refresh()
    end
    if Q.RefreshCharDock then Q.RefreshCharDock() end
end

local function StartSpellScan()
    if scanStarted then return end
    RebuildWanted()
    if not next(wantedKeys) then return end
    scanStarted = true
    local id, MAX = 1, 80000
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(self)
        RebuildWanted()
        local n = 0
        while n < 2000 and id <= MAX do
            local name, _, icon = GetSpellInfo(id)
            if name and icon then RememberSpell(name, icon) end
            id = id + 1
            n = n + 1
        end
        if id > MAX or WantedFilled() then
            self:SetScript("OnUpdate", nil)
            spellIndexReady = true
            for k in pairs(spellIconCache) do spellIconCache[k] = nil end
            Q.RefreshAllGemIcons()
        end
    end)
end

local function TooltipSpellIcon(entry)
    if not entry then return nil end
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "qtAstralQOLSpellScan", UIParent, "GameTooltipTemplate")
        scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    scanTip:ClearLines()
    scanTip:SetHyperlink("item:" .. entry)
    local found
    local n = scanTip:NumLines() or 0
    for i = 1, n do
        local fs = _G["qtAstralQOLSpellScanTextLeft" .. i]
        local t = fs and fs:GetText()
        if t then
            local sid = t:match("|Hspell:(%d+)|h")
            if sid then
                local icon = select(3, GetSpellInfo(tonumber(sid)))
                if icon and IconScore(icon) > 0 then
                    found = icon
                    break
                end
            end
            local named = LookupByName(t) or LookupByName(t:match("%[(.-)%]"))
            if named then
                found = named
                break
            end
        end
    end
    scanTip:Hide()
    return found
end

local function SpellIconForLabel(label)
    local key = NormKey(label)
    if not key then return nil end
    local cached = spellIconCache[key]
    if cached ~= nil then
        return cached or nil
    end
    local icon = LookupByName(label)
        or LookupByName(label and tostring(label):match("%sof%s+(.+)$"))
    if not icon then
        local cleaned = CleanLabel(label)
        local fromName = cleaned and select(3, GetSpellInfo(cleaned))
        if fromName and IconScore(fromName) > 0 then icon = fromName end
    end
    if icon then
        spellIconCache[key] = icon
        return icon
    end
    if spellIndexReady then
        spellIconCache[key] = false
    end
    return nil
end

function Q.GemTexture(entry)
    entry = tonumber(entry)
    if not entry then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    if not scanStarted then StartSpellScan() end
    local cat = Q.Cat(entry)
    if cat then
        if type(cat.icon) == "string" and IconScore(cat.icon) > 0 then
            return cat.icon, true
        end
        local sid = tonumber(cat.spellId)
        if sid then
            local icon = select(3, GetSpellInfo(sid))
            if icon and IconScore(icon) > 0 then return icon, true end
        end
    end
    local spellIcon = SpellIconForLabel(cat and cat.family)
        or SpellIconForLabel(cat and cat.name)
        or SpellIconForLabel(select(1, GetItemInfo(entry)))
        or TooltipSpellIcon(entry)
    if spellIcon and IconScore(spellIcon) > 0 then
        return spellIcon, true
    end
    local itemIcon = select(10, GetItemInfo(entry))
    return itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark", false
end

function Q.SetGemIcon(tex, entry)
    if not tex then return false end
    local path, isSpell = Q.GemTexture(entry)
    tex:SetTexture(path)
    tex:SetVertexColor(1, 1, 1, 1)
    return isSpell
end

local scanBoot = CreateFrame("Frame")
scanBoot:RegisterEvent("PLAYER_LOGIN")
scanBoot:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    local acc = 0
    self:SetScript("OnUpdate", function(me, dt)
        acc = acc + dt
        if not scanStarted then StartSpellScan() end
        if scanStarted or acc > 12 then
            me:SetScript("OnUpdate", nil)
        end
    end)
end)

function Q.GemShortName(entry)
    local cat = Q.Cat(entry)
    if cat and cat.family and cat.family ~= "" then
        return cat.family
    end
    local raw = (cat and cat.name ~= "" and cat.name) or select(1, GetItemInfo(entry))
    return CleanLabel(raw) or raw or ("Item " .. tostring(entry))
end

function Q.FusionPips(count)
    count = tonumber(count) or 0
    if count <= 0 then return 0 end
    local rem = count % 3
    if rem == 0 then return 3 end
    return rem
end

function Q.FamilyTierCount(family, tier, stock)
    stock = stock or Q.Stock()
    local catalog = Q.Catalog()
    local n = 0
    if not family or family == "" then return n end
    for entry, count in pairs(stock) do
        local c = catalog[entry]
        if c and c.family == family and c.tier == tier and not c.isMythic then
            n = n + (tonumber(count) or 0)
        end
    end
    return n
end

function Q.HasHigherTierAvailable(family, tier)
    if not family or family == "" then return false end
    tier = tonumber(tier) or 0
    local stock = Q.Stock()
    for entry, c in pairs(Q.Catalog()) do
        if c and c.family == family and not c.isMythic then
            local t = tonumber(c.tier) or 0
            if t > tier then
                if (tonumber(stock[entry]) or 0) > 0 then return true end
                if (GetItemCount(entry) or 0) > 0 then return true end
            end
        end
    end
    return false
end

function Q.ResolveLoadoutIds(ids)
    local out = {}
    for i = 1, #(ids or {}) do
        out[i] = tonumber(ids[i]) or 0
    end
    local sub, miss = 0, 0
    local fallback = Q.DB().gemLoadoutBestRank
    local stock = Q.Stock()
    local catalog = Q.Catalog()
    local pool = {}

    local function add(id, n)
        id, n = tonumber(id), tonumber(n) or 0
        if id and id > 0 and n > 0 then
            pool[id] = (pool[id] or 0) + n
        end
    end
    for id, n in pairs(stock) do add(id, n) end
    if Q.CaptureLoadout then
        for _, id in ipairs(Q.CaptureLoadout()) do add(id, 1) end
    end

    local famGems = {}
    if fallback then
        for entry, c in pairs(catalog) do
            if c and c.family and c.family ~= "" and not c.isMythic then
                local list = famGems[c.family]
                if not list then
                    list = {}
                    famGems[c.family] = list
                end
                list[#list + 1] = { id = entry, tier = tonumber(c.tier) or 0 }
            end
        end
        for _, list in pairs(famGems) do
            table.sort(list, function(a, b) return a.tier > b.tier end)
        end
    end

    local function take(id)
        if not id or id <= 0 then return end
        local n = pool[id]
        if not n then
            n = (GetItemCount and GetItemCount(id)) or 0
            pool[id] = n
        end
        if n > 0 then
            pool[id] = n - 1
            return true
        end
    end

    for i, want in ipairs(out) do
        if want > 0 then
            if take(want) then
                -- exact gem
            elseif fallback then
                local pick = 0
                local c = catalog[want]
                local list = c and not c.isMythic and c.family and famGems[c.family]
                if list then
                    local wantTier = tonumber(c.tier) or 0
                    for j = 1, #list do
                        if list[j].tier <= wantTier and take(list[j].id) then
                            pick = list[j].id
                            break
                        end
                    end
                end
                out[i] = pick
                if pick > 0 then
                    sub = sub + 1
                else
                    miss = miss + 1
                end
            else
                miss = miss + 1
            end
        end
    end
    return out, sub, miss
end

function Q.DepositAll()
    SendChatMessage(".astralstash depositall", "SAY")
    local PA = Q.PA()
    if PA and PA.GemStash and PA.GemStash.DelayedRequestState then
        PA.GemStash.DelayedRequestState(400)
    end
end

function Q.RequestGemData()
    local PA = Q.PA()
    if PA and PA.GemFusion and PA.GemFusion.RequestInfo then
        PA.GemFusion.RequestInfo()
    elseif _G.AIO and _G.AIO.Handle then
        _G.AIO.Handle("AstralgemServer", "RequestInfo")
    end
    if PA and PA.GemStash and PA.GemStash.RequestState then
        PA.GemStash.RequestState()
    end
    if _G.AIO and _G.AIO.Handle then
        _G.AIO.Handle("AstralgemServer", "RequestLoadout")
    end
end

SLASH_QTASTRALQOL1 = "/qgems"
SLASH_QTASTRALQOL2 = "/qolgems"
SlashCmdList["QTASTRALQOL"] = function(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local key = msg:lower()
    local db = Q.DB()
    if key == "notify" then
        db.notify = not db.notify
        DEFAULT_CHAT_FRAME:AddMessage("|cff80e0ffqtAstralQOL|r gem toasts: " .. (db.notify and "on" or "off"))
    elseif key == "dock" then
        db.charDock = not db.charDock
        DEFAULT_CHAT_FRAME:AddMessage("|cff80e0ffqtAstralQOL|r character dock: " .. (db.charDock and "on" or "off"))
        if Q.RefreshCharDock then Q.RefreshCharDock() end
    elseif key == "deposit" then
        Q.DepositAll()
    elseif key:find("^loadout") then
        if Q.LoadoutSlash then Q.LoadoutSlash(msg) end
    else
        local PA = Q.PA()
        if PA and PA.AstralGems then
            if PA.EnsureMainMenu then PA.EnsureMainMenu() end
            local mf = PA.mainFrame
            if mf then
                mf:Show()
                if mf.SwitchTab then mf:SwitchTab("AstralGems") end
                if mf._tabBar then mf._tabBar:SelectTab("AstralGems") end
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff80e0ffqtAstralQOL|r  /qgems  /qgems deposit  /qgems notify  /qgems dock  /qgems loadout")
    end
end
