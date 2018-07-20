-- utility function for state prev_s
-- simulate forward some number of seconds, then apply a heuristic.  Return evaluation.
-- positive numbers are good for the bot, while
-- negative numbers are good for the enemy
function bot_esparanbot_eval1(prev_s, user)
    local bot = BOT_ESPARANBOT[user.n]
    
    --local s = bot_esparanbot_simulate(prev_s, prev_s.time + 30, false)
    
    local s = prev_s
    
    -- simply add the number of ships the bot has
    -- and subtract the number of enemy ships
    local total = bot_esparanbot_sum_ships(s, user)
    total = total - bot_esparanbot_sum_enemy_ships(s, user)
    
    return total
end

-- return the number of ships belonging to user in state s
function bot_esparanbot_sum_ships(s, user)
    local planets = s.planets
    local fleets = s.fleets
    
    local sum = 0
    
    for _i, planet in pairs(planets) do
        if planet.owner_n == user.n then
            sum = sum + planet.ships_value
        end
    end
    
    for _i, fleet in pairs(fleets) do
        if fleet.owner_n == user.n then
            sum = sum + fleet.fleet_ships
        end
    end
    
    return sum
end

-- return the number of ships NOT belonging to user in state s
function bot_esparanbot_sum_enemy_ships(s, user)
    local sum = 0
    for _i, planet in pairs(s.planets) do
        if not g2.item(planet.owner_n).user_neutral and planet.owner_n ~= user.n then
            sum = sum + planet.ships_value
        end
    end
    
    for _i, fleet in pairs(s.fleets) do
        if fleet.owner_n ~= user.n then
            sum = sum + fleet.fleet_ships
        end
    end
    
    return sum
end