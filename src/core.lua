-- externals
local AceEvent = LibStub("AceEvent-3.0")

GambleCore = {}

-- invoked when Gamble first comes online
function GambleCore:Initialize()
    -- listen for the following events:

    -- social messages
    AceEvent:RegisterEvent("CHAT_MSG_SAY", function (...) GambleCore:onSocialMessage(...) end)
    AceEvent:RegisterEvent("CHAT_MSG_PARTY", function (...) GambleCore:onSocialMessage(...) end)
    AceEvent:RegisterEvent("CHAT_MSG_RAID", function (...) GambleCore:onSocialMessage(...) end)

    -- system messages (aka rolls)
    AceEvent:RegisterEvent("CHAT_MSG_SYSTEM", function (...) GambleCore:onSystemMessage(...) end)
end

-- used to start a game between this and all listening instances of Gamble
function GambleCore:StartGame(type)
    -- initialize a new game table of the appropriate kind
    GambleCore.currentGame = {
        kind = type,
        creator = UnitName("player")
    }

    -- redraw the UI
    GambleUI:Refresh()
end

-- invoked when there is a social message
function GambleCore:onSocialMessage(type, message)
    -- if the current user is not the host of a game
    if not GambleCore:IsHosting() then
        -- there's nothing to do
        return
    end

    print("A social message we care about")
end

-- whenever there is a system message (aka a roll)
function GambleCore:onSystemMessage(type, message)
    -- if the current user is not the host of a game
    if not GambleCore:IsHosting() then
        -- there's nothing to do
        return
    end

end

------------------------------------------------------------
-- Utils
------------------------------------------------------------

-- returns the current game
function GambleCore:CurrentGame()
    return GambleCore.currentGame
end

-- return true if the current user is hosting a game
function GambleCore:IsHosting()
    return GambleCore:CurrentGame() and GambleCore:CurrentGame().creator == UnitName("player")
end
