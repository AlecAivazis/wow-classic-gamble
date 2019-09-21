-- addon definition
GambleAddon = LibStub("AceAddon-3.0"):NewAddon("Gamble", "AceConsole-3.0")

-- invoked by ace when the addon is enabled
function GambleAddon:OnEnable()
    -- register slash commands
    GambleAddon:RegisterChatCommand("gamble", "MainCmd")
    GambleAddon:RegisterChatCommand("gmb", "MainCmd")


end

-- invoked by ace when the addon is disabled
function GambleAddon:OnDisable()
    -- unregister slash commands
    GambleAddon:UnregisterChatCommand("gamble")
    GambleAddon:UnregisterChatCommand("gmb")
end
