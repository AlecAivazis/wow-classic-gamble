GambleUI = {}

-- local imports
local AceGUI = LibStub("AceGUI-3.0")

-- tab name constants
local TabPlay = "play"
local TabHistory = "history"

function GambleUI:Initialize()
    -- create the root frame
    GambleUI.frame = AceGUI:Create("Frame")

    -- configure the frame
    GambleUI.frame:SetTitle("Gamble")
    GambleUI.frame:SetStatusText("v0.0.0")
    GambleUI.frame:SetLayout("Fill")
    GambleUI.frame:SetWidth(400)
    GambleUI.frame:SetHeight(300)

    -- create the tab group at the root of the UI
    GambleUI.tabs = AceGUI:Create("TabGroup")
    GambleUI.tabs:SetLayout("Flow")
    GambleUI.tabs:SetTabs({
        {
            text = "Play",
            value=TabPlay
        },
        {
            text = "History",
            value=TabHistory
        },
    })
    GambleUI.tabs:SetCallback("OnGroupSelected", function (container, event, tabName)
        -- save a reference to the container in case we need to update it out of band
        GambleUI._tabFrame = container
        GambleUI._currentTab = tabName
        
        -- draw the selected tab
        GambleUI:_drawTab(container, tabName)
    end )
    GambleUI.tabs:SelectTab(TabPlay)
    -- add the select to the frame
    GambleUI.frame:AddChild(GambleUI.tabs)

    -- make sure the frame starts hidden
    GambleUI.frame:Hide()
end

-- Shows the UI
function GambleUI:Show()
    -- force the play tab to always be open at first
    GambleUI.tabs:SelectTab(TabPlay)

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
    if which == TabPlay then
        GambleUI:_drawPlayTab(scrollContainer)
    -- otherwise they could be showing the history tab
    elseif which == TabHistory then 
        GambleUI:_drawHistoryTab(scrollContainer)
    end
end

-- invoked when the user wants to draw the play tab
function GambleUI:_drawPlayTab(container) 
    -- if there is no current game
    if not GambleCore.currentGame then 
        -- render the appropriate state of the playtab
        GambleUI:_drawPlayTab_noCurrentGame(container)
    -- otherwise there is a game currently going
    else
        -- render the summary of the current game
        GambleUI:_drawPlayTab_currentGame(container)
    end
end

-- the state of the play tab when there is no game playing
function GambleUI:_drawPlayTab_noCurrentGame(container)
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

function GambleUI:_drawPlayTab_currentGame(container) 
    -- for now just tell them its coming
    local content = AceGUI:Create("Label")
    content:SetText("theres a game going!")

    container:AddChild(content)
end

-- invoked when the user wants to draw the history tab
function GambleUI:_drawHistoryTab(container)
    -- for now just tell them its coming
    local content = AceGUI:Create("Label")
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