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
    channel = ChannelNames.Say
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
    AceEvent:RegisterEvent("CHAT_MSG_RAID", function (...) GambleCore:onSocialMessage(ChannelNames.Raid, ...) end)

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
        -- we are no longer accepting players
        currentGame.phase = GamePhase.Rolling

        -- redraw the UI
        GambleUI:Refresh()
    end

    -- if we have a last call delay
    if LastCallDelay > 0 then 
        -- before we actually begin the game, lets give some stragglers the ability to catch up
        GambleCore:Say("Last call for players! The game will begin in ".. LastCallDelay .." seconds...")

        -- start the game
        GambleCore:Delay(LastCallDelay, lastCall)
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
    if not channel == GambleCore.channel or GambleCore:CurrentGame() == nil then
        -- there's nothing to do
        return
    end

    -- we still want to track people coming and going even if we're not host

    -- if the message is the entry message then the user wants to join the current game
    if message == JoinMessage then
        -- add it to the list of players
        currentGame.players[playerID] = true
    -- the message could indicate someone wants to leave
    elseif message == LeaveMessage then 
        -- remove the player from the list
        currentGame.players[playerID] = nil
    end

    -- update the ui
    GambleUI:Refresh()
end

-- whenever there is a system message (aka a roll)
function GambleCore:onSystemMessage(type, message)
    -- if the current user is not the host of a game
    if not GambleCore:IsHosting() then
        -- there's nothing to do
        return
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

local waitTable = {};
local waitFrame = nil;

-- delays the execution of the provided function with the given args
function GambleCore:Delay(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end
