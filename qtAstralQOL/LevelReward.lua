local Q = qtAstralQOL

local function Enhance(popup)
    if not popup or popup.qolExtractBtn then return end
    local btn = CreateFrame("Button", "qtAstralQOL_LevelExtract", popup, "UIPanelButtonTemplate")
    btn:SetSize(92, 22)
    btn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -10, -12)
    btn:SetText("Disenchant")
    btn:SetScript("OnClick", function()
        Q.OpenAstralDisenchant()
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Astral Disenchant")
        GameTooltip:AddLine("Open the gem extraction table without closing this reward.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)
    popup.qolExtractBtn = btn
end

local wait = CreateFrame("Frame")
wait:SetScript("OnUpdate", function(self)
    local popup = _G.PALevelRewardPopup
    if not popup then return end
    Enhance(popup)
    if not popup._qolExtractHook then
        popup._qolExtractHook = true
        popup:HookScript("OnShow", Enhance)
    end
    if popup.qolExtractBtn then
        self:SetScript("OnUpdate", nil)
    end
end)

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    wait:Show()
end)
