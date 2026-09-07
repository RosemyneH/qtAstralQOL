local Q = qtAstralQOL

local ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local PREFIX = "QG1."

local function B64Enc(s)
    local out, n = {}, #s
    for i = 1, n, 3 do
        local a = s:byte(i)
        local b = s:byte(i + 1)
        local c = s:byte(i + 2)
        local v = a * 65536 + (b or 0) * 256 + (c or 0)
        out[#out + 1] = ALPHA:sub(math.floor(v / 262144) % 64 + 1, math.floor(v / 262144) % 64 + 1)
        out[#out + 1] = ALPHA:sub(math.floor(v / 4096) % 64 + 1, math.floor(v / 4096) % 64 + 1)
        if not b then
            out[#out + 1] = "=="
        elseif not c then
            out[#out + 1] = ALPHA:sub(math.floor(v / 64) % 64 + 1, math.floor(v / 64) % 64 + 1) .. "="
        else
            out[#out + 1] = ALPHA:sub(math.floor(v / 64) % 64 + 1, math.floor(v / 64) % 64 + 1)
            out[#out + 1] = ALPHA:sub(v % 64 + 1, v % 64 + 1)
        end
    end
    return table.concat(out)
end

local function B64Dec(s)
    s = s:gsub("%s", ""):gsub("[^A-Za-z0-9%+/=]", "")
    local map = {}
    for i = 1, 64 do map[ALPHA:sub(i, i)] = i - 1 end
    local out = {}
    for i = 1, #s, 4 do
        local a = map[s:sub(i, i)] or 0
        local b = map[s:sub(i + 1, i + 1)] or 0
        local c = map[s:sub(i + 2, i + 2)] or 0
        local d = map[s:sub(i + 3, i + 3)] or 0
        local v = a * 262144 + b * 4096 + c * 64 + d
        out[#out + 1] = string.char(math.floor(v / 65536) % 256)
        if s:sub(i + 2, i + 2) ~= "=" then
            out[#out + 1] = string.char(math.floor(v / 256) % 256)
        end
        if s:sub(i + 3, i + 3) ~= "=" then
            out[#out + 1] = string.char(v % 256)
        end
    end
    return table.concat(out)
end

local function SlotList()
    local t = {}
    for _, sc in ipairs(Q.SLOT_SCHEMA) do
        for idx = 0, sc.n - 1 do
            t[#t + 1] = { ord = sc.ord, idx = idx, equip = sc.equipSlot }
        end
    end
    return t
end

function Q.CaptureLoadout()
    local ids = {}
    local PA = Q.PA()
    local lo = PA and PA.AstralGems and PA.AstralGems.loadout or {}
    for _, sl in ipairs(SlotList()) do
        local d = lo[sl.ord] and lo[sl.ord][sl.idx]
        local id = d and tonumber(d.gemId) or 0
        ids[#ids + 1] = (id and id > 0) and id or 0
    end
    return ids
end

function Q.EncodeLoadout(ids)
    ids = ids or Q.CaptureLoadout()
    return PREFIX .. B64Enc("1:" .. table.concat(ids, ","))
end

function Q.DecodeLoadout(code)
    if not code then return nil end
    code = tostring(code):gsub("%s", "")
    local payload = code
    if code:sub(1, #PREFIX) == PREFIX then
        payload = code:sub(#PREFIX + 1)
    end
    payload = payload:gsub("%-", "+"):gsub("_", "/")
    local raw = B64Dec(payload)
    local body = raw:match("^1:(.*)$") or raw
    local ids = {}
    for part in string.gmatch(body .. ",", "([^,]*),") do
        ids[#ids + 1] = tonumber(part) or 0
    end
    if #ids < 13 then return nil end
    return ids
end

local function Store()
    local db = Q.DB()
    if type(db.gemLoadouts) ~= "table" then db.gemLoadouts = {} end
    return db.gemLoadouts
end

local function Names()
    local t = {}
    for n in pairs(Store()) do t[#t + 1] = n end
    table.sort(t)
    return t
end

function Q.SaveGemLoadout(name, code)
    name = (name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        UIErrorsFrame:AddMessage("Name the loadout first.", 1, 0.8, 0.3, 1)
        return
    end
    if type(code) == "table" then
        code = Q.EncodeLoadout(code)
    elseif type(code) == "string" then
        local ids = Q.DecodeLoadout(code)
        if not ids then
            UIErrorsFrame:AddMessage("Invalid gem loadout code.", 1, 0.45, 0.45, 1)
            return
        end
        code = Q.EncodeLoadout(ids)
    else
        code = Q.EncodeLoadout()
    end
    Store()[name] = code
    Q.DB().gemLoadoutLast = name
    UIErrorsFrame:AddMessage("Saved gem loadout: " .. name, 0.6, 1, 0.6, 1)
    if Q.RefreshLoadoutList then Q.RefreshLoadoutList() end
end

function Q.DeleteGemLoadout(name)
    name = (name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" or not Store()[name] then
        UIErrorsFrame:AddMessage("No loadout named " .. tostring(name), 1, 0.45, 0.45, 1)
        return
    end
    Store()[name] = nil
    local db = Q.DB()
    if db.gemLoadoutLast == name then db.gemLoadoutLast = Names()[1] or "PvE" end
    UIErrorsFrame:AddMessage("Deleted gem loadout: " .. name, 0.6, 1, 0.6, 1)
    if Q.RefreshLoadoutList then Q.RefreshLoadoutList() end
end

local applying, queue, qn

local function Socket(equip, idx, gem)
    if _G.AIO and _G.AIO.Handle then
        local AG = Q.PA() and Q.PA().AstralGems
        if AG then AG._pendingGemEntry = gem end
        _G.AIO.Handle("AstralgemServer", "Socket", equip, idx, gem)
    else
        SendChatMessage(string.format(".gem socket %d %d %d", equip, idx, gem), "SAY")
    end
end

local function Unsocket(equip, idx)
    if _G.AIO and _G.AIO.Handle then
        _G.AIO.Handle("AstralgemServer", "Unsocket", equip, idx)
    else
        SendChatMessage(string.format(".gem unsocket %d %d", equip, idx), "SAY")
    end
end

function Q.ApplyGemLoadout(ids)
    if applying then
        UIErrorsFrame:AddMessage("Loadout already applying.", 1, 0.8, 0.3, 1)
        return
    end
    if UnitAffectingCombat and UnitAffectingCombat("player") then
        UIErrorsFrame:AddMessage("Leave combat to change gem loadout.", 1, 0.45, 0.45, 1)
        return
    end
    ids = type(ids) == "string" and Q.DecodeLoadout(ids) or ids
    if not ids then
        UIErrorsFrame:AddMessage("Invalid gem loadout code.", 1, 0.45, 0.45, 1)
        return
    end
    local sub, miss = 0, 0
    if Q.ResolveLoadoutIds then
        ids, sub, miss = Q.ResolveLoadoutIds(ids)
    end
    local slots = SlotList()
    local cur = Q.CaptureLoadout()
    queue, qn = {}, 1
    for i, sl in ipairs(slots) do
        local now, want = cur[i] or 0, ids[i] or 0
        if now ~= want then
            if now > 0 then
                local e, x = sl.equip, sl.idx
                queue[#queue + 1] = function() Unsocket(e, x) end
            end
            if want > 0 then
                local e, x, g = sl.equip, sl.idx, want
                queue[#queue + 1] = function() Socket(e, x, g) end
            end
        end
    end
    if #queue == 0 then
        UIErrorsFrame:AddMessage("Loadout already matches.", 0.7, 0.85, 1, 1)
        return
    end
    applying = true
    local acc = 0.4
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(self, dt)
        acc = acc + dt
        if acc < 0.45 then return end
        acc = 0
        local step = queue[qn]
        if not step then
            self:SetScript("OnUpdate", nil)
            applying = false
            local msg = "Gem loadout applied."
            if sub > 0 then
                msg = msg .. " " .. sub .. " used highest owned rank."
            end
            if miss > 0 then
                msg = msg .. " " .. miss .. " skipped (missing)."
            end
            UIErrorsFrame:AddMessage(msg, 0.6, 1, 0.6, 1)
            if _G.AIO and _G.AIO.Handle then
                _G.AIO.Handle("AstralgemServer", "RequestLoadout")
            end
            return
        end
        qn = qn + 1
        step()
    end)
end

function Q.LoadGemLoadout(name)
    local code = Store()[name]
    if not code then
        UIErrorsFrame:AddMessage("No loadout named " .. tostring(name), 1, 0.45, 0.45, 1)
        return
    end
    Q.DB().gemLoadoutLast = name
    Q.ApplyGemLoadout(code)
end

local function MakeBestRankOpt(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(18)
    local chk = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    chk:SetPoint("LEFT", -6, 0)
    chk:SetScale(0.72)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", 22, 0)
    label:SetText("Use highest owned rank")
    label:SetTextColor(0.82, 0.90, 0.98)
    chk:SetScript("OnClick", function(self)
        Q.DB().gemLoadoutBestRank = self:GetChecked() and true or false
        if row.onToggle then row.onToggle() end
    end)
    chk:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Highest owned rank")
        GameTooltip:AddLine("If a loadout gem is missing, socket the best tier you have of that family (T3 → T1).", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    chk:SetScript("OnLeave", GameTooltip_Hide)
    function row:Refresh()
        chk:SetChecked(Q.DB().gemLoadoutBestRank and true or false)
    end
    return row
end

local share

local function ShowShare(text, importMode)
    if not share then
        local f = CreateFrame("Frame", "qtAstralQOL_LoadoutShare", UIParent)
        f:SetSize(420, 220)
        f:SetPoint("CENTER", 0, 80)
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0.04, 0.05, 0.10, 0.96)
        f:SetBackdropBorderColor(0.32, 0.42, 0.70, 1)
        tinsert(UISpecialFrames, "qtAstralQOL_LoadoutShare")

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.title:SetPoint("TOP", 0, -12)

        f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.hint:SetPoint("TOP", f.title, "BOTTOM", 0, -4)
        f.hint:SetTextColor(0.7, 0.78, 0.9)

        f.edit = CreateFrame("EditBox", "qtAstralQOL_LoadoutShareEdit", f, "InputBoxTemplate")
        f.edit:SetPoint("TOPLEFT", 18, -52)
        f.edit:SetPoint("TOPRIGHT", -18, -52)
        f.edit:SetHeight(48)
        f.edit:SetAutoFocus(true)
        f.edit:SetMaxLetters(400)
        f.edit:SetScript("OnEscapePressed", function() f:Hide() end)

        f.ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.ok:SetSize(90, 22)
        f.ok:SetPoint("BOTTOM", 100, 14)

        f.link = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.link:SetSize(90, 22)
        f.link:SetPoint("BOTTOM", 0, 14)
        f.link:SetText("Chat link")
        f.link:SetScript("OnClick", function()
            local box = _G.qtAstralQOL_LoadoutName
            Q.InsertLoadoutLink(box and box:GetText() or Q.DB().gemLoadoutLast)
            f:Hide()
        end)

        local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        close:SetSize(90, 22)
        close:SetPoint("BOTTOM", -100, 14)
        close:SetText("Close")
        close:SetScript("OnClick", function() f:Hide() end)

        f.rankOpt = MakeBestRankOpt(f)
        f.rankOpt:SetPoint("BOTTOMLEFT", 18, 40)
        f.rankOpt:SetPoint("BOTTOMRIGHT", -18, 40)
        share = f
    end
    share.importMode = importMode
    if importMode then
        share.title:SetText("Import gem loadout")
        share.hint:SetText("Paste a QG1. code from notepad.")
        share.edit:SetText("")
        share.ok:SetText("Apply")
        share.ok:SetScript("OnClick", function()
            Q.ApplyGemLoadout(share.edit:GetText())
            share:Hide()
        end)
        share.link:Hide()
        share.ok:ClearAllPoints()
        share.ok:SetPoint("BOTTOM", 50, 14)
        share:SetHeight(248)
        share.rankOpt:Show()
        share.rankOpt:Refresh()
    else
        share.title:SetText("Export gem loadout")
        share.hint:SetText("Ctrl+A, Ctrl+C — or post a chat link.")
        share.edit:SetText(text or "")
        share.edit:HighlightText()
        share.ok:SetText("Copy done")
        share.ok:SetScript("OnClick", function() share:Hide() end)
        share.link:Show()
        share.ok:ClearAllPoints()
        share.ok:SetPoint("BOTTOM", 100, 14)
        share:SetHeight(220)
        share.rankOpt:Hide()
    end
    share:Show()
    share.edit:SetFocus()
    if not importMode then share.edit:HighlightText() end
end

function Q.ExportGemLoadout()
    ShowShare(Q.EncodeLoadout(), false)
end

function Q.ImportGemLoadout()
    ShowShare("", true)
end

-- ʕ •ᴥ•ʔ✿ chat carries a token; we turn it into a hover/click link locally ✿ ʕ •ᴥ•ʔ
local LINK_TYPE = "qtl"

local function SafeName(name)
    name = tostring(name or "Loadout")
    name = name:gsub("[%c%{%}%|:]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then name = "Loadout" end
    if #name > 18 then name = name:sub(1, 18) end
    return name
end

local function WireCode(code)
    return (code or ""):gsub("%+", "-"):gsub("/", "_")
end

local function ParsePair(body)
    if not body or body == "" then return end
    local name, code = tostring(body):match("^(.-):(QG1%..+)$")
    if not name then return end
    name = SafeName(name:gsub("_", " "))
    local ids = Q.DecodeLoadout(code)
    if not ids then return end
    return name, ids, code
end

function Q.MakeLoadoutToken(name)
    name = SafeName(name or Q.DB().gemLoadoutLast)
    local token = "{QGL:" .. name:gsub(" ", "_") .. ":" .. WireCode(Q.EncodeLoadout()) .. "}"
    if #token > 240 then
        UIErrorsFrame:AddMessage("Loadout link is too long for chat.", 1, 0.45, 0.45, 1)
        return
    end
    return token
end

function Q.InsertLoadoutLink(name)
    local token = Q.MakeLoadoutToken(name)
    if not token then return end
    local eb
    if ChatEdit_GetActiveWindow then eb = ChatEdit_GetActiveWindow() end
    eb = eb or ChatFrameEditBox or (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox)
    if eb and eb:IsShown() then
        eb:Insert(token)
        eb:SetFocus()
        return
    end
    if ChatFrame_OpenChat then
        ChatFrame_OpenChat(token)
    elseif eb then
        eb:Show()
        eb:SetText(token)
        eb:SetFocus()
    end
end

local function MissingMap(ids)
    local need, have = {}, {}
    for _, id in ipairs(ids) do
        if id and id > 0 then need[id] = (need[id] or 0) + 1 end
    end
    local stock = Q.Stock()
    for id in pairs(need) do
        have[id] = tonumber(stock[id]) or 0
    end
    for _, id in ipairs(Q.CaptureLoadout()) do
        if id and id > 0 then have[id] = (have[id] or 0) + 1 end
    end
    local miss = {}
    for id, n in pairs(need) do
        miss[id] = (have[id] or 0) < n
    end
    return miss
end

local function GemLabel(id)
    if not id or id <= 0 then return "Empty" end
    local cat = Q.Cat(id)
    local tier = cat and cat.tier
    local name = Q.GemShortName(id)
    if tier then return "T" .. tier .. " " .. name end
    return name
end

local function MakeGemCell(parent, size, mouse)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    b:EnableMouse(mouse and true or false)
    local ring = b:CreateTexture(nil, "BORDER")
    ring:SetAllPoints()
    ring:SetTexture("Interface\\Buttons\\WHITE8X8")
    b.ring = ring
    local inner = b:CreateTexture(nil, "ARTWORK")
    inner:SetPoint("TOPLEFT", 1, -1)
    inner:SetPoint("BOTTOMRIGHT", -1, 1)
    inner:SetTexture("Interface\\Buttons\\WHITE8X8")
    inner:SetVertexColor(0.06, 0.07, 0.11, 1)
    b.inner = inner
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetDrawLayer("ARTWORK", 1)
    b.icon = icon
    if mouse then
        b:SetScript("OnEnter", function(self)
            if not (self._id and self._id > 0) then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. self._id)
            local cat = Q.Cat(self._id)
            if cat then Q.AddEventTooltip(cat.eventType) end
            if self._missing then
                GameTooltip:AddLine("Not in stash or sockets.", 1, 0.45, 0.45)
            elseif self._sub and self._wanted and self._wanted ~= self._id then
                GameTooltip:AddLine("Using highest owned rank (loadout: " .. GemLabel(self._wanted) .. ").", 1, 0.86, 0.40, true)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
    end
    return b
end

local function PaintCell(b, id, color, missing, sub, wanted)
    b._id = id
    b._missing = missing
    b._sub = sub
    b._wanted = wanted
    local rgb = Q.QUALITY_RGB[color] or Q.QUALITY_RGB[3]
    b.ring:SetVertexColor(rgb[1], rgb[2], rgb[3], 0.95)
    if id and id > 0 then
        Q.SetGemIcon(b.icon, id)
        if missing then
            b.icon:SetVertexColor(1, 0.42, 0.42, 1)
        elseif sub then
            b.icon:SetVertexColor(1, 0.86, 0.40, 1)
        else
            b.icon:SetVertexColor(1, 1, 1, 1)
        end
        b.icon:Show()
        b.inner:Hide()
    else
        b.icon:Hide()
        b.inner:Show()
    end
end

local function BuildGrid(parent, iconSize, mouse)
    local grid = { rows = {} }
    local y = 0
    for i, sc in ipairs(Q.SLOT_SCHEMA) do
        local row = CreateFrame("Frame", nil, parent)
        row:SetHeight(iconSize + 4)
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", 0, 0)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.label:SetPoint("LEFT", 0, 0)
        row.label:SetWidth(52)
        row.label:SetJustifyH("LEFT")
        row.label:SetText(sc.label)
        row.label:SetTextColor(0.70, 0.80, 0.94)
        row.cells = {}
        for gi = 1, sc.n do
            local cell = MakeGemCell(row, iconSize, mouse)
            cell:SetPoint("LEFT", 56 + (gi - 1) * (iconSize + 3), 0)
            row.cells[gi] = cell
        end
        row.names = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.names:SetPoint("LEFT", 56 + sc.n * (iconSize + 3) + 6, 0)
        row.names:SetPoint("RIGHT", -4, 0)
        row.names:SetJustifyH("LEFT")
        row.names:SetNonSpaceWrap(false)
        grid.rows[i] = row
        y = y + iconSize + 6
    end
    grid.height = y
    function grid:Paint(ids, resolved)
        resolved = resolved or ids
        local owned = MissingMap(ids)
        local n = 0
        local missing, subs = 0, 0
        for ri, sc in ipairs(Q.SLOT_SCHEMA) do
            local row = self.rows[ri]
            local labels = {}
            for gi = 1, sc.n do
                n = n + 1
                local orig = ids[n] or 0
                local use = resolved[n] or 0
                local sub = orig > 0 and use > 0 and orig ~= use
                local gone = orig > 0 and (use == 0 or (use == orig and owned[orig]))
                if gone then missing = missing + 1 end
                if sub then subs = subs + 1 end
                local shown = (use > 0 and use) or orig
                PaintCell(row.cells[gi], shown, sc.colors and sc.colors[gi] or 3, gone, sub, orig)
                if shown > 0 then labels[#labels + 1] = GemLabel(shown) end
            end
            row.names:SetText(table.concat(labels, "  ·  "))
        end
        return missing, subs
    end
    return grid
end

local hoverTip

local function HideLoadoutTip()
    if hoverTip then
        hoverTip:SetScript("OnUpdate", nil)
        hoverTip:Hide()
    end
end

local function ShowLoadoutTip(name, ids)
    if not ids then return end
    if not hoverTip then
        local f = CreateFrame("Frame", "qtAstralQOL_LoadoutTip", UIParent)
        f:SetFrameStrata("TOOLTIP")
        f:SetWidth(268)
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0.03, 0.04, 0.09, 0.97)
        f:SetBackdropBorderColor(0.40, 0.52, 0.82, 1)
        f:SetClampedToScreen(true)
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.title:SetPoint("TOPLEFT", 12, -10)
        f.title:SetPoint("RIGHT", -12, 0)
        f.title:SetJustifyH("LEFT")
        f.gridHost = CreateFrame("Frame", nil, f)
        f.gridHost:SetPoint("TOPLEFT", 12, -28)
        f.gridHost:SetPoint("RIGHT", -8, 0)
        f.grid = BuildGrid(f.gridHost, 16, false)
        f.gridHost:SetHeight(f.grid.height)
        f.foot = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        f.foot:SetPoint("BOTTOMLEFT", 12, 10)
        f.foot:SetPoint("BOTTOMRIGHT", -12, 10)
        f.foot:SetJustifyH("LEFT")
        f.foot:SetText("Click to preview and add.")
        hoverTip = f
    end
    hoverTip.title:SetText("Gem Loadout  ·  " .. (name or "Loadout"))
    hoverTip.grid:Paint(ids)
    hoverTip:SetHeight(28 + hoverTip.grid.height + 22)
    hoverTip:ClearAllPoints()
    hoverTip:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale() or 1
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + 18, y / scale + 12)
    end)
    hoverTip:Show()
end

local offer

local function ShowLoadoutOffer(name, ids, code)
    HideLoadoutTip()
    if not ids then return end
    name = SafeName(name)
    code = code or Q.EncodeLoadout(ids)
    if not offer then
        local f = CreateFrame("Frame", "qtAstralQOL_LoadoutOffer", UIParent)
        f:SetSize(360, 318)
        f:SetPoint("CENTER", 0, 60)
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0.04, 0.05, 0.10, 0.96)
        f:SetBackdropBorderColor(0.32, 0.42, 0.70, 1)
        f:SetClampedToScreen(true)
        tinsert(UISpecialFrames, "qtAstralQOL_LoadoutOffer")

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.title:SetPoint("TOP", 0, -12)
        f.title:SetText("Add gem loadout")

        f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.hint:SetPoint("TOP", f.title, "BOTTOM", 0, -3)
        f.hint:SetTextColor(0.7, 0.78, 0.9)
        f.hint:SetText("Hover a socket for gem stats.")

        local nameWrap = CreateFrame("Frame", nil, f)
        nameWrap:SetHeight(20)
        nameWrap:SetPoint("TOPLEFT", 16, -48)
        nameWrap:SetPoint("TOPRIGHT", -16, -48)
        nameWrap:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        nameWrap:SetBackdropColor(0.02, 0.03, 0.07, 0.96)
        nameWrap:SetBackdropBorderColor(0.22, 0.36, 0.55, 1)
        f.nameBox = CreateFrame("EditBox", "qtAstralQOL_LoadoutOfferName", nameWrap)
        f.nameBox:SetPoint("LEFT", 6, 1)
        f.nameBox:SetPoint("RIGHT", -6, 1)
        f.nameBox:SetHeight(16)
        f.nameBox:SetAutoFocus(false)
        f.nameBox:SetMaxLetters(24)
        f.nameBox:SetFontObject(GameFontHighlightSmall)
        f.nameBox:SetTextInsets(2, 2, 0, 0)
        f.nameBox:SetJustifyH("LEFT")
        f.nameBox:SetTextColor(0.82, 0.90, 0.98)
        f.nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        f.gridHost = CreateFrame("Frame", nil, f)
        f.gridHost:SetPoint("TOPLEFT", 16, -76)
        f.gridHost:SetPoint("RIGHT", -12, 0)
        f.grid = BuildGrid(f.gridHost, 26, true)
        f.gridHost:SetHeight(f.grid.height)

        f.miss = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.miss:SetPoint("TOPLEFT", f.gridHost, "BOTTOMLEFT", 0, -8)
        f.miss:SetPoint("RIGHT", -16, 0)
        f.miss:SetJustifyH("LEFT")

        f.rankOpt = MakeBestRankOpt(f)
        f.rankOpt:SetPoint("BOTTOMLEFT", 16, 40)
        f.rankOpt:SetPoint("BOTTOMRIGHT", -16, 40)
        f.rankOpt.onToggle = function()
            if Q.RefreshLoadoutOffer then Q.RefreshLoadoutOffer() end
        end

        f.save = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.save:SetSize(90, 22)
        f.save:SetPoint("BOTTOM", -100, 14)
        f.save:SetText("Save")
        f.save:SetScript("OnClick", function()
            Q.SaveGemLoadout(f.nameBox:GetText(), f._code)
            f:Hide()
        end)

        f.apply = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.apply:SetSize(90, 22)
        f.apply:SetPoint("BOTTOM", 0, 14)
        f.apply:SetText("Apply")
        f.apply:SetScript("OnClick", function()
            Q.ApplyGemLoadout(f._ids)
            f:Hide()
        end)

        local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        close:SetSize(90, 22)
        close:SetPoint("BOTTOM", 100, 14)
        close:SetText("Close")
        close:SetScript("OnClick", function() f:Hide() end)
        offer = f
    end
    offer._ids = ids
    offer._code = code
    offer.nameBox:SetText(name)
    offer.rankOpt:Refresh()
    Q.RefreshLoadoutOffer()
    offer:Show()
    offer.nameBox:ClearFocus()
end

function Q.RefreshLoadoutOffer()
    if not (offer and offer._ids) then return end
    local resolved = offer._ids
    if Q.ResolveLoadoutIds then
        resolved = Q.ResolveLoadoutIds(offer._ids)
    end
    local missing, subs = offer.grid:Paint(offer._ids, resolved)
    if missing > 0 and subs > 0 then
        offer.miss:SetText(subs .. " will use your highest rank.  " .. missing .. " still missing.")
        offer.miss:SetTextColor(1, 0.72, 0.40)
    elseif subs > 0 then
        offer.miss:SetText(subs .. " gem" .. (subs == 1 and "" or "s") .. " will use your highest owned rank.")
        offer.miss:SetTextColor(1, 0.86, 0.40)
    elseif missing > 0 then
        offer.miss:SetText(missing .. " gem" .. (missing == 1 and "" or "s") .. " missing from stash.")
        offer.miss:SetTextColor(1, 0.55, 0.45)
    else
        offer.miss:SetText("All gems are in stash or already socketed.")
        offer.miss:SetTextColor(0.55, 0.90, 0.62)
    end
    offer:SetHeight(76 + offer.grid.height + 74)
end

local function HandleLoadoutLink(link, text)
    local body = link and link:match("^" .. LINK_TYPE .. ":(.+)$")
    local name, ids, code = ParsePair(body)
    if not ids and type(text) == "string" then
        local shown = text:match("%[Gem Loadout:%s*(.-)%]")
        name, ids, code = ParsePair((shown or "Loadout"):gsub(" ", "_") .. ":" .. (body or ""))
    end
    return name, ids, code
end

local hookedRef
local function InstallClickHook()
    if hookedRef or not SetItemRef then return end
    hookedRef = true
    local orig = SetItemRef
    SetItemRef = function(link, text, button, chatFrame)
        if type(link) == "string" and link:sub(1, #LINK_TYPE + 1) == LINK_TYPE .. ":" then
            local name, ids, code = HandleLoadoutLink(link, text)
            if ids then
                if IsShiftKeyDown() then
                    local token = "{QGL:" .. SafeName(name):gsub(" ", "_") .. ":" .. WireCode(code or Q.EncodeLoadout(ids)) .. "}"
                    local eb
                    if ChatEdit_GetActiveWindow then eb = ChatEdit_GetActiveWindow() end
                    eb = eb or ChatFrameEditBox or (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox)
                    if eb and eb:IsShown() then
                        eb:Insert(token)
                    elseif ChatFrame_OpenChat then
                        ChatFrame_OpenChat(token)
                    end
                    return
                end
                ShowLoadoutOffer(name, ids, code)
            end
            return
        end
        return orig(link, text, button, chatFrame)
    end
end

local function HookChatFrame(cf)
    if not cf then return end
    if not (cf.HasScript and cf:HasScript("OnHyperlinkEnter")) then return end
    if cf._qolLoadoutEnter == cf:GetScript("OnHyperlinkEnter") then return end
    local origEnter = cf:GetScript("OnHyperlinkEnter")
    local origLeave = cf:GetScript("OnHyperlinkLeave")
    local function enter(self, link, text, ...)
        if origEnter then origEnter(self, link, text, ...) end
        if type(link) == "string" and link:sub(1, #LINK_TYPE + 1) == LINK_TYPE .. ":" then
            local name, ids = HandleLoadoutLink(link, text)
            if ids then ShowLoadoutTip(name, ids) end
        end
    end
    local function leave(self, ...)
        if origLeave then origLeave(self, ...) end
        HideLoadoutTip()
    end
    cf:SetScript("OnHyperlinkEnter", enter)
    cf:SetScript("OnHyperlinkLeave", leave)
    cf._qolLoadoutEnter = enter
end

local function HookAllChatFrames()
    for i = 1, 20 do
        HookChatFrame(_G["ChatFrame" .. i])
    end
end

local function TokenToLink(body)
    local name, ids, code = ParsePair(body)
    if not ids then return "{QGL:" .. body .. "}" end
    return string.format("|cff80e0ff|H%s:%s:%s|h[Gem Loadout: %s]|h|r",
        LINK_TYPE, SafeName(name):gsub(" ", "_"), WireCode(code), SafeName(name))
end

local function ChatFilter(_, _, msg, ...)
    if type(msg) ~= "string" or not msg:find("{QGL:", 1, true) then return false end
    return false, msg:gsub("{QGL:([^}]+)}", TokenToLink), ...
end

if ChatFrame_AddMessageEventFilter then
    local events = {
        "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE",
        "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
        "CHAT_MSG_CHANNEL",
        "CHAT_MSG_BATTLEGROUND", "CHAT_MSG_BATTLEGROUND_LEADER",
    }
    for i = 1, #events do
        ChatFrame_AddMessageEventFilter(events[i], ChatFilter)
    end
end

local linkBoot = CreateFrame("Frame")
linkBoot:RegisterEvent("PLAYER_LOGIN")
linkBoot:RegisterEvent("PLAYER_ENTERING_WORLD")
linkBoot:SetScript("OnEvent", function(self, event)
    InstallClickHook()
    HookAllChatFrames()
    if event ~= "PLAYER_LOGIN" then return end
    local acc = 0
    self:SetScript("OnUpdate", function(me, dt)
        acc = acc + dt
        if acc < 2 then return end
        HookAllChatFrames()
        if type(hooksecurefunc) == "function" and _G.FCF_OpenNewWindow then
            hooksecurefunc("FCF_OpenNewWindow", HookAllChatFrames)
        end
        me:SetScript("OnUpdate", nil)
    end)
end)
InstallClickHook()
HookAllChatFrames()

function Q.LoadoutSlash(msg)
    local rest = msg:match("^loadout%s*(.*)$") or ""
    rest = rest:gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, arg = rest:match("^(%S+)%s*(.*)$")
    cmd = (cmd or ""):lower()
    if cmd == "export" or rest == "" then
        Q.ExportGemLoadout()
    elseif cmd == "import" then
        if arg ~= "" then Q.ApplyGemLoadout(arg) else Q.ImportGemLoadout() end
    elseif cmd == "link" or cmd == "share" then
        Q.InsertLoadoutLink(arg ~= "" and arg or nil)
    elseif cmd == "rank" or cmd == "bestrank" then
        local db = Q.DB()
        db.gemLoadoutBestRank = not db.gemLoadoutBestRank
        DEFAULT_CHAT_FRAME:AddMessage("|cff80e0ffqtAstralQOL|r highest owned rank: " .. (db.gemLoadoutBestRank and "on" or "off"))
        if Q.RefreshLoadoutOffer then Q.RefreshLoadoutOffer() end
    elseif cmd == "save" then
        Q.SaveGemLoadout(arg)
    elseif cmd == "load" or cmd == "apply" then
        Q.LoadGemLoadout(arg)
    elseif cmd == "delete" or cmd == "del" or cmd == "remove" then
        Q.DeleteGemLoadout(arg)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff80e0ffqtAstralQOL|r  /qgems loadout export  |  import  |  link  |  rank  |  save Name  |  load Name  |  delete Name")
    end
end

local BTN = {
    primary = {
        idle = { 0.10, 0.20, 0.42, 0.95 },
        hover = { 0.20, 0.36, 0.68, 1.00 },
        border = { 0.38, 0.58, 0.85, 1.0 },
        text = { 0.86, 0.94, 1.00 },
    },
    secondary = {
        idle = { 0.05, 0.09, 0.18, 0.95 },
        hover = { 0.12, 0.22, 0.38, 1.00 },
        border = { 0.22, 0.36, 0.55, 1.0 },
        text = { 0.82, 0.90, 0.98 },
    },
}

local function SkinBox(f, bg, br)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 0.94)
    f:SetBackdropBorderColor(br[1], br[2], br[3], br[4] or 1)
end

local function Chip(parent, label, w, kind, click)
    local v = BTN[kind] or BTN.primary
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, 18)
    SkinBox(b, v.idle, v.border)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER", 0, 1)
    fs:SetText(label)
    fs:SetTextColor(v.text[1], v.text[2], v.text[3])
    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(v.hover[1], v.hover[2], v.hover[3], v.hover[4])
        self:SetBackdropBorderColor(0.58, 0.88, 1.00, 1)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(v.idle[1], v.idle[2], v.idle[3], v.idle[4])
        self:SetBackdropBorderColor(v.border[1], v.border[2], v.border[3], v.border[4])
    end)
    b:SetScript("OnClick", click)
    return b
end

function Q.AttachLoadoutUI(panel)
    if not panel then return end
    if panel._qolLoadoutBar then return end

    local bar = CreateFrame("Frame", nil, panel)
    panel._qolLoadoutBar = bar
    panel._qolLoadout = true
    bar:SetSize(240, 58)
    bar:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 22, 12)
    bar:SetFrameLevel((panel:GetFrameLevel() or 1) + 20)
    bar:EnableMouse(true)
    SkinBox(bar, { 0.04, 0.06, 0.12, 0.94 }, { 0.32, 0.48, 0.72, 1 })
    bar:Show()

    local nameBox
    local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 8, -5)
    title:SetText("Loadouts")
    title:SetTextColor(0.60, 0.85, 1.00)

    local linkBtn = Chip(bar, "Link", 36, "secondary", function()
        Q.InsertLoadoutLink(nameBox and nameBox:GetText())
    end)
    linkBtn:SetSize(36, 16)
    linkBtn:SetPoint("TOPRIGHT", -5, -4)
    title:SetPoint("RIGHT", linkBtn, "LEFT", -4, 0)
    title:SetJustifyH("LEFT")
    linkBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Chat link")
        GameTooltip:AddLine("Inserts a loadout link into chat. Anyone with this addon can hover to preview and click to add it.", 0.8, 0.85, 1, true)
        GameTooltip:Show()
    end)
    linkBtn:HookScript("OnLeave", GameTooltip_Hide)

    local combo = CreateFrame("Frame", nil, bar)
    combo:SetHeight(18)
    combo:SetPoint("TOPLEFT", 8, -20)
    combo:SetPoint("TOPRIGHT", -8, -20)
    SkinBox(combo, { 0.02, 0.03, 0.07, 0.96 }, { 0.22, 0.36, 0.55, 1 })

    nameBox = CreateFrame("EditBox", "qtAstralQOL_LoadoutName", combo)
    nameBox:SetPoint("LEFT", 6, 1)
    nameBox:SetPoint("RIGHT", -18, 1)
    nameBox:SetHeight(16)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(24)
    nameBox:SetFontObject(GameFontHighlightSmall)
    nameBox:SetTextInsets(2, 2, 0, 0)
    nameBox:SetJustifyH("LEFT")
    nameBox:SetTextColor(0.82, 0.90, 0.98)
    nameBox:SetText(Q.DB().gemLoadoutLast or "PvE")
    nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    nameBox:SetScript("OnEnterPressed", function(self)
        local n = self:GetText()
        if Store()[n] then Q.LoadGemLoadout(n) else Q.SaveGemLoadout(n) end
        self:ClearFocus()
    end)

    local menu = CreateFrame("Frame", "qtAstralQOL_LoadoutMenu", UIParent)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetToplevel(true)
    menu:SetWidth(220)
    menu:Hide()
    SkinBox(menu, { 0.03, 0.05, 0.10, 0.98 }, { 0.38, 0.58, 0.85, 1 })

    local rows = {}
    local ROW_H = 16

    local function HideMenu()
        menu:Hide()
        menu:SetScript("OnUpdate", nil)
    end

    local function RefreshMenu()
        local names = Names()
        local n = math.max(#names, 1)
        for i = 1, math.max(n, #rows) do
            local r = rows[i]
            if not r then
                r = CreateFrame("Button", nil, menu)
                r:SetHeight(ROW_H)
                r:SetPoint("LEFT", 3, 0)
                r:SetPoint("RIGHT", -3, 0)
                if i == 1 then
                    r:SetPoint("TOP", 0, -4)
                else
                    r:SetPoint("TOP", rows[i - 1], "BOTTOM", 0, 0)
                end
                r.bg = r:CreateTexture(nil, "BACKGROUND")
                r.bg:SetAllPoints()
                r.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
                r.bg:SetVertexColor(0.12, 0.20, 0.36, 0)
                r.label = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                r.label:SetPoint("LEFT", 6, 0)
                r.label:SetPoint("RIGHT", -16, 0)
                r.label:SetJustifyH("LEFT")
                r.del = CreateFrame("Button", nil, r)
                r.del:SetSize(14, 14)
                r.del:SetPoint("RIGHT", -1, 0)
                local dx = r.del:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                dx:SetPoint("CENTER", 1, 1)
                dx:SetText("x")
                dx:SetTextColor(0.90, 0.42, 0.42)
                r.del.text = dx
                r:SetScript("OnEnter", function(self)
                    if self._name then self.bg:SetVertexColor(0.20, 0.36, 0.68, 0.80) end
                end)
                r:SetScript("OnLeave", function(self)
                    self.bg:SetVertexColor(0.12, 0.20, 0.36, 0)
                end)
                r:SetScript("OnClick", function(self)
                    if not self._name then return end
                    nameBox:SetText(self._name)
                    Q.DB().gemLoadoutLast = self._name
                    HideMenu()
                end)
                r.del:SetScript("OnEnter", function(self)
                    self.text:SetTextColor(1, 0.62, 0.62)
                end)
                r.del:SetScript("OnLeave", function(self)
                    self.text:SetTextColor(0.90, 0.42, 0.42)
                end)
                r.del:SetScript("OnClick", function(self)
                    local parent = self:GetParent()
                    if parent._name then
                        Q.DeleteGemLoadout(parent._name)
                    end
                end)
                rows[i] = r
            end
            local name = names[i]
            if name then
                r._name = name
                r.label:SetText(name)
                r.label:SetTextColor(0.82, 0.90, 0.98)
                r.del:Show()
                r:Enable()
                r:Show()
            elseif i == 1 then
                r._name = nil
                r.label:SetText("none saved")
                r.label:SetTextColor(0.55, 0.68, 0.82)
                r.del:Hide()
                r:Disable()
                r:Show()
            else
                r._name = nil
                r:Hide()
            end
        end
        menu:SetHeight(8 + n * ROW_H)
    end

    local function ToggleMenu()
        if menu:IsShown() then
            HideMenu()
            return
        end
        RefreshMenu()
        menu:ClearAllPoints()
        menu:SetPoint("BOTTOMLEFT", combo, "TOPLEFT", 0, 2)
        menu:SetFrameLevel((bar:GetFrameLevel() or 1) + 40)
        menu:Show()
        menu:SetScript("OnUpdate", function(self)
            if MouseIsOver(self) or MouseIsOver(combo) then return end
            if IsMouseButtonDown("LeftButton") then HideMenu() end
        end)
    end

    local arrow = CreateFrame("Button", nil, combo)
    arrow:SetSize(16, 16)
    arrow:SetPoint("RIGHT", -1, 0)
    arrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    arrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    arrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    local hilite = arrow:GetHighlightTexture()
    if hilite then hilite:SetBlendMode("ADD") end
    arrow:SetScript("OnClick", ToggleMenu)

    Chip(bar, "Save", 52, "primary", function() Q.SaveGemLoadout(nameBox:GetText()) end)
        :SetPoint("BOTTOMLEFT", 8, 6)
    Chip(bar, "Load", 52, "primary", function() Q.LoadGemLoadout(nameBox:GetText()) end)
        :SetPoint("BOTTOMLEFT", 64, 6)
    Chip(bar, "Export", 52, "secondary", function() Q.ExportGemLoadout() end)
        :SetPoint("BOTTOMLEFT", 120, 6)
    Chip(bar, "Import", 52, "secondary", function() Q.ImportGemLoadout() end)
        :SetPoint("BOTTOMLEFT", 176, 6)

    panel._qolLoadoutName = nameBox
    panel:HookScript("OnHide", HideMenu)

    function Q.RefreshLoadoutList()
        if not nameBox:HasFocus() then
            local last = Q.DB().gemLoadoutLast
            if last and last ~= "" then nameBox:SetText(last) end
        end
        local n = #Names()
        title:SetText(n == 0 and "Loadouts" or ("Loadouts  ·  " .. n))
        if menu:IsShown() then RefreshMenu() end
    end
    Q.RefreshLoadoutList()
    if Q.LayoutGemTab then Q.LayoutGemTab(panel) end
end

local function TryAttach()
    local PA = Q.PA()
    if not PA then return false end
    local AG = PA.AstralGems
    local panel = AG and AG.panel
    if not panel then
        local mf = PA.mainFrame
        if mf and mf.content and mf.content._tabBuilt then
            panel = mf.content._tabBuilt["AstralGems"]
        end
    end
    if not panel then return false end
    if Q.EnhanceGemTab then Q.EnhanceGemTab(panel) end
    Q.AttachLoadoutUI(panel)
    return panel._qolLoadoutBar and true or false
end

local wrappedGemTab

local function WrapGemTabBuilder()
    local PA = Q.PA()
    if not PA then return end
    PA._tabContent = PA._tabContent or {}
    local orig = PA._tabContent["AstralGems"]
    if type(orig) ~= "function" or orig == wrappedGemTab then return end
    wrappedGemTab = function(host)
        orig(host)
        TryAttach()
        if host then host:HookScript("OnShow", TryAttach) end
    end
    PA._tabContent["AstralGems"] = wrappedGemTab
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    local acc = 0
    boot:SetScript("OnUpdate", function(self, dt)
        acc = acc + dt
        WrapGemTabBuilder()
        local ok = TryAttach()
        local PA = Q.PA()
        local mf = PA and PA.mainFrame
        if mf and not mf._qolLoadoutHook then
            mf._qolLoadoutHook = true
            mf:HookScript("OnShow", TryAttach)
        end
        if (wrappedGemTab and acc > 3) or acc > 90 then
            self:SetScript("OnUpdate", nil)
        end
    end)
end)

