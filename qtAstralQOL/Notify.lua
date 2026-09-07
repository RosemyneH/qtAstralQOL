local Q = qtAstralQOL

local knownFamilies = {}

local function Elv()
    local pack = _G.ElvUI
    return pack and pack[1]
end

local function GainCfg()
    local PA = Q.PA()
    local s = PA and PA.Settings and PA.Settings.gainPopup or {}
    return {
        width   = s.width or 280,
        height  = s.height or 46,
        anchor  = s.anchor or "BOTTOMRIGHT",
        offsetX = s.offsetX or -30,
        offsetY = s.offsetY or 180,
    }
end

local function SkinToast(f)
    local E = Elv()
    if not E then return end
    if f.SetTemplate then
        f:SetTemplate("Transparent")
    end
    if f.icon and E.TexCoords then
        f.icon:SetTexCoord(unpack(E.TexCoords))
    end
    local font = E.media and E.media.normFont
    if font and f.label and f.label.SetFont then
        f.label:SetFont(font, 12, "OUTLINE")
        f.label:SetTextColor(1, 1, 1)
    end
end

function Q.RememberOwnedFamilies()
    local catalog = Q.Catalog()
    if not next(catalog) then return end
    local stock = Q.Stock()
    for entry, count in pairs(stock) do
        if (tonumber(count) or 0) > 0 then
            local cat = catalog[entry]
            local family = cat and cat.family
            if family and family ~= "" then knownFamilies[family] = true end
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
    local evName = Q.EVENT_NAME[opts.eventType or 6] or "Any"
    local name = opts.title or "Gem"
    local line = string.format("T%d  %s  ·  %s", opts.tier or 1, name, evName)
    if opts.isNew then line = "NEW  " .. line end

    local PA = Q.PA()
    local UI = PA and PA.UI
    local f
    if UI and UI.GainPopup then
        f = UI.GainPopup(line, opts.isNew and "warn" or "gems", { fontSize = 12 })
    end

    if not f then
        local cfg = GainCfg()
        f = CreateFrame("Frame", nil, UIParent)
        f:SetSize(cfg.width, cfg.height)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        if UI and UI.AstralBackdrop then
            UI.AstralBackdrop(f, {
                thin = true,
                bg = { 0.04, 0.06, 0.11, 0.92 },
                border = opts.isNew and { 1, 0.75, 0.35, 1 } or { 0.75, 0.55, 0.95, 1 },
            })
        else
            f:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 16, edgeSize = 18,
                insets = { left = 4, right = 4, top = 4, bottom = 4 },
            })
            f:SetBackdropColor(0.04, 0.06, 0.11, 0.92)
        end
        local lbl = f:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\MORPHEUS.TTF", 12)
        lbl:SetText(line)
        lbl:SetTextColor(0.95, 0.95, 1)
        f.label = lbl
        f:SetPoint(cfg.anchor, UIParent, cfg.anchor, cfg.offsetX, cfg.offsetY)
        f:SetAlpha(0)
        f:Show()
        local phase, phaseT = "in", 0
        f:SetScript("OnUpdate", function(self, dt)
            phaseT = phaseT + dt
            if phase == "in" then
                local t = math.min(1, phaseT / 0.35)
                self:SetAlpha(1 - (1 - t) * (1 - t) * (1 - t))
                if t >= 1 then phase, phaseT = "hold", 0 end
            elseif phase == "hold" then
                if phaseT >= 3 then phase, phaseT = "out", 0 end
            else
                local t = math.min(1, phaseT / 0.5)
                self:SetAlpha(1 - t)
                if t >= 1 then self:Hide() end
            end
        end)
    end

    local rgb = Q.EVENT_RGB[opts.eventType or 6] or Q.EVENT_RGB[6]
    if f.stripe then
        f.stripe:SetVertexColor(rgb[1], rgb[2], rgb[3], 1)
    end

    local cfg = GainCfg()
    local right = cfg.anchor == "BOTTOMRIGHT" or cfg.anchor == "TOPRIGHT"
    if not f.icon then
        local icon = f:CreateTexture(nil, "ARTWORK")
        icon:SetSize(cfg.height - 14, cfg.height - 14)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        f.icon = icon
    end
    f.icon:SetTexture(opts.texture or "Interface\\Icons\\INV_Misc_Gem_Variety_01")
    f.icon:ClearAllPoints()
    if f.label then f.label:ClearAllPoints() end
    if right then
        f.icon:SetPoint("LEFT", 8, 0)
        if f.label then
            f.label:SetPoint("LEFT", f.icon, "RIGHT", 8, 0)
            f.label:SetPoint("RIGHT", f, "RIGHT", -14, 0)
            f.label:SetJustifyH("RIGHT")
        end
    else
        f.icon:SetPoint("RIGHT", -8, 0)
        if f.label then
            f.label:SetPoint("LEFT", f, "LEFT", 14, 0)
            f.label:SetPoint("RIGHT", f.icon, "LEFT", -8, 0)
            f.label:SetJustifyH("LEFT")
        end
    end

    SkinToast(f)
    return f
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
    end)
end)
