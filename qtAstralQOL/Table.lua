local Q = qtAstralQOL

function Q.LayoutAstralTableButtons(frame)
    if not frame then return end
    local rows = {
        { frame.disenchantBtn, frame.tierLink },
        { frame.importBtn,     frame.filterBtn },
        { frame.qolDepositGems, frame.qolSkipBtn },
    }
    local h, gap, rowGap, pad = 28, 8, 8, 22
    local fw = frame:GetWidth() or 360
    local colW = math.floor((fw - pad * 2 - gap) / 2)
    if colW < 120 then colW = 120 end
    local n = #rows
    for i = 1, n do
        local left, right = rows[i][1], rows[i][2]
        local y = 12 + (n - i) * (h + rowGap)
        if left then
            left:SetSize(colW, h)
            left:ClearAllPoints()
            left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", pad, y)
        end
        if right then
            right:SetSize(colW, h)
            right:ClearAllPoints()
            if left then
                right:SetPoint("LEFT", left, "RIGHT", gap, 0)
            else
                right:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", pad + colW + gap, y)
            end
        end
    end
end

local function Skin(btn)
    local PA = Q.PA()
    if PA and PA.UI and PA.UI.CosmicButton then
        PA.UI.CosmicButton(btn)
    end
end

local function EnhanceAstralTable(frame)
    if not frame then return end

    if not frame._qolTable and not frame.elvPADepositGems and not frame.qolDepositGems then
        frame._qolTable = true
        frame:SetHeight((frame:GetHeight() or 470) + 36)

        local btn = CreateFrame("Button", "qtAstralQOL_TableDeposit", frame, "UIPanelButtonTemplate")
        btn:SetSize(160, 28)
        btn:SetText("Deposit All Gems")
        Skin(btn)
        btn:SetScript("OnClick", Q.DepositAll)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Deposit All Gems")
            GameTooltip:AddLine("Sends all Astral gems and scrolls in your bags to the Gem Stash.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", GameTooltip_Hide)
        frame.qolDepositGems = btn
        frame.elvPADepositGems = btn
    end

    if Q.HookExtract then Q.HookExtract(frame) end
    Q.LayoutAstralTableButtons(frame)
end

local wait = CreateFrame("Frame")
wait:SetScript("OnUpdate", function(self)
    local frame = _G.ProjectAstralAstralDisenchant
    if not frame then return end
    EnhanceAstralTable(frame)
    if not frame._qolShowHook then
        frame._qolShowHook = true
        frame:HookScript("OnShow", function(f)
            EnhanceAstralTable(f)
        end)
    end
    if frame._qolTable then
        self:SetScript("OnUpdate", nil)
    end
end)

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    wait:Show()
end)
