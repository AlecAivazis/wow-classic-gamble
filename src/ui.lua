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
    -- save a local reference to the current game
    local game = GambleCore:CurrentGame()

    -- if there is no current game
    if not game then
        GambleUI:_drawPlayTab_noCurrentGame(container)

    -- there is a game going on
    else 
        -- show some basic information about the game, regardless of the current phase

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
        hostLabel:SetText("Host: " .. game.host)
        hostLabel:SetFontObject(GameFontHighlightMedium)
        container:AddChild(hostLabel)
    
        -- some more spacing
        GambleUI:VerticalSpace(container, "small")

        -- show the phase-specific content
        if game.phase == GamePhase.GatheringPlayers then
            GambleUI:_drawPlayTab_gatheringPlayers(container)
        -- otherwise the game could be going and rolls being made
        elseif game.phase == GamePhase.Rolling then
            GambleUI:_drawPlayTab_rolling(container)
        -- or the game could be over
        elseif game.phase == GamePhase.Results then
            GambleUI:_drawPlayTab_results(container)
        end
    end
end

-- the state of the play tab when there is no game playing
function GambleUI:_drawPlayTab_noCurrentGame(container)

    -- show some configuration before the game selection
    local riskInput = AceGUI:Create("EditBox")
    riskInput:SetLabel("Maximum Risk")
    riskInput:SetRelativeWidth(0.45)
    riskInput:SetText("7777")
    container:AddChild(riskInput)

    GambleUI:HoritzonalSpace(container, 0.1)
    
    -- last call input
    local lastCallInput = AceGUI:Create("EditBox")
    lastCallInput:SetLabel("Last Call to Join (in seconds)")
    lastCallInput:SetRelativeWidth(0.45)
    lastCallInput:SetText("5")
    container:AddChild(lastCallInput)


    -- some spacing between controls and game type
    GambleUI:VerticalSpace(container, "small")

    
    -- there is no game currently in progress so we just need to render the options to kick off a new game
    local head = AceGUI:Create("Heading")
    head:SetText("Start a Game")
    head:SetFullWidth(true)
    container:AddChild(head)

    -- some vertical spacing under the header
    GambleUI:VerticalSpace(container, "small")

    -- each potential game gets a button in the UI

    -- build a sorted list of each game
    local orderedGameKeys = {}
    for k in pairs(Games) do
        table.insert(orderedGameKeys, k)
    end

    -- sort the list
    table.sort(orderedGameKeys)

    -- for each game
    for i = 1, #orderedGameKeys do
        -- the game we are giving a button
        local game = Games[orderedGameKeys[i]]

        -- add the button
        local button = AceGUI:Create("Button")
        button:SetText(game.Name)
        button:SetRelativeWidth(0.48)
        button:SetCallback("OnClick", function() GambleCore:NewGame(game.Name, tonumber(riskInput:GetText())) end)
        container:AddChild(button)

        -- if the button is in the left column
        if i % 2 == 1 then
            -- we need a 10% space before we add the right column
            GambleUI:HoritzonalSpace(container, 0.04)
        -- the button is on the right
        else 
            -- add a little before the next row
            GambleUI:VerticalSpace(container, "small")
        end
    end
end

function GambleUI:_drawPlayTab_gatheringPlayers(container)
    -- save a reference to the current game
    local game = GambleCore:CurrentGame()

    -- if the current user is the host
    if GambleCore:IsHosting() then
        -- add a commands section the host can use to officiate
        local hostHeader = AceGUI:Create("Heading")
        hostHeader:SetText("Host Commands")
        hostHeader:SetFullWidth(true)
        container:AddChild(hostHeader)

        -- a button to cancel the current game
        local cancelButton = AceGUI:Create("Button")
        cancelButton:SetText("Cancel Game")
        cancelButton:SetRelativeWidth(0.32)
        cancelButton:SetCallback("OnClick", function() GambleCore:CancelGame() end)
        container:AddChild(cancelButton)
        
        -- some spacing between the buttons
        GambleUI:HoritzonalSpace(container, 0.01)
    
        -- a button to explain the current game
        local explainButton = AceGUI:Create("Button")
        explainButton:SetText("Explain")
        explainButton:SetRelativeWidth(0.32)
        explainButton:SetCallback("OnClick", function() GambleCore:Explain() end)
        container:AddChild(explainButton)

        -- if there are at least two players present we can start the game
        if GambleCore:CurrentNumberOfPlayers() >= 2 then
            -- some spacing between the buttons
            GambleUI:HoritzonalSpace(container, 0.01)
    
            -- a button to start the game
            local finalizeButton = AceGUI:Create("Button")
            finalizeButton:SetText("Begin Game")
            finalizeButton:SetRelativeWidth(0.32)
            finalizeButton:SetCallback("OnClick", function() GambleCore:StartGame() end)
            container:AddChild(finalizeButton)
        end
        
        -- some more spacing
        GambleUI:VerticalSpace(container, "small")
    end 

    -- player commands
    local hostHeader = AceGUI:Create("Heading")
    hostHeader:SetText("Player Commands")
    hostHeader:SetFullWidth(true)
    container:AddChild(hostHeader)

    -- the fully qualified name of the current player
    local currentPlayerName = UnitName("player")

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
    for _, user in ipairs(GambleCore:CurrentPlayers()) do
        players = players .. user .. ", "
    end
    -- update the body of the element
    playersBody:SetText(players:sub(0, -3))
end

function GambleUI:_drawPlayTab_rolling(container)
    -- add the host commands
    if GambleCore:IsHosting() then
        -- add a commands section the host can use to officiate
        local hostHeader = AceGUI:Create("Heading")
        hostHeader:SetText("Host Commands")
        hostHeader:SetFullWidth(true)
        container:AddChild(hostHeader)
        
        -- a button to cancel the current game
        local cancelButton = AceGUI:Create("Button")
        cancelButton:SetText("Cancel Game")
        cancelButton:SetRelativeWidth(0.32)
        cancelButton:SetCallback("OnClick", function() GambleCore:CancelGame() end)
        container:AddChild(cancelButton)
        
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
    end

    -- add a player commands section if the user needs to roll
    if GambleCore:PlayerNeedsToRoll() then
        -- add players commands
        local playerHeader = AceGUI:Create("Heading")
        playerHeader:SetText("Player Commands")
        playerHeader:SetFullWidth(true)
        container:AddChild(playerHeader)

        -- a button to roll
        local RollButton = AceGUI:Create("Button")
        RollButton:SetText("Roll")
        RollButton:SetRelativeWidth(0.32)
        RollButton:SetCallback("OnClick", function() GambleCore:Roll() end)
        container:AddChild(RollButton)

        -- some more spacing
        GambleUI:VerticalSpace(container, "small")
    end

    -- if there is at least one result
    if GambleCore:NumberOfRollResults() > 0 then
        -- add a section with the roll results
        local resultsHeader = AceGUI:Create("Heading")
        resultsHeader:SetText("Results")
        resultsHeader:SetFullWidth(true)
        container:AddChild(resultsHeader)

        -- each roll result gets its own line
        for user, result in pairs(GambleCore:RollResults()) do
            local playerScore = AceGUI:Create("Label")
            playerScore:SetFullWidth(true)
            playerScore:SetFontObject(GameFontHighlightMedium)
            playerScore:SetText(user .. " -> " .. result)
            container:AddChild(playerScore)

        end

        -- some more spacing
        GambleUI:VerticalSpace(container, "small")
    end

    -- if there is at least one pending roll
    if GambleCore:NumberOfPendingRolls() > 0 then
        -- and a section with the people have have yet to roll
        local resultsHeader = AceGUI:Create("Heading")
        resultsHeader:SetText("Pending Rolls")
        resultsHeader:SetFullWidth(true)
        container:AddChild(resultsHeader)
        
        -- the list of users that have to roll
        local playersBody = AceGUI:Create("Label")
        playersBody:SetFullWidth(true)
        playersBody:SetFontObject(GameFontHighlightMedium)
        container:AddChild(playersBody)

        -- compute the actual players text
        local players = ""
        for user in pairs(GambleCore:PendingRolls()) do
            players = players .. user .. ", "
        end
        -- update the body of the element
        playersBody:SetText(players:sub(0, -3))
    end
end


function GambleUI:_drawPlayTab_results(container)
    -- the results of the game
    local result = GambleCore:CurrentGame().result

    -- the name of the winner
    local content = AceGUI:Create("Label")
    content:SetFontObject(GameFontHighlightLarge)
    content:SetFullWidth(true)
    content:SetText(result.winner.name .. " won " .. result.amount .." with a roll of " .. result.winner.value .. "!")
    container:AddChild(content)

    -- some spacing
    GambleUI:VerticalSpace(container, "large")

    -- a message for the loser
    local content = AceGUI:Create("Label")
    content:SetFullWidth(true)
    content:SetFontObject(GameFontHighlightLarge)
    content:SetText(
        result.loser.name .. " lost with their roll of " .. result.loser.value ..  "."
    )

    container:AddChild(content)

    -- some spacing
    GambleUI:VerticalSpace(container, "large")

    -- a button to play another
    local continueButton = AceGUI:Create("Button")
    continueButton:SetText("Play Again!")
    continueButton:SetRelativeWidth(0.32)
    continueButton:SetCallback("OnClick", function() GambleCore:Reset() end)
    container:AddChild(continueButton)
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
