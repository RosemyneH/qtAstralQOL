local Q = qtAstralQOL

local function EnhanceAstralTable(frame)
    if not frame then return end

    if not frame._qolTable and not frame.elvPADepositGems and not frame.qolDepositGems then
        frame._qolTable = true
        frame:SetHeight((frame:GetHeight() or 470) + 36)

        local btn = CreateFrame("Button", "qtAstralQOL_TableDeposit", frame, "UIPanelButtonTemplate")
        btn:SetSize(268, 26)
        btn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 12)
        btn:SetText("Deposit All Gems")
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
