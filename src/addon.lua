-- addon definition
GambleAddon = LibStub("AceAddon-3.0"):NewAddon("Gamble", "AceConsole-3.0")

-- invoked by ace when the addon is enabled
function GambleAddon:OnEnable()
    -- initialize the frame
    GambleUI.Initialize()

    -- register slash commands
    GambleAddon:RegisterChatCommand("gamble", "ParseCmd")
    GambleAddon:RegisterChatCommand("gmb", "ParseCmd")

    GambleUI:Show()
end

-- invoked by ace when the addon is disabled
function GambleAddon:OnDisable()
    -- unregister slash commands
    GambleAddon:UnregisterChatCommand("gamble")
    GambleAddon:UnregisterChatCommand("gmb")
end
