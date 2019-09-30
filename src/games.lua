-- the list of games that we can play
Games = {}

Games["HiLo"] ={
    Name = "HiLo",
    Explain = "Some really helpful text",
    Execute = function (players, maxRisk) 
        -- we have to start by collecting the rolls from every player
        GambleCore:CollectSameRoll(players, 1, maxRisk, function(results) 
            -- the extreme rolls
            local lowest = nil
            local highest = nil

            -- go over every result
            for player, value in pairs(results) do
                -- the entry for this paid
                local record = { name = player, value = value}

                -- if there is no highest or lowest use this
                if lowest == nil and highest == nil then
                    lowest = record
                    highest = record
                end

                -- if the value is lower than the lowest we've seen
                if value < lowest.value then
                    lowest = record
                elseif value > highest.value then
                    highest = record
                end
            end
            
            -- TODO: handle ties

            -- the game is over
            GambleCore:GameOver(highest, lowest, highest.value - lowest.value)
            return
        end)
    end,
}
