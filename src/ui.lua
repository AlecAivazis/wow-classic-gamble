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
        -- clear the contents of the tab container
        container:ReleaseChildren()

        -- if the user is showing the play tab
        if tabName == TabPlay then
            GambleUI:_drawPlayTab(container)
        -- otherwise they could be showing the history tab
        elseif tabName == TabHistory then 
            GambleUI:_drawHistoryTab(container)
        end
    end )
    GambleUI.tabs:SelectTab(TabPlay)
    -- add the select to the frame
    GambleUI.frame:AddChild(GambleUI.tabs)

    -- make sure the frame starts hidden
    GambleUI.frame:Hide()
end

-- Show shows the UI
function GambleUI:Show()
    -- force the play tab to always be open at first
    GambleUI.tabs:SelectTab(TabPlay)
    
    GambleUI.frame:Show()
end

-- Hide hides the UI
function GambleUI:Hide()
    GambleUI.frame:Hide()
end


-- invoked when the user wants to draw the play tab
function GambleUI:_drawPlayTab(container) 

end

-- invoked when the user wants to draw the history tab
function GambleUI:_drawHistoryTab(container)

end