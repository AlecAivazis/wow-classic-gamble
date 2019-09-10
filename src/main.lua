-- the root frame for interacting with GambleClassic
local frame = CreateFrame("Frame", "GambleClassic_mainFrame", UIParent)
frame:SetFrameStrata("TOOLTIP")
-- start GambleClassic hidden
frame:Hide()

function Main()
    print("Showing gamble frame")
    -- show the frame
    frame:Show()
end