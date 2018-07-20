-- utility function for state s
-- positive numbers are good for the bot, while
-- negative numbers are good for the enemy
function bot_carlsen_eval1(prev_s)
    local BOT = BOT_CARLSEN
    local sum_ships = bot_carlsen_sum_ships
    
    --[[
    for _i, fleet in pairs(prev_s.fleets) do
    print("fleets before: "..fleet.n.." "..fleet.fleet_target)
        local target = prev_s.planets[fleet.fleet_target]
    print("fleet target: "..target.position_x..", "..target.position_y)
    print("fleet position: "..fleet.position_x..", "..fleet.position_y)
    end
    --]]
    local s = bot_carlsen_simulate(prev_s, prev_s.time + 30, false)
    
    --[[
    for _i, fleet in pairs(s.fleets) do
    print("fleets after: "..fleet.n.." "..fleet.fleet_target)
    local target = s.planets[fleet.fleet_target]
    print("fleet target: "..target.position_x..", "..target.position_y)
    print("fleet position: "..fleet.position_x..", "..fleet.position_y)
    end
    --]]
    
    -- simply add the number of ships the bot has
    -- and subtract the number of enemy ships
    local total = sum_ships(s, BOT.user)
    total = total - 1.0001*sum_ships(s, BOT.enemy_user)
    
    return total
end

-- utility function for state s
-- positive numbers are good for the bot, while
-- negative numbers are good for the enemy
function bot_carlsen_eval2(s)
    local BOT = BOT_CARLSEN
    local sum_ships = bot_carlsen_sum_ships
    
    -- simply add the number of ships the bot has
    -- and subtract the number of enemy ships
    local total = sum_ships(s, BOT.user)
    total = total - sum_ships(s, BOT.enemy_user)
    
    return total
end