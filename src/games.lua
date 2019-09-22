-- the list of games that we can play
Games = {}

Games["HiLo"] ={
    Name = "HiLo",
    Explain = "Some really helpful text",
    Execute = function (players) 
        -- we have to start by collecting the rolls from every player
        GambleCore:CollectSameRoll(players, 1, 7777, function(results) 
            print("roll results:")

            for player, value in pairs(results) do
                print(player .. " rolled " .. value)
            end
        end, nil)
    end,
}

Games["Big Twos"] = {
    Name = "Big Twos",
    Explain = "Some really helpful text",
}