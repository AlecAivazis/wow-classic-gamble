-- the entrypoint for chat based interactions
function GambleAddon:ParseCmd(input) 
    -- remove any slashes from the command
    input = string.trim(input, " ")

    -- /gamble
    if input == "" or not input then 
        return GambleAddon:RootCmd()
    end
    
    -- we did not recognize the command
    print("Unrecognized command: \"" .. input .."\".  Please try again.") 
end

-- a command with no inputs
function GambleAddon:RootCmd()
    -- open the UI
    GambleUI.Show()
end