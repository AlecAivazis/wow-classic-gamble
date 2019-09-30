-- the list of games that we can play
Games = {}

Games["HiLo"] ={
    Name = "HiLo",
    Explain = "Some really helpful text",
    Execute = function (players, maxRisk) 
        -- notify people that the game has actually started
        GambleCore:Say("Okay! Let's begin. Everyone roll a number between 1  and " .. maxRisk .. ".")
        GambleCore:Say("In case you didn't know, you can do that with /roll " .. maxRisk)

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

            -- the amount won
            local winnings = highest.value - lowest.value

            -- tell everyone what just happend
            GambleCore:Say(highest.name .. " won! " .. lowest.name .. " owes " .. "them " .. winnings .. ".")

            -- the game is over
            GambleCore:GameOver(highest, lowest, winnings)
            return
        end)
    end,
}
