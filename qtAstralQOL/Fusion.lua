local Q = qtAstralQOL

local function Enhance(frame)
    if not frame or frame.qolDisenchantBtn then return end

    local btn = CreateFrame("Button", "qtAstralQOL_FusionDisenchant", frame)
    btn:SetSize(28, 28)
    if frame.stashBtn then
        btn:SetPoint("RIGHT", frame.stashBtn, "LEFT", -6, 0)
    elseif frame.browseBtn then
        btn:SetPoint("RIGHT", frame.browseBtn, "LEFT", -6, 0)
    else
        btn:SetPoint("BOTTOMRIGHT", frame.unlockBox or frame, "BOTTOMRIGHT", 0, -38)
    end
    btn:SetFrameLevel((frame:GetFrameLevel() or 1) + 20)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp")
    btn:SetNormalTexture("Interface\\Icons\\INV_Enchant_DustIllusion")
    local nt = btn:GetNormalTexture()
    if nt then nt:SetTexCoord(0.07, 0.93, 0.07, 0.93) end
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetVertexColor(0.55, 0.80, 1.00, 0.8)
    btn:SetScript("OnClick", function()
        Q.ToggleAstralDisenchant(_G.PAMainMenuFrame or frame)
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Astral Disenchant")
        GameTooltip:AddLine("Toggle The Astral Table to extract gems from gear.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    if frame.listHeader and frame.unlockBox then
        frame.listHeader:SetPoint("TOPRIGHT", frame.unlockBox, "BOTTOMRIGHT", -96, -34)
    end

    frame.qolDisenchantBtn = btn
end

local wait = CreateFrame("Frame")
wait:SetScript("OnUpdate", function(self)
    local frame = _G.PAGemFusionFrame
    if not frame then return end
    Enhance(frame)
    if not frame._qolFusionHook then
        frame._qolFusionHook = true
        frame:HookScript("OnShow", Enhance)
    end
    if frame.qolDisenchantBtn then
        self:SetScript("OnUpdate", nil)
    end
end)

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    wait:Show()
end)
