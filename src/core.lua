-- externals
local AceEvent = LibStub("AceEvent-3.0")
local AceComm = LibStub("AceComm-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
-- a game transitions between three distinct phases
GamePhase = {
    GatheringPlayers = "accepting",
    Rolling = "rolling",
    Results = "results",
}

-- the comm events used between instances of Gamble
CommEvents = {
    NewPhase = "Gamble_PHASE",
    NewGame = "Gamble_GAME",
    PendingRolls = "Gamble_ROLLS",
    GameOver = "Gamble_GAME_OVR",
    Cancel = "Gamble_Cancel"
}

-- a namspace for the api
GambleCore = {
    -- players with pending rolls
    _pendingRolls = {},
}

-- the message that indicates a user wants to join
JoinMessage = "1"
LeaveMessage = "imacowardnevermind"
ExplainMessage = "explain"

-- the default delay on last call
LastCallDelay = 0

-- the current game (if there is one)
local currentGame = nil

-- invoked when Gamble first comes online
function GambleCore:Initialize()
    -- listen for the following events:

    -- social messages
    AceEvent:RegisterEvent("CHAT_MSG_PARTY", function (...) GambleCore:onSocialMessage(...) end)
    AceEvent:RegisterEvent("CHAT_MSG_PARTY_LEADER", function (...) GambleCore:onSocialMessage(...) end)
    AceEvent:RegisterEvent("CHAT_MSG_RAID", function (...) GambleCore:onSocialMessage(...) end)
    AceEvent:RegisterEvent("CHAT_MSG_RAID_LEADER", function (...) GambleCore:onSocialMessage(...) end)

    -- addon communication channels
    AceComm:RegisterComm(CommEvents.NewGame, function (...) GambleCore:onCommNewGame(...) end)
    AceComm:RegisterComm(CommEvents.PendingRolls, function (...) GambleCore:onCommPendingRolls(...) end)
    AceComm:RegisterComm(CommEvents.NewPhase, function (...) GambleCore:onCommNewPhase(...) end)
    AceComm:RegisterComm(CommEvents.GameOver, function (...) GambleCore:onCommGameOver(...) end)
    AceComm:RegisterComm(CommEvents.Cancel, function (...) GambleCore:onCommCancel(...) end)

    -- whispers can be for explanation while a game is accepting invites
    AceEvent:RegisterEvent("CHAT_MSG_WHISPER", function (...) GambleCore:onWhisper(...) end)

    -- system messages (aka rolls)
    AceEvent:RegisterEvent("CHAT_MSG_SYSTEM", function (...) GambleCore:onSystemMessage(...) end)
end


------------------------------------------------------------
-- Actions
------------------------------------------------------------

-- used to start a game between this and all listening instances of Gamble
function GambleCore:NewGame(type)
    -- create a new game of the appropriate type and channel with the current user
    -- as the host
    GambleCore:_newGame(type, UnitName("player"))
    
    -- tell everyone what's going on
    GambleCore:Say(
        "Now playing " .. currentGame.rules.Name .. "! Type " .. JoinMessage 
        .. " in this channel to join. If you don't know how to play, you can whisper me \"" 
        .. ExplainMessage .. "\" for help."
    )

    -- notify other open clients
    AceComm:SendCommMessage(CommEvents.NewGame, type, "RAID")

    -- redraw the UI
    GambleUI:Refresh()
end

function GambleCore:_newGame(type, host)
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
        host = host,
        rules = rules,
        players = {},
        phase = GamePhase.GatheringPlayers,
    }
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
    AceComm:SendCommMessage(CommEvents.Cancel, "anything", "RAID")

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
function GambleCore:StartGame()
    -- the function to call
    function lastCall() 
        -- if the game was canceled since last call
        if currentGame == nil then
            -- there's nothing to do
            return
        end

        -- we are no longer accepting players
        currentGame.phase = GamePhase.Rolling
        AceComm:SendCommMessage(CommEvents.NewPhase, GamePhase.Rolling, "RAID")

        -- build up a list of the players
        local players = {}

        for player, _ in pairs(currentGame.players) do
            table.insert(players, player)
        end

        -- execute the game
        currentGame.rules.Execute(players)
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
function GambleCore:onSocialMessage(type, message, playerID)
    -- if there is no current game
    if GambleCore:CurrentGame() == nil then
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
    if GambleCore:CurrentGame() == nil or not GambleUtils:TableHasKeys(GambleCore._pendingRolls) then
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
        return
    end

    -- extract the roll range from the message
    local range = GambleUtils:SplitString(string.sub(rangeString, 2, -2), "-")
    local min, max = tonumber(range[1]), tonumber(range[2])

    -- if the roll was not what we expected
    if (min ~= expected.Min) or (max ~= expected.Max) then
        -- if the user is not the host
        if not GambleCore:IsHosting() then
            -- ignore the roll
            return
        end

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

    -- if we are responsible for handling rolls and there are none left
    if GambleCore:IsHosting() and GambleCore._pendingRollsCount == 0 and GambleCore._pendingRollCompleteCallback ~= nil then
        -- we can invoke the roll callback handler with the results
        GambleCore._pendingRollCompleteCallback(GambleCore._rollResults)
    end

    -- update the UI
    GambleUI:Refresh()
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


-- invoked when another addon creates a new game
function GambleCore:onCommNewGame(eventType, message, channel, author)
    -- the new game event comes in the form of TYPE
    local newGameType = message

    -- as long as there isn't a game going now
    if GambleCore:CurrentGame() == nil or GambleCore:CurrentGame().phase == GamePhase.Results then
        -- register the new game
        GambleCore:_newGame(newGameType, author)    

        -- refresh the UI
        GambleUI:Refresh()
    end
end

-- invoked when another addon adds pending rolls
function GambleCore:onCommPendingRolls(eventType, message, channel, author)
    -- if the author of the message is not the host
    if GambleCore:CurrentGame() == nil or author ~= GambleCore:CurrentGame().host then
        -- ignore this message
        return
    end

    -- deserialize the table of pending rolls into the internal state
    okay, payload = AceSerializer:Deserialize(message)
    -- if something went wrong
    if not okay then 
        print("not okay", rolls, message)
        -- don't continue
        return
    end

    -- update the internal rolls table
    GambleCore._pendingRolls = payload.rolls
    GambleCore._rollResults = {}
    GambleCore._pendingRollsCount = payload.nPlayers

    GambleUI:Refresh()
end

-- invoked when addon changes the phase
function GambleCore:onCommNewPhase(eventType, message, channel, author)
    local currentGame = GambleCore:CurrentGame()

    -- if the author of the message is not the host
    if currentGame == nil or author ~= currentGame.host then
        -- ignore this message
        return
    end

    -- set the phase
    currentGame.phase = message

    -- refresh the ui
    GambleUI:Refresh()
end

function GambleCore:onCommGameOver(eventType, message, channel, author)
    local currentGame = GambleCore:CurrentGame()

    -- if the author of the message is not the host
    if currentGame == nil or author ~= currentGame.host then
        -- ignore this message
        return
    end
    
    -- the message is a serialized result object
    okay, payload = AceSerializer:Deserialize(message)
    -- if something went wrong
    if not okay then 
        print("not okay", rolls, message)
        -- don't continue
        return
    end

    -- call the game over
    GambleCore:GameOver(payload.winner, payload.loser, payload.amount)
end

function GambleCore:onCommCancel(eventType, message, channel, author)
    local currentGame = GambleCore:CurrentGame()

    -- if the author of the message is not the host
    if currentGame == nil or author ~= currentGame.host then
        print("not resetting")
        -- ignore this message
        return
    end
    print("cancel")

    
    -- just reset the UI
    GambleCore:Reset()
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
    return GambleCore:CurrentGame() and GambleCore:CurrentGame().host == UnitName("player")
end

-- sends a message on the appropriate channel for the current game
function GambleCore:Say(message) 
    -- default send the message to the party
    local channel = "PARTY"    
    
    -- if the user is in a raid
    if UnitInRaid("player") then
        -- then send the message there
        channel = "RAID"
    end

    -- send the message to the right channel
    SendChatMessage(message, channel)
end

function GambleCore:CurrentPlayers()
    -- the list of valid players
    local players = {}

    -- get the current game
    local game = GambleCore:CurrentGame()
    -- if there is no game
    if game == nil then 
        -- there are no players
        return players
    end

    for user, val in pairs(game.players) do
        -- players could have been removed (set to false)
        if val then 
            table.insert(players, user)
        end
    end

    -- return the list of non-nil players
    return players
end

-- the number of players in the current game
function GambleCore:CurrentNumberOfPlayers() 
    -- the current list of players
    local players = GambleCore:CurrentPlayers()

    -- the running total
    local total = 0
    -- add one for each player
    for _ in pairs(players) do
        total = total + 1
    end

    return total
end

-- perform the roll that is pending for the current user
function GambleCore:Roll()
    -- the name of the current player
    local currentPlayer = UnitName("player")

    -- the expected roll of the current player
    local expected = GambleCore._pendingRolls[currentPlayer]

    -- if the user does not have to roll
    if expected == nil then
        -- don't do anything else
        return
    end

    -- perform the roll
    RandomRoll(expected.Min, expected.Max)
end


-- returns true if the current user needs to roll
function GambleCore:PlayerNeedsToRoll()
    -- save a reference to the current game
    local game = GambleCore:CurrentGame()
    -- if there is no game
    if not game then
        -- the user doesn't need to roll
        return false
    end

    -- the name of the current player
    local currentPlayer = UnitName("player")


    -- look at each of the pending rolls
    for player, _ in pairs(GambleCore:PendingRolls()) do
        -- if we found an entry for the current player
        if player == currentPlayer then
            return true
        end
    end

    -- go through the current game
    return false
end

-- return the table of pending rolls
function GambleCore:PendingRolls()
    return GambleCore._pendingRolls
end

function GambleCore:NumberOfPendingRolls()
    -- the running total
    local total = 0
    -- add one for each 
    for _ in pairs(GambleCore:PendingRolls()) do
        total = total + 1
    end

    return total
end

-- return the table of recorded rolls
function GambleCore:RollResults()
    return GambleCore._rollResults
end

function GambleCore:NumberOfRollResults()
    -- the running total
    local total = 0
    -- add one for each 
    for _ in pairs(GambleCore:RollResults() or {}) do
        total = total + 1
    end

    return total
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

    -- send the list of pending rolls
    AceComm:SendCommMessage(CommEvents.PendingRolls, AceSerializer:Serialize({
        rolls = GambleCore._pendingRolls,
        nPlayers = GambleCore._pendingRollsCount,
    }), "RAID")
end

-- used by games to record the final winner, loser, and the amount owed
function GambleCore:GameOver(winner, loser, amount)
    -- record the result
    currentGame.result = {
        winner = winner,
        loser = loser,
        amount = amount,
    }

    -- send the UI to the result phase
    currentGame.phase = GamePhase.Results

    -- render the UI
    GambleUI:Refresh()
    
    -- notify other clients
    AceComm:SendCommMessage(CommEvents.GameOver, AceSerializer:Serialize(currentGame.result), "RAID")

end

function GambleCore:Reset()
    -- clear the current game
    currentGame = nil

    -- refresh the UI
    GambleUI:Refresh()
end