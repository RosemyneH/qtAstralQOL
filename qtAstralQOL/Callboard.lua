local Q = qtAstralQOL

local PREFIX = "qAQLCB"
local VERSION = "4"
local MAX_SLOTS = 6

local CAT_LABEL = {
    [1] = "Slay", [2] = "Rare", [3] = "Elite", [4] = "Skin",
    [5] = "Herb", [6] = "Mine", [7] = "Fish", [8] = "Cloth",
    [9] = "Craft", [10] = "Quests", [11] = "LFG",
}

local CAT_COLOR = {
    [1]  = { 0.92, 0.62, 0.55 },
    [2]  = { 0.92, 0.55, 0.92 },
    [3]  = { 0.65, 0.55, 0.92 },
    [4]  = { 0.82, 0.66, 0.55 },
    [5]  = { 0.55, 0.92, 0.55 },
    [6]  = { 0.66, 0.66, 0.66 },
    [7]  = { 0.55, 0.82, 0.92 },
    [8]  = { 0.92, 0.92, 0.92 },
    [9]  = { 0.92, 0.82, 0.55 },
    [10] = { 0.65, 0.82, 1.00 },
    [11] = { 0.85, 0.55, 1.00 },
}

local DUNGEON_SHORT = {
    [201] = "SFK", [202] = "Stocks", [203] = "VC", [204] = "WC",
    [205] = "RFK", [206] = "BFD", [207] = "Ulda", [208] = "Gnom",
    [209] = "ST", [210] = "RFD", [211] = "SM", [212] = "ZF",
    [213] = "BRS", [214] = "BRD", [215] = "Scholo", [216] = "Strat",
    [217] = "Mara", [218] = "RFC", [219] = "DM",
}

local DUNGEON_ICON = {
    SFK    = "Interface\\LFGFrame\\LFGIcon-ShadowfangKeep",
    Stocks = "Interface\\LFGFrame\\LFGIcon-TheStockade",
    VC     = "Interface\\LFGFrame\\LFGIcon-Deadmines",
    WC     = "Interface\\LFGFrame\\LFGIcon-WailingCaverns",
    RFK    = "Interface\\LFGFrame\\LFGIcon-RazorfenKraul",
    BFD    = "Interface\\LFGFrame\\LFGIcon-BlackfathomDeeps",
    Ulda   = "Interface\\LFGFrame\\LFGIcon-Uldaman",
    Gnom   = "Interface\\LFGFrame\\LFGIcon-Gnomeregan",
    ST     = "Interface\\LFGFrame\\LFGIcon-SunkenTemple",
    RFD    = "Interface\\LFGFrame\\LFGIcon-RazorfenDowns",
    SM     = "Interface\\LFGFrame\\LFGIcon-ScarletMonastery",
    ZF     = "Interface\\LFGFrame\\LFGIcon-ZulFarak",
    BRS    = "Interface\\LFGFrame\\LFGIcon-BlackrockSpire",
    BRD    = "Interface\\LFGFrame\\LFGIcon-BlackrockDepths",
    Scholo = "Interface\\LFGFrame\\LFGIcon-Scholomance",
    Strat  = "Interface\\LFGFrame\\LFGIcon-Stratholme",
    Mara   = "Interface\\LFGFrame\\LFGIcon-Maraudon",
    RFC    = "Interface\\LFGFrame\\LFGIcon-RagefireChasm",
    DM     = "Interface\\LFGFrame\\LFGIcon-DireMaul",
}

local CAT_ICON = {
    [1]  = "Interface\\Icons\\Ability_Hunter_SniperShot",
    [2]  = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    [3]  = "Interface\\Icons\\Spell_Nature_Lightning",
    [4]  = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    [5]  = "Interface\\Icons\\INV_Misc_Flower_02",
    [6]  = "Interface\\Icons\\INV_Pick_02",
    [7]  = "Interface\\Icons\\Trade_Fishing",
    [8]  = "Interface\\Icons\\INV_Fabric_Silk_02",
    [9]  = "Interface\\Icons\\Trade_BlackSmithing",
    [10] = "Interface\\Icons\\INV_Misc_Book_09",
    [11] = "Interface\\LFGFrame\\LFGIcon-Quest",
}

local DUNGEON_NAMES = {
    [201] = "Shadowfang Keep", [202] = "The Stockade", [203] = "The Deadmines",
    [204] = "Wailing Caverns", [205] = "Razorfen Kraul", [206] = "Blackfathom Deeps",
    [207] = "Uldaman", [208] = "Gnomeregan", [209] = "Sunken Temple",
    [210] = "Razorfen Downs", [211] = "Scarlet Monastery", [212] = "Zul'Farrak",
    [213] = "Blackrock Spire", [214] = "Blackrock Depths", [215] = "Scholomance",
    [216] = "Stratholme", [217] = "Maraudon", [218] = "Ragefire Chasm",
    [219] = "Dire Maul",
}

local ZONE_NAMES = {
    "Elwynn Forest", "Westfall", "Duskwood", "Redridge Mountains",
    "Stranglethorn Vale", "Swamp of Sorrows", "Blasted Lands", "Burning Steppes",
    "Searing Gorge", "Badlands", "Loch Modan", "Dun Morogh", "Wetlands",
    "Arathi Highlands", "Hillsbrad Foothills", "Alterac Mountains",
    "Silverpine Forest", "Tirisfal Glades", "Western Plaguelands",
    "Eastern Plaguelands", "Durotar", "The Barrens", "Barrens", "Mulgore",
    "Stonetalon Mountains", "Ashenvale", "Darkshore", "Teldrassil", "Felwood",
    "Winterspring", "Moonglade", "Azshara", "Dustwallow Marsh", "Thousand Needles",
    "Tanaris", "Un'Goro Crater", "Silithus", "Desolace", "Feralas",
    "Eastern Kingdoms", "Kalimdor", "Hinterlands", "The Hinterlands",
}

table.sort(ZONE_NAMES, function(a, b) return #a > #b end)

local ZONE_ABBR = {
    ["eastern plaguelands"] = "EPL",
    ["western plaguelands"] = "WPL",
    ["elwynn forest"] = "Elwynn",
    ["redridge mountains"] = "RR",
    ["stranglethorn vale"] = "STV",
    ["swamp of sorrows"] = "SoS",
    ["blasted lands"] = "BL",
    ["burning steppes"] = "BS",
    ["searing gorge"] = "SG",
    ["loch modan"] = "Loch",
    ["dun morogh"] = "Dun",
    ["arathi highlands"] = "Arathi",
    ["hillsbrad foothills"] = "Hillsbrad",
    ["alterac mountains"] = "Alterac",
    ["silverpine forest"] = "Silverpine",
    ["tirisfal glades"] = "Tirisfal",
    ["the barrens"] = "Barrens",
    ["barrens"] = "Barrens",
    ["stonetalon mountains"] = "Stonetalon",
    ["dustwallow marsh"] = "Dustwallow",
    ["thousand needles"] = "Needles",
    ["un'goro crater"] = "Un'Goro",
    ["eastern kingdoms"] = "EK",
    ["the hinterlands"] = "Hinterlands",
    ["hinterlands"] = "Hinterlands",
}

local function ZoneShort(name)
    if not name or name == "" then return "" end
    return ZONE_ABBR[name:lower()] or name
end

local DUNGEON_ALIAS = {
    sfk = 201, stockade = 202, stocks = 202, deadmines = 203, vc = 203,
    wc = 204, rfk = 205, bfd = 206, ulda = 207, uldaman = 207,
    gnom = 208, gnomeregan = 208, st = 209, rfd = 210, sm = 211,
    zf = 212, brs = 213, ubrs = 213, lbrs = 213, brd = 214,
    scholo = 215, strat = 216, mara = 217, rfc = 218, dm = 219,
}

local function CatHex(cat)
    local c = CAT_COLOR[cat] or { 0.55, 0.55, 0.55 }
    return string.format("%02x%02x%02x",
        math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255))
end

local function DungeonShort(slot)
    local z = tonumber(slot.zone or slot.zoneId or slot.map or slot.mapId)
    if DUNGEON_SHORT[z] then return DUNGEON_SHORT[z] end
    local hay = ((slot.title or "") .. " " .. (slot.objective or "")):lower()
    local best, bestLen
    for id, name in pairs(DUNGEON_NAMES) do
        if hay:find(name:lower(), 1, true) then
            if not bestLen or #name > bestLen then
                best, bestLen = DUNGEON_SHORT[id], #name
            end
        end
    end
    if best then return best end
    local cat = tonumber(slot.cat) or 0
    local lfg = hay:find("lfg", 1, true) or hay:find("looking for group", 1, true)
    if cat == 2 or cat == 3 or cat == 11 or lfg then
        for alias, id in pairs(DUNGEON_ALIAS) do
            if hay:find("%f[%a]" .. alias .. "%f[%A]") then
                return DUNGEON_SHORT[id]
            end
        end
    end
    return ""
end

local function ParseZone(...)
    local hay = table.concat({ ... }, " "):lower()
    if hay == "" then return "" end
    for i = 1, #ZONE_NAMES do
        local name = ZONE_NAMES[i]
        if hay:find(name:lower(), 1, true) then return name end
    end
    return ""
end

local function StripHunt(title)
    local t = tostring(title or "")
    t = t:gsub("^[Rr]are%s+[Hh]unt%s*[:%-–]%s*", "")
    t = t:gsub("^[Rr]are%s+[Hh]unt%s+", "")
    t = t:gsub("^[Ee]lite%s+[Hh]unt%s*[:%-–]%s*", "")
    t = t:gsub("^[Ee]lite%s+[Hh]unt%s+", "")
    t = t:gsub("^LFG%s*[:%-–]%s*", "")
    t = t:gsub("^LFG%s+", "")
    return t
end

local function NpcName(title)
    local t = StripHunt(title)
    t = t:gsub("^[Ee]lite%s+", "")
    t = t:gsub("^[Rr]are%s+", "")
    t = t:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if #t > 32 then t = t:sub(1, 32) end
    return t
end

local function SlotCat(s)
    local hay = ((s.title or "") .. " " .. (s.objective or "")):lower()
    if hay:find("lfg", 1, true) or hay:find("looking for group", 1, true) then
        return 11
    end
    local c = s.cat
    if type(c) == "string" then
        if c:lower():find("lfg") then return 11 end
        c = tonumber(c)
    end
    return tonumber(c) or 0
end

local function TitlesMatch(a, b)
    a = StripHunt((a or ""):lower()):gsub("^[Ee]lite%s+", ""):gsub("^[Rr]are%s+", "")
    b = StripHunt((b or ""):lower()):gsub("^[Ee]lite%s+", ""):gsub("^[Rr]are%s+", "")
    if a == "" or b == "" then return false end
    return a == b or a:find(b, 1, true) or b:find(a, 1, true)
end

local function LogIndexFor(title)
    local n = GetNumQuestLogEntries and GetNumQuestLogEntries() or 0
    for i = 1, n do
        local logTitle, _, _, _, isHeader = GetQuestLogTitle(i)
        if not isHeader and TitlesMatch(logTitle, title) then return i end
    end
end

local function ProgressText(s, title)
    local cur = tonumber(s.cur or s.progress or s.prog or s.count or s.have)
    local max = tonumber(s.max or s.needed or s.req or s.need)
    if cur and max and max > 0 then
        return cur .. "/" .. max
    end
    local a, b = tostring(s.objective or ""):match("(%d+)%s*/%s*(%d+)")
    if a then return a .. "/" .. b end
    local idx = LogIndexFor(title)
    if not idx then return "" end
    local _, _, _, _, _, _, isComplete = GetQuestLogTitle(idx)
    local num = GetNumQuestLeaderBoards and GetNumQuestLeaderBoards(idx) or 0
    local parts = {}
    for o = 1, num do
        local text = GetQuestLogLeaderBoard(o, idx)
        if text and text ~= "" then parts[#parts + 1] = text end
    end
    if #parts > 0 then return table.concat(parts, " · ") end
    if isComplete == 1 then return "ready" end
    return ""
end

local function StripDungeonWords(t)
    t = tostring(t or "")
    for _, name in pairs(DUNGEON_NAMES) do
        t = t:gsub(name, "")
    end
    for _, short in pairs(DUNGEON_SHORT) do
        t = t:gsub("%f[%a]" .. short .. "%f[%A]", "")
    end
    t = StripHunt(t)
    t = t:gsub("[Dd]ungeon", "")
    t = t:gsub("[Ii]nstance", "")
    t = t:gsub("[%:%-%–]", " ")
    t = t:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return t
end

local function BossFromText(text)
    text = tostring(text or "")
    local n = text:match("[Dd]efeat%s+([^%.%d]+)")
        or text:match("[Ss]lay%s+([^%.%d]+)")
        or text:match("[Kk]ill%s+([^%.%d]+)")
        or text:match("^(.+)%s+[Ss]lain")
        or text:match("^(.+)%s+[Dd]efeated")
    if not n then return "" end
    n = n:gsub("%s+in%s+.*$", "")
    n = StripDungeonWords(n)
    n = n:gsub("%s+in%s+$", "")
    return n
end

local function IsDungeonPhrase(p)
    local l = (p or ""):lower()
    if l == "" then return true end
    for _, name in pairs(DUNGEON_NAMES) do
        if l == name:lower() or l:find(name:lower(), 1, true) then return true end
    end
    for _, short in pairs(DUNGEON_SHORT) do
        if l == short:lower() then return true end
    end
    return false
end

local LFG_JUNK = {
    need = true, needs = true, needed = true, tank = true, tanks = true,
    healer = true, healers = true, heal = true, heals = true,
    dps = true, melee = true, ranged = true, lfg = true, lfm = true,
    group = true, party = true, raid = true, spot = true, spots = true,
    looking = true, pst = true, whisper = true, wisp = true,
    deep = true, within = true, inside = true, inside = true,
    located = true, found = true, beneath = true, below = true,
    above = true, around = true, near = true, outside = true,
    throughout = true, among = true, across = true, behind = true,
    depths = true, halls = true, instance = true, dungeon = true,
}

local function CutPlace(n)
    n = tostring(n or "")
    n = n:gsub("%s+[Dd]eep%s+[Ww]ithin.*$", "")
    n = n:gsub("%s+[Ww]ithin%s+.*$", "")
    n = n:gsub("%s+[Ii]nside%s+.*$", "")
    n = n:gsub("%s+[Bb]eneath%s+.*$", "")
    n = n:gsub("%s+[Nn]ear%s+.*$", "")
    n = n:gsub("%s+[Oo]utside%s+.*$", "")
    n = n:gsub("%s+[Aa]round%s+.*$", "")
    n = n:gsub("%s+[Ll]ocated%s+.*$", "")
    n = n:gsub("%s+in%s+the%s+.*$", "")
    n = n:gsub("%s+at%s+the%s+.*$", "")
    n = n:gsub("%s+in%s+.*$", "")
    return n
end

local function FinalizeLfgBoss(n)
    n = CutPlace(n or "")
    n = StripDungeonWords(n)
    n = CutPlace(n)
    n = n:gsub("[%(%[%{].*$", "")
    n = n:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    local words = {}
    for w in n:gmatch("%S+") do
        local lw = w:lower():gsub("[^%a']", "")
        if LFG_JUNK[lw] then break end
        words[#words + 1] = w
        if #words >= 4 then break end
    end
    n = table.concat(words, " ")
    n = n:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if #n > 28 then n = n:sub(1, 28) end
    return n
end

local function LfgBoss(s)
    local fromObj = BossFromText(s.objective)
    if fromObj ~= "" then return FinalizeLfgBoss(fromObj) end

    local t = StripHunt(s.title or "")
    t = t:gsub("%s*[%-–:]%s*", "|")
    for chunk in t:gmatch("[^|]+") do
        chunk = chunk:gsub("^%s+", ""):gsub("%s+$", "")
        if chunk ~= "" and not IsDungeonPhrase(chunk) then
            return FinalizeLfgBoss(chunk)
        end
    end
    local fromTitle = StripDungeonWords(s.title)
    if fromTitle ~= "" then return FinalizeLfgBoss(fromTitle) end
    return FinalizeLfgBoss(BossFromText(ProgressText(s, s.title)))
end

local snapshots = {}
local lastSig
local panel
local hooked

local function ShortName(name)
    return name and name:match("^([^-]+)") or nil
end

local function PlayerName()
    return ShortName(UnitName("player"))
end

local function InGroup()
    return (GetNumPartyMembers and GetNumPartyMembers() or 0) > 0
        or (GetNumRaidMembers and GetNumRaidMembers() or 0) > 0
end

local function Channel()
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then return "RAID" end
    if GetNumPartyMembers and GetNumPartyMembers() > 0 then return "PARTY" end
end

local function GroupNames()
    local names, seen = {}, {}
    local function add(n)
        n = ShortName(n)
        if n and not seen[n] then
            seen[n] = true
            names[#names + 1] = n
        end
    end
    add(UnitName("player"))
    local nraid = GetNumRaidMembers and GetNumRaidMembers() or 0
    if nraid > 0 then
        for i = 1, nraid do add(UnitName("raid" .. i)) end
    else
        local np = GetNumPartyMembers and GetNumPartyMembers() or 0
        for i = 1, np do add(UnitName("party" .. i)) end
    end
    return names
end

local function IsGroupMember(name)
    local short = ShortName(name)
    if not short then return false end
    for _, n in ipairs(GroupNames()) do
        if n == short then return true end
    end
    return false
end

local function Clean(value, limit)
    local text = tostring(value or "")
    text = text:gsub("[%c%^]", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if #text > limit then text = text:sub(1, limit) end
    return text
end

local function Split(message)
    local fields, start = {}, 1
    while true do
        local pos = message:find("^", start, true)
        if not pos then
            fields[#fields + 1] = message:sub(start)
            return fields
        end
        fields[#fields + 1] = message:sub(start, pos - 1)
        start = pos + 1
    end
end

local function Send(msg)
    local ch = Channel()
    if not ch or not SendAddonMessage then return end
    if ChatThrottleLib and ChatThrottleLib.SendAddonMessage then
        ChatThrottleLib:SendAddonMessage("NORMAL", PREFIX, msg, ch)
    else
        SendAddonMessage(PREFIX, msg, ch)
    end
end

local function Capture()
    local PA = Q.PA()
    local M = PA and PA.DailyCallboard
    local slots = M and M.slots
    if not slots then return nil end
    local quests = {}
    for _, s in pairs(slots) do
        local cat = SlotCat(s)
        local accepted = tonumber(s.status) == 1
            or (cat == 11 and LogIndexFor(s.title))
        local hasId = (tonumber(s.qid) or 0) > 0 or (s.title and s.title ~= "")
        if accepted and hasId then
            local dung = Clean(DungeonShort(s), 8)
            local zone = (cat == 11) and "" or ParseZone(s.objective, s.title)
            local name = (cat == 11) and LfgBoss(s) or NpcName(s.title)
            if cat == 11 then
                if name == "" then name = NpcName(s.title) end
                for _, member in ipairs(GroupNames()) do
                    if member and member ~= "" then
                        local esc = member:gsub("(%p)", "%%%1")
                        name = name:gsub("%s+" .. esc .. "%s*$", "")
                        name = name:gsub("^" .. esc .. "%s+", "")
                    end
                end
                name = name:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            end
            quests[#quests + 1] = {
                qid   = tonumber(s.qid) or 0,
                done  = s.serverComplete and true or false,
                tok   = tonumber(s.tokens) or 0,
                cat   = cat,
                dung  = dung,
                zone  = zone,
                title = name,
                prog  = Clean(ProgressText(s, s.title), 40),
                idx   = tonumber(s.idx),
            }
        end
    end
    table.sort(quests, function(a, b) return a.qid < b.qid end)
    if #quests > MAX_SLOTS then
        while #quests > MAX_SLOTS do quests[#quests] = nil end
    end
    return { name = PlayerName() or "Player", quests = quests }
end

local function Signature(snap)
    if not snap then return "" end
    local p = {}
    for i = 1, #snap.quests do
        local q = snap.quests[i]
        p[#p + 1] = table.concat({ q.qid, q.done and 1 or 0, q.tok, q.cat, q.dung, q.zone, q.title, q.prog }, "^")
    end
    return table.concat(p, "~")
end

local function Prune()
    local keep = {}
    for _, n in ipairs(GroupNames()) do keep[n] = true end
    for name in pairs(snapshots) do
        if not keep[name] then snapshots[name] = nil end
    end
end

function Q.BroadcastCallboard(force)
    local snap = Capture()
    if not snap then return end
    local me = snap.name
    snapshots[me] = snap
    if Q.RefreshCallboardPanel then Q.RefreshCallboardPanel() end
    if not InGroup() then return end
    local sig = Signature(snap)
    if not force and sig == lastSig then return end
    lastSig = sig
    Send(table.concat({ "H", VERSION, tostring(#snap.quests) }, "^"))
    for i = 1, #snap.quests do
        local q = snap.quests[i]
        Send(table.concat({
            "Q", VERSION, tostring(q.qid), q.done and "1" or "0",
            tostring(q.tok), tostring(q.cat), q.dung, q.zone, q.title, q.prog or "",
        }, "^"))
    end
    Send("E^" .. VERSION)
end

function Q.RequestCallboardSync()
    Prune()
    Send("R^" .. VERSION)
    Q.BroadcastCallboard(true)
end

function Q.OpenDailyCallboard()
    local PA = Q.PA()
    local M = PA and PA.DailyCallboard
    if M and M.Open then
        M:Open()
    elseif _G.ProjectAstralDailyCallboardFrame then
        _G.ProjectAstralDailyCallboardFrame:Show()
    end
end

local function LocalSlotIdx(q)
    if not q then return end
    if q.idx then return q.idx end
    local PA = Q.PA()
    local slots = PA and PA.DailyCallboard and PA.DailyCallboard.slots
    if not slots then return end
    local qid = tonumber(q.qid)
    if not qid or qid <= 0 then return end
    for _, s in pairs(slots) do
        if tonumber(s.qid) == qid and tonumber(s.status) == 1 then
            return s.idx
        end
    end
end

function Q.TurnInCallboard(q)
    local idx = LocalSlotIdx(q)
    local PA = Q.PA()
    local M = PA and PA.DailyCallboard
    if idx and M and M.TurnIn then
        M:TurnIn(idx)
    else
        Q.OpenDailyCallboard()
    end
end

function Q.ShareCallboardQuest(q, who)
    if not q then return end
    local cat = CAT_LABEL[q.cat] or "Quest"
    local where = q.dung ~= "" and q.dung or (q.zone ~= "" and ZoneShort(q.zone) or "")
    local npc = q.title or ""
    local parts = { "[" .. cat .. "]" }
    if where ~= "" then parts[#parts + 1] = where end
    if npc ~= "" then parts[#parts + 1] = npc end
    if q.prog and q.prog ~= "" then parts[#parts + 1] = q.prog end
    if q.done then parts[#parts + 1] = "ready" end
    if who and who ~= "" then parts[#parts + 1] = "(" .. who .. ")" end
    local msg = table.concat(parts, " ")
    if #msg > 240 then msg = msg:sub(1, 240) end
    local ch = Channel()
    if ch == "RAID" then
        SendChatMessage(msg, "RAID")
    elseif ch == "PARTY" then
        SendChatMessage(msg, "PARTY")
    else
        SendChatMessage(msg, "SAY")
    end
end

local pending = {}

local function Handle(message, sender)
    if type(message) ~= "string" or #message > 240 then return end
    sender = ShortName(sender)
    if not sender or not IsGroupMember(sender) then return end
    local f = Split(message)
    if f[2] ~= VERSION then return end
    if f[1] == "R" then
        Q.BroadcastCallboard(true)
        return
    end
    if f[1] == "H" then
        local n = tonumber(f[3])
        if not n or n < 0 or n > MAX_SLOTS then return end
        pending[sender] = { name = sender, expected = n, received = 0, quests = {} }
        if n == 0 then
            snapshots[sender] = { name = sender, quests = {} }
            pending[sender] = nil
            if Q.RefreshCallboardPanel then Q.RefreshCallboardPanel() end
        end
        return
    end
    if f[1] == "Q" then
        local inc = pending[sender]
        local qid = tonumber(f[3])
        if not inc or not qid then return end
        if f[4] ~= "0" and f[4] ~= "1" then return end
        inc.quests[#inc.quests + 1] = {
            qid   = qid,
            done  = f[4] == "1",
            tok   = tonumber(f[5]) or 0,
            cat   = tonumber(f[6]) or 0,
            dung  = Clean(f[7], 8),
            zone  = Clean(f[8], 24),
            title = Clean(FinalizeLfgBoss(StripHunt(f[9])), 32),
            prog  = Clean(f[10], 40),
        }
        inc.received = inc.received + 1
        return
    end
    if f[1] == "E" then
        local inc = pending[sender]
        if not inc then return end
        if inc.received ~= inc.expected then
            pending[sender] = nil
            return
        end
        snapshots[sender] = { name = sender, quests = inc.quests }
        pending[sender] = nil
        if Q.RefreshCallboardPanel then Q.RefreshCallboardPanel() end
    end
end

local function QuestFrame()
    return _G.QuestLogFrame
end

local HEADER_H, ROW_H = 18, 17
local headers, rows = {}, {}
local headerUsed, rowUsed = 0, 0
local scroll, content, toggleBtn, emptyLabel

local function CatRGB(cat)
    return CAT_COLOR[cat] or { 0.55, 0.55, 0.55 }
end

local function AcquireHeader()
    headerUsed = headerUsed + 1
    local h = headers[headerUsed]
    if h then return h end
    h = CreateFrame("Frame", nil, content)
    h:SetHeight(HEADER_H)
    h.bg = h:CreateTexture(nil, "BACKGROUND")
    h.bg:SetAllPoints()
    h.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h.label:SetPoint("LEFT", 6, 0)
    h.label:SetPoint("RIGHT", -6, 0)
    h.label:SetJustifyH("LEFT")
    headers[headerUsed] = h
    return h
end

local function AcquireRow()
    rowUsed = rowUsed + 1
    local r = rows[rowUsed]
    if r then return r end
    r = CreateFrame("Frame", nil, content)
    r:SetHeight(ROW_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    r.label = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.tok = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.tok:SetPoint("RIGHT", -6, 0)
    r.tok:SetJustifyH("RIGHT")
    r.tok:SetWidth(40)
    r.check = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.check:SetPoint("LEFT", -2, 0)
    r.check:SetScale(0.65)
    r.check:EnableMouse(false)
    r.label:SetPoint("LEFT", 22, 0)
    r.label:SetPoint("RIGHT", r.tok, "LEFT", -8, 0)
    r.label:SetJustifyH("LEFT")
    r:EnableMouse(true)
    r:SetScript("OnLeave", GameTooltip_Hide)
    rows[rowUsed] = r
    return r
end

local function HideUnused()
    for i = headerUsed + 1, #headers do headers[i]:Hide() end
    for i = rowUsed + 1, #rows do rows[i]:Hide() end
end

local function Place(frame, y, w)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", 0, -y)
    frame:SetWidth(w)
    frame:Show()
end

local function QuestDone(q)
    if not q then return false end
    if q.done then return true end
    local a, b = tostring(q.prog or ""):match("(%d+)%s*/%s*(%d+)")
    if a and b and tonumber(b) > 0 and tonumber(a) >= tonumber(b) then return true end
    return q.prog == "ready"
end

local callTip

local function HideCallTip()
    if callTip then callTip:Hide() end
end

local function EnsureCallTip()
    if callTip then return callTip end
    local f = CreateFrame("Frame", "qtAstralQOL_CallTip", UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:SetWidth(252)
    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0.03, 0.04, 0.09, 0.97)
    f:SetBackdropBorderColor(0.40, 0.52, 0.82, 1)

    f.stripe = f:CreateTexture(nil, "ARTWORK")
    f.stripe:SetWidth(4)
    f.stripe:SetPoint("TOPLEFT", 4, -4)
    f.stripe:SetPoint("BOTTOMLEFT", 4, 4)
    f.stripe:SetTexture("Interface\\Buttons\\WHITE8X8")

    local ring = f:CreateTexture(nil, "ARTWORK")
    ring:SetSize(40, 40)
    ring:SetPoint("TOPLEFT", 14, -12)
    ring:SetTexture("Interface\\Buttons\\WHITE8X8")
    ring:SetVertexColor(0.08, 0.10, 0.16, 1)
    f.icon = f:CreateTexture(nil, "OVERLAY")
    f.icon:SetPoint("TOPLEFT", ring, "TOPLEFT", 2, -2)
    f.icon:SetPoint("BOTTOMRIGHT", ring, "BOTTOMRIGHT", -2, 2)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    f.cat = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.cat:SetPoint("TOPLEFT", ring, "TOPRIGHT", 10, 2)
    f.cat:SetPoint("RIGHT", -12, 0)
    f.cat:SetJustifyH("LEFT")

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOPLEFT", f.cat, "BOTTOMLEFT", 0, -3)
    f.title:SetPoint("RIGHT", -12, 0)
    f.title:SetJustifyH("LEFT")

    f.who = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.who:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -2)
    f.who:SetPoint("RIGHT", -12, 0)
    f.who:SetJustifyH("LEFT")

    f.prog = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.prog:SetPoint("TOPLEFT", 14, -62)
    f.prog:SetPoint("RIGHT", -12, 0)
    f.prog:SetJustifyH("LEFT")

    f.foot = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.foot:SetPoint("BOTTOMLEFT", 14, 12)
    f.foot:SetPoint("BOTTOMRIGHT", -12, 12)
    f.foot:SetJustifyH("LEFT")

    callTip = f
    return f
end

local function ShowCallTip(owner, q, who)
    if not q then return end
    local f = EnsureCallTip()
    local rgb = CAT_COLOR[q.cat] or { 0.55, 0.55, 0.55 }
    f.stripe:SetVertexColor(rgb[1], rgb[2], rgb[3], 1)
    f:SetBackdropBorderColor(rgb[1] * 0.7 + 0.15, rgb[2] * 0.7 + 0.15, rgb[3] * 0.7 + 0.2, 1)

    local icon = (q.dung and DUNGEON_ICON[q.dung]) or CAT_ICON[q.cat]
        or "Interface\\Icons\\INV_Misc_QuestionMark"
    f.icon:SetTexture(icon)

    local catName = CAT_LABEL[q.cat] or "Quest"
    f.cat:SetText(catName)
    f.cat:SetTextColor(rgb[1], rgb[2], rgb[3])

    local title
    if q.zone and q.zone ~= "" then
        title = ZoneShort(q.zone)
        if q.title and q.title ~= "" then title = title .. "  ·  " .. q.title end
    elseif q.dung and q.dung ~= "" then
        title = q.dung
        if q.title and q.title ~= "" then title = title .. "  ·  " .. q.title end
    else
        title = (q.title and q.title ~= "") and q.title or catName
    end
    f.title:SetText(title)

    if who and who ~= "" then
        f.who:SetText(who)
        f.who:Show()
    else
        f.who:SetText("")
        f.who:Hide()
    end

    if q.prog and q.prog ~= "" then
        f.prog:ClearAllPoints()
        if f.who:IsShown() then
            f.prog:SetPoint("TOPLEFT", f.who, "BOTTOMLEFT", 0, -4)
        else
            f.prog:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -6)
        end
        f.prog:SetPoint("RIGHT", -12, 0)
        f.prog:SetText(q.prog)
        f.prog:Show()
    else
        f.prog:SetText("")
        f.prog:Hide()
    end

    local foot = (q.tok or 0) .. " tokens"
    local mine = not who or who == PlayerName()
    if q.done or QuestDone(q) then
        if mine then
            foot = foot .. "   |cff66ff66Click to turn in  Shift: send|r"
        else
            foot = foot .. "   |cff66ff66Ready|r"
        end
    else
        foot = foot .. "   |cff888888Click: board  Shift: send|r"
    end
    f.foot:SetText(foot)

    local h = 78
    if f.who:IsShown() then h = h + 12 end
    if f.prog:IsShown() then h = h + 16 end
    f:SetHeight(h)

    f:ClearAllPoints()
    f:SetPoint("LEFT", owner, "RIGHT", 10, 0)
    f:SetClampedToScreen(true)
    f:Show()
end

local function FillRow(r, left, tok, done, q, who)
    r.label:SetText(left or "")
    r.label:ClearAllPoints()
    if r.check then
        if done then
            r.check:Show()
            r.check:SetChecked(true)
            r.label:SetPoint("LEFT", 22, 0)
        else
            r.check:Hide()
            r.check:SetChecked(false)
            r.label:SetPoint("LEFT", 8, 0)
        end
    else
        r.label:SetPoint("LEFT", 8, 0)
    end
    if tok and tok ~= "" then
        r.tok:SetText(tok)
        r.tok:Show()
        r.label:SetPoint("RIGHT", r.tok, "LEFT", -8, 0)
    else
        r.tok:SetText("")
        r.tok:Hide()
        r.label:SetPoint("RIGHT", -6, 0)
    end
    r.label:SetJustifyH("LEFT")
    if q then
        r:SetScript("OnEnter", function(self)
            ShowCallTip(self, q, who)
        end)
        r:SetScript("OnLeave", HideCallTip)
        r:SetScript("OnMouseUp", function()
            if IsShiftKeyDown() then
                Q.ShareCallboardQuest(q, who)
                return
            end
            local mine = not who or who == PlayerName()
            if mine and QuestDone(q) then
                Q.TurnInCallboard(q)
            else
                Q.OpenDailyCallboard()
            end
        end)
    else
        r:SetScript("OnEnter", nil)
        r:SetScript("OnLeave", nil)
        r:SetScript("OnMouseUp", nil)
    end
end

local function QuestLeft(q)
    local col = CatHex(q.cat)
    local cat = "|cff" .. col .. (CAT_LABEL[q.cat] or "?") .. "|r"
    if q.zone and q.zone ~= "" then
        local npc = q.title ~= "" and q.title or "Elite"
        return "|cff" .. col .. ZoneShort(q.zone) .. "|r - |cffffffff" .. npc .. "|r"
    end
    if q.dung and q.dung ~= "" then
        local boss = q.title ~= "" and q.title or ""
        if boss ~= "" then
            return "|cff" .. col .. q.dung .. "|r - |cffffffff" .. boss .. "|r"
        end
        return cat .. "  |cff" .. col .. q.dung .. "|r"
    end
    local npc = q.title or ""
    if npc == "" then npc = CAT_LABEL[q.cat] or "Quest" end
    return cat .. "  |cffffffff" .. npc .. "|r"
end

local function OrderedNames()
    local names = GroupNames()
    local me = PlayerName()
    if #names <= 1 then return { me } end
    return names
end

local function RenderParty(w)
    local y = 0
    local me = PlayerName()
    for _, name in ipairs(OrderedNames()) do
        local snap = snapshots[name]
        local rgb = { 0.18, 0.32, 0.48 }
        local h = AcquireHeader()
        Place(h, y, w)
        h.bg:SetVertexColor(rgb[1], rgb[2], rgb[3], 0.45)
        h.label:SetText((name or "?") .. (name == me and "  (you)" or ""))
        y = y + HEADER_H

        if not snap then
            local r = AcquireRow()
            Place(r, y, w)
            r.bg:SetVertexColor(0.08, 0.09, 0.12, 0.4)
            FillRow(r, "|cff888888no data|r")
            y = y + ROW_H
        elseif #snap.quests == 0 then
            local r = AcquireRow()
            Place(r, y, w)
            r.bg:SetVertexColor(0.08, 0.09, 0.12, 0.4)
            FillRow(r, "|cff888888no accepted dailies|r")
            y = y + ROW_H
        else
            for i = 1, #snap.quests do
                local q = snap.quests[i]
                local c = CatRGB(q.cat)
                local r = AcquireRow()
                Place(r, y, w)
                r.bg:SetVertexColor(c[1], c[2], c[3], i % 2 == 0 and 0.16 or 0.08)
                FillRow(r, QuestLeft(q), (q.tok or 0) .. "T", QuestDone(q), q, name)
                y = y + ROW_H
            end
        end
        y = y + 4
    end
    return y
end

local function RenderTable(w)
    local buckets, keys = {}, {}
    for _, name in ipairs(OrderedNames()) do
        local snap = snapshots[name]
        if snap then
            for i = 1, #snap.quests do
                local q = snap.quests[i]
                local key, label, cat
                local catName = CAT_LABEL[q.cat] or "?"
                cat = q.cat
                if q.cat == 2 or q.cat == 3 or q.cat == 11 then
                    key = tostring(q.cat) .. ":c"
                    label = catName
                elseif q.zone and q.zone ~= "" then
                    key = tostring(q.cat) .. ":z:" .. q.zone
                    label = ZoneShort(q.zone)
                elseif q.dung and q.dung ~= "" then
                    key = tostring(q.cat) .. ":d:" .. q.dung
                    label = catName .. "  " .. q.dung
                else
                    key = tostring(q.cat) .. ":c"
                    label = catName
                end
                if not buckets[key] then
                    buckets[key] = { label = label, cat = cat, rows = {} }
                    keys[#keys + 1] = key
                end
                buckets[key].rows[#buckets[key].rows + 1] = { name = name, q = q }
            end
        end
    end
    table.sort(keys, function(a, b)
        return buckets[a].label < buckets[b].label
    end)

    local y = 0
    for _, key in ipairs(keys) do
        local g = buckets[key]
        local c = CatRGB(g.cat)
        local h = AcquireHeader()
        Place(h, y, w)
        h.bg:SetVertexColor(c[1], c[2], c[3], 0.38)
        h.label:SetText(string.format("|cff%s%s|r  (%d)", CatHex(g.cat), g.label, #g.rows))
        y = y + HEADER_H

        table.sort(g.rows, function(a, b)
            local za, zb = a.q.zone or "", b.q.zone or ""
            if za ~= zb then return za < zb end
            if a.q.title == b.q.title then return a.name < b.name end
            return (a.q.title or "") < (b.q.title or "")
        end)
        for i = 1, #g.rows do
            local e = g.rows[i]
            local r = AcquireRow()
            Place(r, y, w)
            r.bg:SetVertexColor(c[1], c[2], c[3], i % 2 == 0 and 0.14 or 0.07)
            FillRow(r, QuestLeft(e.q), (e.q.tok or 0) .. "T", QuestDone(e.q), e.q, e.name)
            y = y + ROW_H
        end
        y = y + 5
    end
    return y
end

local MIN_W, MIN_H = 240, 180

local function ScreenMaxH()
    return math.max(MIN_H, math.floor((UIParent:GetHeight() or 768) - 80))
end

local function DefaultHeight(parent)
    local qh = ((parent and parent:GetHeight()) or 480) - 24
    local cap = math.floor((UIParent:GetHeight() or 768) * 0.62)
    return math.max(MIN_H, math.min(qh, cap, ScreenMaxH()))
end

local function ApplyPanelSize()
    if not panel then return end
    local parent = QuestFrame()
    if not parent then return end
    local db = Q.DB()
    local w = tonumber(db.callboardW) or 298
    local h = tonumber(db.callboardH) or DefaultHeight(parent)
    w = math.max(MIN_W, math.min(420, w))
    h = math.max(MIN_H, math.min(ScreenMaxH(), h))
    db.callboardW, db.callboardH = w, h
    panel:SetResizable(true)
    panel:SetMinResize(MIN_W, MIN_H)
    panel:SetMaxResize(420, ScreenMaxH())
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", parent, "TOPRIGHT", 4, -12)
    panel:SetWidth(w)
    panel:SetHeight(h)
end

local function SavePanelSize()
    if not panel then return end
    local db = Q.DB()
    db.callboardW = math.floor((panel:GetWidth() or 298) + 0.5)
    db.callboardH = math.floor((panel:GetHeight() or 320) + 0.5)
end

local function SkinHeaderButton(b)
    if not b then return end
    local E = _G.ElvUI and _G.ElvUI[1]
    local S = E and E.GetModule and E:GetModule("Skins", true)
    if S and S.HandleButton then
        S:HandleButton(b, true)
        return
    end
    if b.SetTemplate then
        b:SetTemplate("Default", true)
        return
    end
    local PA = Q.PA()
    if PA and PA.UI and PA.UI.CosmicButton then
        PA.UI.CosmicButton(b)
    end
end

local function MakePanel()
    local parent = QuestFrame()
    if not parent then return end
    if panel then return panel end
    panel = CreateFrame("Frame", "qtAstralQOL_PartyCallboard", parent)
    ApplyPanelSize()
    panel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    panel:SetBackdropColor(0.04, 0.05, 0.10, 0.94)
    panel:SetBackdropBorderColor(0.32, 0.42, 0.70, 1)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("Party Callboard")

    toggleBtn = CreateFrame("Button", "qtAstralQOL_CallboardToggle", panel, "UIPanelButtonTemplate")
    toggleBtn:SetSize(64, 18)
    toggleBtn:SetPoint("TOPRIGHT", -10, -8)
    toggleBtn:SetScript("OnClick", function()
        local db = Q.DB()
        if (db.callboardView or "party") == "party" then
            db.callboardView = "table"
        else
            db.callboardView = "party"
        end
        Q.RefreshCallboardPanel()
    end)
    SkinHeaderButton(toggleBtn)

    local boardBtn = CreateFrame("Button", "qtAstralQOL_CallboardBoard", panel, "UIPanelButtonTemplate")
    boardBtn:SetSize(52, 18)
    boardBtn:SetPoint("RIGHT", toggleBtn, "LEFT", -4, 0)
    boardBtn:SetText("Board")
    boardBtn:SetScript("OnClick", Q.OpenDailyCallboard)
    SkinHeaderButton(boardBtn)

    scroll = CreateFrame("ScrollFrame", "qtAstralQOL_PartyCallboardScroll", panel)
    scroll:SetPoint("TOPLEFT", 8, -32)
    scroll:SetPoint("BOTTOMRIGHT", -10, 10)
    scroll:EnableMouseWheel(true)
    scroll:EnableMouse(true)

    content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(1)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    local track = CreateFrame("Frame", nil, panel)
    track:SetWidth(6)
    track:SetPoint("BOTTOMRIGHT", -3, 4)
    track:SetPoint("TOPRIGHT", -3, -34)
    track:SetFrameLevel(panel:GetFrameLevel() + 6)
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    trackBg:SetVertexColor(0.12, 0.14, 0.20, 0.7)

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetHeight(18)
    thumb:SetPoint("BOTTOMLEFT", 0, 0)
    thumb:SetPoint("BOTTOMRIGHT", 0, 0)
    local thumbBg = thumb:CreateTexture(nil, "ARTWORK")
    thumbBg:SetAllPoints()
    thumbBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumbBg:SetVertexColor(0.42, 0.52, 0.78, 0.95)
    thumb:RegisterForDrag("LeftButton")
    panel.scrollTrack = track
    panel.scrollThumb = thumb

    local function MaxScroll()
        if not (scroll and content) then return 0 end
        return math.max(0, content:GetHeight() - scroll:GetHeight())
    end

    local function LayoutThumb()
        local maxs = MaxScroll()
        local view = scroll:GetHeight() or 1
        local total = content:GetHeight() or 1
        if maxs <= 0 then
            track:Hide()
            return
        end
        track:Show()
        local trackH = track:GetHeight() or 1
        local thumbH = math.max(14, math.min(trackH, trackH * view / total))
        thumb:SetHeight(thumbH)
        local y = (1 - (scroll:GetVerticalScroll() / maxs)) * (trackH - thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("BOTTOMLEFT", 0, y)
        thumb:SetPoint("BOTTOMRIGHT", 0, y)
    end
    panel.LayoutThumb = LayoutThumb

    local function ScrollTo(offset)
        local maxs = MaxScroll()
        scroll:SetVerticalScroll(math.max(0, math.min(maxs, offset)))
        LayoutThumb()
    end

    scroll:SetScript("OnMouseWheel", function(self, delta)
        ScrollTo(self:GetVerticalScroll() - delta * 40)
    end)
    scroll:SetScript("OnVerticalScroll", LayoutThumb)

    thumb:SetScript("OnDragStart", function(self)
        self.drag = true
    end)
    thumb:SetScript("OnDragStop", function(self)
        self.drag = nil
    end)
    thumb:SetScript("OnMouseUp", function(self)
        self.drag = nil
    end)
    thumb:SetScript("OnUpdate", function(self)
        if not self.drag then return end
        local _, cy = GetCursorPosition()
        local scale = self:GetEffectiveScale() or 1
        cy = cy / scale
        local top, bot = track:GetTop(), track:GetBottom()
        local trackH = (top or 0) - (bot or 0)
        local thumbH = self:GetHeight() or 14
        local y = cy - (bot or 0) - thumbH / 2
        y = math.max(0, math.min(trackH - thumbH, y))
        local maxs = MaxScroll()
        local pct = 1
        if trackH > thumbH then
            pct = 1 - (y / (trackH - thumbH))
        end
        ScrollTo(pct * maxs)
    end)

    emptyLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyLabel:SetPoint("TOPLEFT", 14, -40)
    emptyLabel:SetPoint("TOPRIGHT", -12, -40)
    emptyLabel:SetJustifyH("LEFT")
    emptyLabel:SetTextColor(0.55, 0.55, 0.6)
    emptyLabel:Hide()

    local grip = CreateFrame("Button", nil, panel)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -1, 1)
    grip:SetFrameLevel(panel:GetFrameLevel() + 8)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatFrame-ResizeGrip")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatFrame-ResizeGrip")
    grip:SetScript("OnMouseDown", function()
        panel:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        panel:StopMovingOrSizing()
        SavePanelSize()
        ApplyPanelSize()
        Q.RefreshCallboardPanel()
    end)
    grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Resize")
        GameTooltip:AddLine("Drag to change callboard height and width. Saved per character.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", GameTooltip_Hide)
    panel:SetScript("OnSizeChanged", function()
        if panel.LayoutThumb then panel.LayoutThumb() end
    end)

    return panel
end

function Q.RefreshCallboardPanel()
    if not panel or not panel:IsShown() then return end
    Prune()
    local me = PlayerName()
    local mine = Capture()
    if mine then snapshots[me] = mine end

    local mode = Q.DB().callboardView or "party"
    if toggleBtn then
        toggleBtn:SetText(mode == "party" and "Table" or "Party")
    end

    headerUsed, rowUsed = 0, 0
    local w = math.max(120, (scroll and scroll:GetWidth() or 220) - 4)
    if content then content:SetWidth(w) end

    local y
    if mode == "table" then
        y = RenderTable(w)
    else
        y = RenderParty(w)
    end
    HideUnused()

    local hasRows = rowUsed > 0
    if emptyLabel then
        if hasRows then
            emptyLabel:Hide()
        else
            emptyLabel:SetText("No callboard data yet.")
            emptyLabel:Show()
        end
    end
    if content then
        content:SetHeight(math.max(1, y or 1))
    end
    if scroll then
        scroll:SetVerticalScroll(0)
    end
    if panel and panel.LayoutThumb then
        panel.LayoutThumb()
    end
end

function Q.ShowCallboardPanel()
    if Q.DB().callboard == false then return end
    MakePanel()
    if not panel then return end
    ApplyPanelSize()
    panel:Show()
    Q.RefreshCallboardPanel()
    Q.RequestCallboardSync()
    local PA = Q.PA()
    if PA and PA.DailyCallboard and PA.DailyCallboard.RequestState then
        PA.DailyCallboard:RequestState()
    end
end

local function HookQuestLog()
    local qf = QuestFrame()
    if not qf or qf._qolCB then return end
    qf._qolCB = true
    qf:HookScript("OnShow", Q.ShowCallboardPanel)
    qf:HookScript("OnHide", function()
        if panel then panel:Hide() end
    end)
    if qf:IsShown() then Q.ShowCallboardPanel() end
end

local function HookAIO()
    if hooked then return end
    local PA = Q.PA()
    if not (PA and PA.AIOTable) then return end
    local Client = PA.AIOTable("AstralDailyCallboard")
    if not Client then return end
    hooked = true
    local origState = Client.State
    Client.State = function(...)
        if origState then origState(...) end
        Q.BroadcastCallboard()
        Q.RefreshCallboardPanel()
    end
end

local origDefaults = Q.Defaults
function Q.Defaults()
    local d = origDefaults()
    d.callboard = true
    d.notify = true
    if d.callboardView == nil then d.callboardView = "party" end
    if d.callboardW == nil then d.callboardW = 298 end
    return d
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("PARTY_MEMBERS_CHANGED")
boot:RegisterEvent("RAID_ROSTER_UPDATE")
boot:RegisterEvent("CHAT_MSG_ADDON")
boot:RegisterEvent("QUEST_LOG_UPDATE")
boot:RegisterEvent("QUEST_WATCH_UPDATE")
boot:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, _, sender = ...
        if prefix == PREFIX then Handle(message, sender) end
        return
    end
    if event == "PLAYER_LOGIN" then
        HookAIO()
        HookQuestLog()
    end
    Prune()
    Q.BroadcastCallboard()
    Q.RefreshCallboardPanel()
end)

boot.acc, boot.life = 0, 0
boot:SetScript("OnUpdate", function(self, dt)
    self.acc = self.acc + dt
    self.life = self.life + dt
    if self.acc < 1 then return end
    self.acc = 0
    HookAIO()
    HookQuestLog()
    if (QuestFrame() and QuestFrame()._qolCB) or self.life > 20 then
        self:SetScript("OnUpdate", nil)
    end
end)

if RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(PREFIX)
end
