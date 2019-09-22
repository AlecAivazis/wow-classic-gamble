-- externals
local AceEvent = LibStub("AceEvent-3.0")

-- a namspace for the api
GambleCore = {}

-- the current game (if there is one)
local currentGame = nil

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
    currentGame = {
        kind = type,
        creator = UnitName("player"),
        players = {},
    }

    -- redraw the UI
    GambleUI:Refresh()
end


-- used to cancel the current game
function GambleCore:CancelGame()
    -- if the user is not the host
    if not GambleCore:IsHosting() then
        print("cannot do that")
        return
    end

    -- clear the current game
    currentGame = nil

    -- update the UI
    GambleUI:Refresh()
end


------------------------------------------------------------
-- Event Handlers
------------------------------------------------------------

-- invoked when there is a social message
function GambleCore:onSocialMessage(type, message, playerName)
    -- if the current user is not the host of a game
    if not GambleCore:IsHosting() then
        -- there's nothing to do
        return
    end

    -- if the message is the entry message then the user wants to join the current game
    if message == "1" then
        -- get the name of the player
        name = string.gmatch(playerName, "(%w+)-(%w+)")()
        
        -- add it to the list of players
        currentGame.players[name] = true

        -- update the ui
        GambleUI:Refresh()
    end

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
    return currentGame
end

-- return true if the current user is hosting a game
function GambleCore:IsHosting()
    return GambleCore:CurrentGame() and GambleCore:CurrentGame().creator == UnitName("player")
end