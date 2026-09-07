local Q = qtAstralQOL

local function Enhance(frame)
    if not frame then return end
    local anchor = frame.stashBtn or frame.browseBtn
    if not anchor then return end

    local btn = frame.qolDisenchantBtn
    if not btn then
        btn = CreateFrame("Button", "qtAstralQOL_FusionDisenchant", frame)
        btn:SetSize(28, 28)
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
        frame.qolDisenchantBtn = btn
    end

    btn:ClearAllPoints()
    btn:SetPoint("RIGHT", anchor, "LEFT", -6, 0)
    btn:SetFrameLevel((anchor:GetFrameLevel() or 1) + 8)
    btn:Show()

    if frame.listHeader and frame.unlockBox then
        frame.listHeader:SetPoint("TOPRIGHT", frame.unlockBox, "BOTTOMRIGHT", -96, -34)
    end
end

local wrappedBuilder
local function WrapBuilder()
    local PA = Q.PA()
    local tabs = PA and PA._tabContent
    local orig = tabs and tabs.GemFusion
    if not orig or orig == wrappedBuilder then return end
    local inner = orig
    wrappedBuilder = function(panel)
        inner(panel)
        local f = _G.PAGemFusionFrame
        if f then Enhance(f) end
    end
    tabs.GemFusion = wrappedBuilder
end

local wait = CreateFrame("Frame")
local acc = 0
wait:SetScript("OnUpdate", function(self, dt)
    acc = acc + dt
    WrapBuilder()
    local frame = _G.PAGemFusionFrame
    if frame then
        Enhance(frame)
        if not frame._qolFusionHook then
            frame._qolFusionHook = true
            frame:HookScript("OnShow", Enhance)
        end
    end
    if acc > 45 then
        self:SetScript("OnUpdate", nil)
    end
end)

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
    acc = 0
    wait:Show()
end)
