-- externals
local AceEvent = LibStub("AceEvent-3.0")

-- channel enum values
ChannelNames = {
    Raid = "RAID",
    Party = "PARTY",
    Say = "SAY",
}

-- a game transitions between three distinct phases
GamePhase = {
    GatheringPlayers = "accepting",
    Rolling = "rolling",
    Payout = "payout",
}

-- a namspace for the api
GambleCore = {
    -- the channel that messages have to come in on 
    channel = ChannelNames.Say,
    -- players with pending rolls
    _pendingRolls = {},
}

-- the message that indicates a user wants to join
JoinMessage = "1"
LeaveMessage = "imabitchnevermind"
ExplainMessage = "explain"

-- the default delay on last call
LastCallDelay = 5

-- the current game (if there is one)
local currentGame = nil

-- invoked when Gamble first comes online
function GambleCore:Initialize()
    -- listen for the following events:

    -- social messages
    AceEvent:RegisterEvent("CHAT_MSG_SAY", function (...) GambleCore:onSocialMessage(ChannelNames.Say, ...) end)
    AceEvent:RegisterEvent("CHAT_MSG_PARTY", function (...) GambleCore:onSocialMessage(ChannelNames.Party, ...) end)
    AceEvent:RegisterEvent("CHAT_MSG_PARTY_LEADER", function (...) GambleCore:onSocialMessage(ChannelNames.Party, ...) end)
    AceEvent:RegisterEvent("CHAT_MSG_RAID", function (...) GambleCore:onSocialMessage(ChannelNames.Raid, ...) end)
    AceEvent:RegisterEvent("CHAT_MSG_RAID_LEADER", function (...) GambleCore:onSocialMessage(ChannelNames.Party, ...) end)

    -- whispers can be for explanation while a game is accepting invites
    AceEvent:RegisterEvent("CHAT_MSG_WHISPER", function (...) GambleCore:onWhisper(...) end)

    -- system messages (aka rolls)
    AceEvent:RegisterEvent("CHAT_MSG_SYSTEM", function (...) GambleCore:onSystemMessage(...) end)
end


------------------------------------------------------------
-- Actions
------------------------------------------------------------

-- used to start a game between this and all listening instances of Gamble
function GambleCore:StartGame(type)
    -- the rules to use
    local rules = Games[type]
    -- if we don't recnogize the type
    if not rules then
        print("Unrecognized game type: " .. type)
        return
    end

    -- initialize a new game table of the appropriate kind
    currentGame = {
        kind = type,
        creator = UnitName("player"),
        channel = GambleCore.channel,
        rules = rules,
        players = {},
        phase = GamePhase.GatheringPlayers,
    }
    
    -- tell everyone what's going on
    GambleCore:Say(
        "Now playing " .. rules.Name .. "! Type " .. JoinMessage 
        .. " in this channel to join. If you don't know how to play, you can whisper me \"" 
        .. ExplainMessage .. "\" for help."
    )

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

    -- tell everyone what's going on
    GambleCore:Say("Sorry! The game has been cancelled.")

    -- clear the current game
    currentGame = nil

    -- update the UI
    GambleUI:Refresh()
end

-- used to join the current game
function GambleCore:JoinCurrentGame()
    -- if there is no current game
    if not currentGame or not currentGame.phase == GamePhase.AcceptingInvites then
        print("There is no current game to join")
        return
    end

    -- all we have to do to join the current game is say the join message on the 
    -- designated channel
    GambleCore:Say(JoinMessage)
end

-- used to leave the current game
function GambleCore:LeaveCurrentGame()
    -- if there is no current game or the game is not allowing players to change
    if not currentGame or not currentGame.phase == GamePhase.AcceptingInvites then
        print("There is no current game to join")
        return
    end

    -- all we have to do to leave is to say the leave message on the appropriate channel
    GambleCore:Say(LeaveMessage)
end

-- used to provide an explanation of the current game
function GambleCore:Explain() 
    -- if there is no current game
    if not currentGame then
        print("There is no current game to join")
        return
    end

    -- all we have to do to leave is to say the leave message on the appropriate channel
    GambleCore:Say(currentGame.rules.Explain)
end

-- invoked when its time to start the game
function GambleCore:LastCall()
    -- the function to call
    function lastCall() 
        -- if the game was canceled since last call
        if currentGame == nil then
            -- there's nothing to do
            return
        end

        -- we are no longer accepting players
        currentGame.phase = GamePhase.Rolling

        -- build up a list of the players
        local players = {}

        for player, _ in pairs(currentGame.players) do
            table.insert(players, player)
        end

        -- execute the game
        currentGame.rules.Execute(players)

        -- redraw the UI
        GambleUI:Refresh()
    end

    -- if we have a last call delay
    if LastCallDelay > 0 then 
        -- before we actually begin the game, lets give some stragglers the ability to catch up
        GambleCore:Say("Last call for players! The game will begin in ".. LastCallDelay .." seconds...")
        
        -- start the game
        GambleUtils:Delay(LastCallDelay, lastCall)
    -- there is no last call delay
    else
        -- just start the game
        lastCall()
    end
end


------------------------------------------------------------
-- Event Handlers
------------------------------------------------------------

-- invoked when there is a social message
function GambleCore:onSocialMessage(channel, type, message, playerID)
    -- if the message is on the wrong channel or there is no current game
    if GambleCore:CurrentGame() == nil or channel ~= currentGame.channel  then
        -- there's nothing to do
        return
    end

    -- the name of the player
    playerName = string.gmatch(playerID, "(%w+)-(%w+)")()

    -- if the message is the entry message then the user wants to join the current game
    if message == JoinMessage then
        -- add it to the list of players
        currentGame.players[playerName] = true
    -- the message could indicate someone wants to leave
    elseif message == LeaveMessage then 
        -- remove the player from the list
        currentGame.players[playerName] = nil
    end

    -- update the ui
    GambleUI:Refresh()
end

-- whenever there is a system message (aka a roll)
function GambleCore:onSystemMessage(type, text)
    -- if the current user is not the host of a game
    if not GambleCore:IsHosting() or not GambleUtils:TableHasKeys(GambleCore._pendingRolls) then
        -- there's nothing to do
        return
    end

    -- separate the messages by word
    local message = GambleUtils:SplitString(text, " ")
    -- extract the information from the message
    local player, roll, rangeString = message[1], tonumber(message[3]), message[4]

    -- look up the expected roll
    local expected = GambleCore._pendingRolls[player]

    -- if we don't care about rolls from this player
    if expected == nil then
        print("don't care")
        return
    end

    -- extract the roll range from the message
    local range = GambleUtils:SplitString(string.sub(rangeString, 2, -2), "-")
    local min, max = tonumber(range[1]), tonumber(range[2])

    -- if the bounds of the roll were incorrect
    if (min ~= expected.Min) or (max ~= expected.Max) then
        -- there was a roll mismatch so we need to whisper the player and ask them to re-roll
        local message = "Sorry, that roll has the incorrect bounds. Please roll again "
                        .. "by typing /roll " 

        -- if the lower bound is one, its optional
        if expected.Min ~= 1 then
            message = message .. expected.Min .. " "
        end

        -- the upper bound is always required
        message = message .. expected.Max
                    
        -- send them back the current game's explaination
        SendChatMessage(message , "WHISPER" , nil , player)

        -- we're done processing the roll
        return
    end

    -- add the result to the table
    GambleCore._rollResults[player] = roll
    -- remove the entry in the pending table
    GambleCore._pendingRolls[player] = nil
    -- decrement the count of pending rolls
    GambleCore._pendingRollsCount = GambleCore._pendingRollsCount - 1

    -- if the number of pending rolls is zero
    if GambleCore._pendingRollsCount == 0 and GambleCore._pendingRollCompleteCallback ~= nil then
        -- we can invoke the roll callback handler with the results
        GambleCore._pendingRollCompleteCallback(GambleCore._rollResults)
    end
end

-- when a whisper is recieved
function GambleCore:onWhisper(type, message, playerID)
    -- if the current user is not the host of a game
    if not GambleCore:IsHosting() then
        -- there's nothing to do
        return
    end

    -- if the user asked for an explanation
    if message == ExplainMessage then 
        -- send them back the current game's explaination
        SendChatMessage(currentGame.rules.Explain , "WHISPER" , nil , playerID)
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

-- sends a message on the appropriate channel for the current game
function GambleCore:Say(message) 
    SendChatMessage(message, currentGame.channel)
end

-- wait for rolls from the specified players
function GambleCore:CollectSameRoll(players, min, max, onComplete, onError)
    -- only the host can do this
    if not GambleCore:IsHosting() then
        return
    end


    -- build up the list of pending rolls
    GambleCore._pendingRolls = {}
    GambleCore._rollResults = {}
    GambleCore._pendingRollsCount = table.getn(players)

    -- if we were given an on complete callback
    if onComplete ~= nil then 
        -- save it
        GambleCore._pendingRollCompleteCallback = onComplete
    end

    -- if we were given an onError callback
    if onError ~= nil then
        GambleCore._pendingRollErrorCallback = onError
    end

    -- for every player
    for _, player in ipairs(players) do
        -- add an entry in the pending roll table
        GambleCore._pendingRolls[player] = {
            Min = min,
            Max = max,
        }
    end
end
