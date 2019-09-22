-- externals
local AceGUI = LibStub("AceGUI-3.0")

GambleUI = {}

-- tab name constants
local TabNames = {
    Play = "play",
    History = "history",
}

function GambleUI:Initialize()
    -- create the root frame
    GambleUI.frame = AceGUI:Create("Frame")

    -- configure the frame
    GambleUI.frame:SetTitle("Gamble")
    GambleUI.frame:SetStatusText("v0.0.0")
    GambleUI.frame:SetLayout("Fill")
    GambleUI.frame:SetWidth(400)
    GambleUI.frame:SetHeight(400)

    -- create the tab group at the root of the UI
    GambleUI.tabs = AceGUI:Create("TabGroup")
    GambleUI.tabs:SetLayout("Flow")
    GambleUI.tabs:SetTabs({
        {
            text = "Play",
            value=TabNames.Play
        },
        {
            text = "History",
            value=TabNames.History
        },
    })
    GambleUI.tabs:SetCallback("OnGroupSelected", function (container, event, tabName)
        -- save a reference to the container in case we need to update it out of band
        GambleUI._tabFrame = container
        GambleUI._currentTab = tabName

        -- draw the selected tab
        GambleUI:_drawTab(container, tabName)
    end )
    GambleUI.tabs:SelectTab(TabNames.Play)
    -- add the select to the frame
    GambleUI.frame:AddChild(GambleUI.tabs)

    -- make sure the frame starts hidden
    GambleUI.frame:Hide()
end

-- Shows the UI
function GambleUI:Show()
    -- force the play tab to always be open at first
    GambleUI.tabs:SelectTab(TabNames.Play)

    GambleUI.frame:Show()
end

-- Hides the UI
function GambleUI:Hide()
    GambleUI.frame:Hide()
end

-- Refreshes the UI
function GambleUI:Refresh()
    GambleUI:_drawTab(GambleUI._tabFrame, GambleUI._currentTab)
end

------------------------------------------------------------
-- Tabs
------------------------------------------------------------

-- draw the tab
function GambleUI:_drawTab(container, which)
    -- clear the contents of the tab container before we do anything else
    container:ReleaseChildren()

    -- make sure the container is the right size
    container:SetLayout("Fill")

    -- we will embed each tab in a scroll frame to handle overflow globally
    scrollContainer = AceGUI:Create("ScrollFrame")
    scrollContainer:SetLayout("Flow")
    container:AddChild(scrollContainer)

    -- if the user is showing the play tab
    if which == TabNames.Play then
        GambleUI:_drawPlayTab(scrollContainer)
    -- otherwise they could be showing the history tab
    elseif which == TabNames.History then
        GambleUI:_drawHistoryTab(scrollContainer)
    end
end

-- invoked when the user wants to draw the play tab
function GambleUI:_drawPlayTab(container)
    -- if there is no current game
    if not GambleCore:CurrentGame() then
        -- render the appropriate state of the playtab
        GambleUI:_drawPlayTab_noCurrentGame(container)
    -- otherwise there is a game currently going
    else
        -- render the summary of the current game
        GambleUI:_drawPlayTab_acceptingInvites(container)
    end
end

-- the state of the play tab when there is no game playing
function GambleUI:_drawPlayTab_noCurrentGame(container)
    -- some spacing before the channel select
    GambleUI:VerticalSpace(container, "small")

    -- add a label for the channel select
    local channelLabel = AceGUI:Create("Label")
    channelLabel:SetText("Channel:")
    channelLabel:SetFontObject(GameFontHighlightMedium)
    channelLabel:SetWidth(75)
    container:AddChild(channelLabel)

    -- a dropdown to choose the channel to show
    local channelSelect = AceGUI:Create("Dropdown")
    channelSelect:SetList({})
    channelSelect:SetCallback("OnValueChanged", function (table, event, key)
        -- set the channel config
        GambleCore.channel = key
    end)
    channelSelect:AddItem(ChannelNames.Say, "Say")
    channelSelect:SetValue(ChannelNames.Say)
    channelSelect:SetWidth(100)
    container:AddChild(channelSelect)

    -- if the player is in a party
    if UnitInParty("player") then
        -- add the raid channel as an option
        channelSelect:AddItem(ChannelNames.Party, "Party")
        -- default to that selected
        channelSelect:SetValue(ChannelNames.Party)
    end

    -- if the player is in a raid
    if UnitInRaid("player") then
        -- add the raid channel as an option
        channelSelect:AddItem(ChannelNames.Raid, "Raid")
        -- default to that selected
        channelSelect:SetValue(ChannelNames.Raid)
    end

    -- some spacing before the game select
    GambleUI:VerticalSpace(container, "small")
    
    -- there is no game currently in progress so we just need to render the options to kick off a new game
    local head = AceGUI:Create("Heading")
    head:SetText("Start a Game")
    head:SetFullWidth(true)
    container:AddChild(head)

    -- some vertical spacing under the header
    GambleUI:VerticalSpace(container, "small")

    -- add a button for hilo
    local hiloButton = AceGUI:Create("Button")
    hiloButton:SetText("HiLo")
    hiloButton:SetRelativeWidth(0.48)
    hiloButton:SetCallback("OnClick", function() GambleCore:StartGame("HiLo") end)
    container:AddChild(hiloButton)

    -- we need a 10% space between the two
    GambleUI:HoritzonalSpace(container, 0.04)

    -- add a button for big twos
    local bigTwosButton = AceGUI:Create("Button")
    bigTwosButton:SetText("Big Twos")
    bigTwosButton:SetCallback("OnClick", function() GambleCore:StartGame("Big Twos") end)
    bigTwosButton:SetRelativeWidth(0.48)
    container:AddChild(bigTwosButton)
end

function GambleUI:_drawPlayTab_acceptingInvites(container)
    -- save a reference to the current game
    local game = GambleCore:CurrentGame()

    -- add a little spacing at the top
    GambleUI:VerticalSpace(container, "small")

    -- tell the user what's being played
    local nowPlayingHeader = AceGUI:Create("Label")
    nowPlayingHeader:SetFontObject(GameFontHighlightLarge)
    nowPlayingHeader:SetText("Now Playing: " .. game.kind)
    nowPlayingHeader:SetFullWidth(true)
    container:AddChild(nowPlayingHeader)

    -- list who the dealer is
    local hostLabel = AceGUI:Create("Label")
    hostLabel:SetText("Host: " .. game.creator)
    hostLabel:SetFontObject(GameFontHighlightMedium)
    container:AddChild(hostLabel)

    -- some more spacing
    GambleUI:VerticalSpace(container, "small")

    -- if the current user is the dealer
    if GambleCore:IsHosting() then
        -- add a commands section the host can use to officiate
        local hostHeader = AceGUI:Create("Heading")
        hostHeader:SetText("Host Commands")
        hostHeader:SetFullWidth(true)
        container:AddChild(hostHeader)

        -- a button to explain the current game
        local cancelButton = AceGUI:Create("Button")
        cancelButton:SetText("Cancel Game")
        cancelButton:SetRelativeWidth(0.32)
        cancelButton:SetCallback("OnClick", function() GambleCore:CancelGame() end)
        container:AddChild(cancelButton)
        
        -- some spacing between the buttons
        GambleUI:HoritzonalSpace(container, 0.01)

        -- a button to finalize the current game
        local finalizeButton = AceGUI:Create("Button")
        finalizeButton:SetText("Begin Game")
        finalizeButton:SetRelativeWidth(0.32)
        finalizeButton:SetCallback("OnClick", function() GambleCore:BeginGame() end)
        container:AddChild(finalizeButton)

        -- some more spacing
        GambleUI:VerticalSpace(container, "small")
    end 

    
    -- player commands
    local hostHeader = AceGUI:Create("Heading")
    hostHeader:SetText("Player Commands")
    hostHeader:SetFullWidth(true)
    container:AddChild(hostHeader)

    -- the fully qualified name of the current player
    local currentPlayerName = UnitName("player") .. "-" .. GetRealmName()

    -- if the current user is not in the game
    if not GambleCore:CurrentGame().players[currentPlayerName] then
        -- a button to join the current game
        local joinButton = AceGUI:Create("Button")
        joinButton:SetText("Join Game")
        joinButton:SetRelativeWidth(0.32)
        joinButton:SetCallback("OnClick", function() GambleCore:JoinCurrentGame() end)
        container:AddChild(joinButton)
    else 
        -- a button to join the current game
        local leaveButton = AceGUI:Create("Button")
        leaveButton:SetText("Leave Game")
        leaveButton:SetRelativeWidth(0.32)
        leaveButton:SetCallback("OnClick", function() GambleCore:LeaveCurrentGame() end)
        container:AddChild(leaveButton)
    end
        
    -- some spacing between the buttons
    GambleUI:HoritzonalSpace(container, 0.01)

    -- a button to explain the current game
    local explainButton = AceGUI:Create("Button")
    explainButton:SetText("Explain")
    explainButton:SetRelativeWidth(0.32)
    explainButton:SetCallback("OnClick", function() GambleCore:Explain() end)
    container:AddChild(explainButton)

    -- some more spacing
    GambleUI:VerticalSpace(container, "small")

    -- a heading for the list the people who have entered
    local playersHeader = AceGUI:Create("Heading")
    playersHeader:SetText("Players")
    playersHeader:SetFullWidth(true)
    container:AddChild(playersHeader)

    -- the list of users that have entered the game
    local playersBody = AceGUI:Create("Label")
    playersBody:SetFullWidth(true)
    playersBody:SetFontObject(GameFontHighlightMedium)
    container:AddChild(playersBody)
    -- compute the actual players text
    local players = ""
    for user, val in pairs(game.players) do
        -- players could have been removed (set to false)
        if val then 
            -- get the name of the player
            playerName = string.gmatch(user, "(%w+)-(%w+)")()
    
            players = players .. playerName .. ", "
        end
    end
    -- update the body of the element
    playersBody:SetText(players:sub(0, -3))
end

-- invoked when the user wants to draw the history tab
function GambleUI:_drawHistoryTab(container)
    -- for now just tell them its coming
    local content = AceGUI:Create("Label")
    content:SetFontObject(GameFontHighlightLarge)
    content:SetText("Coming soon!")

    container:AddChild(content)
end


------------------------------------------------------------
-- Drawing Utils
------------------------------------------------------------

-- HorizontalSpace adds a space in the UI that is the designated relative width
function GambleUI:HoritzonalSpace(container, width)
    -- a spacer is really just an empty label
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFontObject(GameFontHighlight)

    -- with the designated relative width
    spacer:SetRelativeWidth(width)

    -- add the label to the container
    container:AddChild(spacer)
end

-- VerticalSpace adds a vertical spacing in the UI that can be one of three sizes "small", "medium", and "large".
-- the default value is "medium"
function GambleUI:VerticalSpace(container, size)
    -- a spacer is really just an empty label
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)

    -- the font size depends on the amount of vertical space requested
    if  size == "large" then
        spacer:SetFontObject(GameFontHighlightLarge)
    elseif size == "small" then
        spacer:SetFontObject(GameFontHighlightSmall)
    else
        spacer:SetFontObject(GameFontHighlight)
    end

    -- add the label to the container
    container:AddChild(spacer)
end
