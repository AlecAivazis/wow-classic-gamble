GambleUI = {}

-- local imports
local AceGUI = LibStub("AceGUI-3.0")

function GambleUI:Initialize()
    -- create the root frame
    GambleUI.frame = AceGUI:Create("Frame")

    -- configure the frame
    GambleUI.frame:SetTitle("Gamble")
    GambleUI.frame:SetStatusText("v0.0.0")
    GambleUI.frame:SetLayout("Fill")


    -- make sure the frame starts hidden
    GambleUI.frame:Hide()
end

function GambleUI:Show()
    GambleUI.frame:Show()
end