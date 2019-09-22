GambleCore = {}

-- invoked when Gamble first comes online
function GambleCore:Initialize()

end

-- used to start a game between this and all listening instances of Gamble
function GambleCore:StartGame(type)
    print("starting game of type: " .. type)
end