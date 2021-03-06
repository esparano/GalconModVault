require("bot_util")
require("bot_vacuumbot_map")

-- initialize bot(s) - call once even if multiple bots
function init_vacuumbot()
    global("BOT_VACUUMBOT")
    BOT_VACUUMBOT = BOT_VACUUMBOT or {}
    
    global("DEBUG")
    DEBUG = true
end

-- reset bot(s) before EVERY game - call once even if multiple bots
function reset_vacuumbot()
    BOT_VACUUMBOT = {}
end

-- first-turn setup.  return a reference to the bot data
function first_turn_setup(user)
    BOT_VACUUMBOT[user.n] = {}
    local bot = BOT_VACUUMBOT[user.n]
    
    bot.horizon = 15
    bot.neutral_user = bot.neutral_user or bot_vacuumbot_get_user_neutral()
    bot.map = bot_vacuumbot_get_map()
    bot_vacuumbot_calculate_closest_planets(user)
    
    DEBUG = true
    if (DEBUG) then 
        debug_view(user, "n")
    end
    
    return bot
end

-- print a label below each planet of the planet's property
function debug_view(user, property, offset)
    offset = offset or 0
    local bot = BOT_VACUUMBOT[user.n]
    for _i, planet in pairs(bot.map.planets) do
        local s = tostring(planet[property])
        g2.new_label(s, planet.position_x, planet.position_y + 30 + offset)
    end 
end

-- bot loop called every tick
function bot_vacuumbot(user)
    -- first-turn setup?
    local bot = BOT_VACUUMBOT[user.n] or first_turn_setup(user) 
    
    -- recompute optimal tunnels IF NECESSARY (if owner of ANY planet has changed)
    local recalculate = false
    for i,planet in pairs(bot.map.planets) do
        local real_planet = g2.item(planet.n)
        local new_owner_n = real_planet.owner_n
        if new_owner_n ~= planet.owner_n then
            recalculate = true
            break
        end
    end
    
    -- update planet properties but don't recalculate closest planets
    local old_map = bot.map
    bot.map = bot_vacuumbot_get_map()
    for i,planet in pairs(old_map.planets) do
        bot.map.planets[planet.n].neighbors = planet.neighbors
    end
    if recalculate then bot_vacuumbot_compute_tunnels(user) end ----------- EXPENSIVE
    bot_vacuumbot_compute_tunnels(user)
    bot_vacuumbot_update_incoming_fleets(user)
    bot_vacuumbot_calculate_initial_time_to_capture(user)
    
    --[[
    -- better estimation
    bot_vacuumbot_compute_tunnels(user)
    bot_vacuumbot_update_incoming_fleets(user)
    bot_vacuumbot_calculate_estimated_time_to_capture(user)
`   --]]
    --[[
    -- even better estimation
    bot_vacuumbot_compute_tunnels(user)
    bot_vacuumbot_update_incoming_fleets(user)
    bot_vacuumbot_calculate_better_estimated_time_to_capture(user)
    --]]
    
    -- actually send
    bot_vacuumbot_compute_tunnels(user)
    bot_vacuumbot_update_incoming_fleets(user)


    -- sort according to predicted number of ships gained in HORIZON seconds divided by number of ships spent to capture
    -- takes into account estimated time to capture the planet
    local targets = g2.search("planet neutral") 
    for _i,p in pairs(bot.map.planets) do
        p.sort_ships_value = sort_ships_value(user, p)
    end
    table.sort(targets, function(p1,p2) 
        local planet1 = bot.map.planets[p1.n]
        local planet2 = bot.map.planets[p2.n]
        if (prod_to_ships(planet1.ships_production) * (bot.horizon - planet1.time_to_capture) - planet1.sort_ships_value) / (planet1.sort_ships_value + 1) 
            > (prod_to_ships(planet2.ships_production) * (bot.horizon - planet2.time_to_capture) - planet2.sort_ships_value) / (planet2.sort_ships_value + 1)  then 
            return true 
        end 
    end)

    for _q,target in ipairs(targets) do
        print("n: " .. target.n .. ", time_to_capture: " .. bot.map.planets[target.n].time_to_capture .. ", busy_until: " .. bot.map.planets[target.n].busy_until)
        local amount_left = bot.map.planets[target.n].ships_value
        local incoming_fleets = bot.map.incoming_fleets[target.n]
        -- sum incoming fleets... and figure out how many more ships to send  -- FLEET ARRIVAL TIME NOT TAKEN INTO ACCOUNT
        for _i,f in ipairs(incoming_fleets) do
            if target.owner_n == f.owner_n then
                amount_left = amount_left + f.fleet_ships
            else
                amount_left = amount_left - f.fleet_ships
            end
        end
        
        -- if the planet won't already be captured by fleets
        if amount_left >= 0 then
            amount_left = amount_left + 1 -- make sure it's captured
            -- send ships from friendly planets to the target in increasing order
            -- of distance from the target
            local planets_to_check = {}
            local closest_planets = bot.map.planets[target.n].neighbors
            for _i,p_n in ipairs(closest_planets) do
                local neighbor = bot.map.planets[p_n]
                if neighbor.owner_n == user.n then  -- ONLY CONSIDERS OWNED PLANETS OR NEUTRAL PLANETS AS SOURCE OF SHIPS
                    table.insert(planets_to_check, p_n)
                elseif g2.item(neighbor.owner_n).user_neutral and neighbor.time_to_capture < bot.horizon then
                    table.insert(planets_to_check, p_n)
                end
            end
            -- sort planets by arrival time of the first ship to be sent from the planet (counting busy_until)
            table.sort(planets_to_check, function(p1_n,p2_n) 
                local p1 = bot.map.planets[p1_n]
                local p2 = bot.map.planets[p2_n]
                local effective_dist1 = p1.busy_until + dist_to_time(p1.tunnel_dist[target.n])
                local effective_dist2 = p2.busy_until + dist_to_time(p2.tunnel_dist[target.n])
                if effective_dist1 < effective_dist2 then return true end
            end)
            
            local time_elapsed = 0
            local attacking_prod = 0
            for _j, p_n in ipairs(planets_to_check) do
                local p = bot.map.planets[p_n]
                local new_time_elapsed = p.busy_until + dist_to_time(p.tunnel_dist[target.n]) -- replace with tunnel distance later 
                local diff = new_time_elapsed - time_elapsed
                if amount_left - diff*prod_to_ships(attacking_prod) < 0 then
                    time_elapsed = time_elapsed + amount_left / prod_to_ships(attacking_prod)
                    break
                end
                time_elapsed = new_time_elapsed
                amount_left = amount_left - diff*prod_to_ships(attacking_prod) -- production from all CLOSER planets
                -- possibly stored send ships on this planet if it is friendly (fleets coming TO the planet count as "stored")
                -- otherwise, just add the production contribution
                if p.owner_n == user.n then
                    local tunnel_alias = p.tunnel[target.n][1]
                    if p.ships_value + p.total_incoming_fleets > amount_left then -- there are enough "stored" ships in this planet to capture
                        if p.ships_value < amount_left then
                            local num_sent = send_exact(user, g2.item(p.n), g2.item(tunnel_alias.n), p.ships_value)
                            p.total_incoming_fleets = math.max(p.total_incoming_fleets - (amount_left - num_sent), 0) -- use up some fleets
                            -- weird bug where num_sent doesn't match number of ships sent... if p.ships_value is very small
                        else 
                            send_exact(user, g2.item(p.n), g2.item(tunnel_alias.n), amount_left)
                        end
                        break
                    else
                        local ships_sent = send_exact(user, g2.item(p.n), g2.item(tunnel_alias.n), p.ships_value)
                        amount_left = amount_left - ships_sent - p.total_incoming_fleets
                        p.total_incoming_fleets = 0
                    end
                end
                attacking_prod = attacking_prod + p.ships_production -- make sure planet is owned by user.. and ships production enabled
            end
            -- steal control of all planets within the attacking radius
            for _i,p_n in ipairs(planets_to_check) do
                local p = bot.map.planets[p_n]
                 local new_time_elapsed = p.busy_until + dist_to_time(p.tunnel_dist[target.n])
                -- if it WAS inside the circle
                if new_time_elapsed < time_elapsed then
                    -- take control of the planet
                    if p.busy_until < time_elapsed then
                        p.busy_until = time_elapsed
                    end
                end  
            end
        end
    end
end

function estimated_time_to_capture(user, target)
    local bot = BOT_VACUUMBOT[user.n]
    
    local amount_left = bot.map.planets[target.n].est_ships_value
    local incoming_fleets = bot.map.incoming_fleets[target.n]
    -- sum incoming fleets... and figure out how many more ships to send  -- FLEET ARRIVAL TIME NOT TAKEN INTO ACCOUNT
    for _i,f in ipairs(incoming_fleets) do
        if target.owner_n == f.owner_n then
            amount_left = amount_left + f.fleet_ships
        else
            amount_left = amount_left - f.fleet_ships
        end
    end
    
    -- if the planet won't already be captured by fleets
    if amount_left >= 0 then
        amount_left = amount_left + 1 -- make sure it's captured
        -- send ships from friendly planets to the target in increasing order
        -- of distance from the target
        local planets_to_check = {}
        local closest_planets = bot.map.planets[target.n].neighbors
        for _i,p_n in ipairs(closest_planets) do
            local neighbor = bot.map.planets[p_n]
            if neighbor.owner_n == user.n then  -- ONLY CONSIDERS OWNED PLANETS OR NEUTRAL PLANETS AS SOURCE OF SHIPS
                table.insert(planets_to_check, p_n)
            elseif g2.item(neighbor.owner_n).user_neutral and neighbor.time_to_capture < bot.horizon then
                table.insert(planets_to_check, p_n)
            end
        end
        -- sort planets by arrival time of the first ship to be sent from the planet (counting busy_until)
        table.sort(planets_to_check, function(p1_n,p2_n) 
            local p1 = bot.map.planets[p1_n]
            local p2 = bot.map.planets[p2_n]
            local effective_dist1 = p1.busy_until + dist_to_time(p1.tunnel_dist[target.n])
            local effective_dist2 = p2.busy_until + dist_to_time(p2.tunnel_dist[target.n])
            if effective_dist1 < effective_dist2 then return true end
        end)
        
        local time_elapsed = 0
        local attacking_prod = 0
        for _j, p_n in ipairs(planets_to_check) do
            local p = bot.map.planets[p_n]
            local new_time_elapsed = p.busy_until + dist_to_time(p.tunnel_dist[target.n]) -- replace with tunnel distance later 
            local diff = new_time_elapsed - time_elapsed
            if amount_left - diff*prod_to_ships(attacking_prod) < 0 then
                time_elapsed = time_elapsed + amount_left / prod_to_ships(attacking_prod)
                break
            end
            time_elapsed = new_time_elapsed
            amount_left = amount_left - diff*prod_to_ships(attacking_prod) -- production from all CLOSER planets
            -- possibly stored send ships on this planet if it is friendly (fleets coming TO the planet count as "stored")
            -- otherwise, just add the production contribution
            if p.owner_n == user.n then
                local tunnel_alias = p.tunnel[target.n][1]
                if p.est_ships_value + p.total_incoming_fleets > amount_left then -- there are enough "stored" ships in this planet to capture
                    if p.est_ships_value < amount_left then
                        p.total_incoming_fleets = p.total_incoming_fleets - (amount_left - p.est_ships_value) -- use up some fleets
                        p.est_ships_value = 0
                    else 
                        p.est_ships_value = p.est_ships_value - amount_left
                    end
                    break
                else
                    amount_left = amount_left - p.est_ships_value - p.total_incoming_fleets
                    p.est_ships_value = 0
                    p.total_incoming_fleets = 0
                end
            end
            attacking_prod = attacking_prod + p.ships_production -- make sure planet is owned by user.. and ships production enabled
        end
        --[[
        -- steal control of all planets within the attacking radius
        for _i,p_n in ipairs(planets_to_check) do
            local p = bot.map.planets[p_n]
             local new_time_elapsed = p.busy_until + dist_to_time(p.tunnel_dist[target.n])
            -- if it WAS inside the circle
            if new_time_elapsed < time_elapsed then
                -- take control of the planet
                if p.busy_until < time_elapsed then
                    p.busy_until = time_elapsed
                end
            end  
        end
        --]]
        return time_elapsed
    else
        local time_to_capture = 0
        amount_left = target.est_ships_value -- make sure it's captured
        incoming_fleets = bot.map.incoming_fleets[target.n]
        for _i,f in ipairs(incoming_fleets) do
            if target.owner_n == f.owner_n then
                amount_left = amount_left + f.fleet_ships
            else
                amount_left = amount_left - f.fleet_ships
                if amount_left < 0 then 
                    if time_to_capture < f.arrival_time then
                        time_to_capture = f.arrival_time
                    end
                    break
                end
            end
        end
        return time_to_capture
    end
end


function better_estimated_time_to_capture(user, target)
    local bot = BOT_VACUUMBOT[user.n]
    
    local amount_left = bot.map.planets[target.n].est_ships_value
    local incoming_fleets = bot.map.incoming_fleets[target.n]
    -- sum incoming fleets... and figure out how many more ships to send  -- FLEET ARRIVAL TIME NOT TAKEN INTO ACCOUNT
    for _i,f in ipairs(incoming_fleets) do
        if target.owner_n == f.owner_n then
            amount_left = amount_left + f.fleet_ships
        else
            amount_left = amount_left - f.fleet_ships
        end
    end
    
    -- if the planet won't already be captured by fleets
    if amount_left >= 0 then
        amount_left = amount_left + 1 -- make sure it's captured
        -- send ships from friendly planets to the target in increasing order
        -- of distance from the target
        local planets_to_check = {}
        local closest_planets = bot.map.planets[target.n].neighbors
        for _i,p_n in ipairs(closest_planets) do
            local neighbor = bot.map.planets[p_n]
            if neighbor.owner_n == user.n then  -- ONLY CONSIDERS OWNED PLANETS OR NEUTRAL PLANETS AS SOURCE OF SHIPS
                table.insert(planets_to_check, p_n)
            elseif g2.item(neighbor.owner_n).user_neutral and neighbor.time_to_capture < bot.horizon then
                table.insert(planets_to_check, p_n)
            end
        end
        -- sort planets by arrival time of the first ship to be sent from the planet (counting busy_until)
        table.sort(planets_to_check, function(p1_n,p2_n) 
            local p1 = bot.map.planets[p1_n]
            local p2 = bot.map.planets[p2_n]
            local effective_dist1 = p1.busy_until + dist_to_time(p1.tunnel_dist[target.n])
            local effective_dist2 = p2.busy_until + dist_to_time(p2.tunnel_dist[target.n])
            if effective_dist1 < effective_dist2 then return true end
        end)
        
        local time_elapsed = 0
        local attacking_prod = 0
        for _j, p_n in ipairs(planets_to_check) do
            local p = bot.map.planets[p_n]
            local new_time_elapsed = p.busy_until + dist_to_time(p.tunnel_dist[target.n]) -- replace with tunnel distance later 
            local diff = new_time_elapsed - time_elapsed
            if amount_left - diff*prod_to_ships(attacking_prod) < 0 then
                time_elapsed = time_elapsed + amount_left / prod_to_ships(attacking_prod)
                break
            end
            time_elapsed = new_time_elapsed
            amount_left = amount_left - diff*prod_to_ships(attacking_prod) -- production from all CLOSER planets
            -- possibly stored send ships on this planet if it is friendly (fleets coming TO the planet count as "stored")
            -- otherwise, just add the production contribution
            if p.owner_n == user.n then
                local tunnel_alias = p.tunnel[target.n][1]
                if p.est_ships_value + p.total_incoming_fleets > amount_left then -- there are enough "stored" ships in this planet to capture
                    if p.est_ships_value < amount_left then
                        p.total_incoming_fleets = p.total_incoming_fleets - (amount_left - p.est_ships_value) -- use up some fleets
                        p.est_ships_value = 0
                    else 
                        p.est_ships_value = p.est_ships_value - amount_left
                    end
                    break
                else
                    amount_left = amount_left - p.est_ships_value - p.total_incoming_fleets
                    p.est_ships_value = 0
                    p.total_incoming_fleets = 0
                end
            end
            attacking_prod = attacking_prod + p.ships_production -- make sure planet is owned by user.. and ships production enabled
        end
        ---[[
        -- steal control of all planets within the attacking radius
        for _i,p_n in ipairs(planets_to_check) do
            local p = bot.map.planets[p_n]
             local new_time_elapsed = p.busy_until + dist_to_time(p.tunnel_dist[target.n])
            -- if it WAS inside the circle
            if new_time_elapsed < time_elapsed then
                -- take control of the planet
                if p.busy_until < time_elapsed then
                    p.busy_until = time_elapsed
                end
            end  
        end
        --]]
        return time_elapsed
    else
        local time_to_capture = 0
        amount_left = target.est_ships_value -- make sure it's captured
        incoming_fleets = bot.map.incoming_fleets[target.n]
        for _i,f in ipairs(incoming_fleets) do
            if target.owner_n == f.owner_n then
                amount_left = amount_left + f.fleet_ships
            else
                amount_left = amount_left - f.fleet_ships
                if amount_left < 0 then 
                    if time_to_capture < f.arrival_time then
                        time_to_capture = f.arrival_time
                    end
                    break
                end
            end
        end
        return time_to_capture
    end
end

-- return ships_value plus/minus incoming fleets... regardless of fleet distance
function sort_ships_value(user, p)
    local bot = BOT_VACUUMBOT[user.n]
    local amount_left = p.ships_value -- make sure it's captured
    local incoming_fleets = bot.map.incoming_fleets[p.n]
    for _i,f in ipairs(incoming_fleets) do
        if p.owner_n == f.owner_n then
            amount_left = amount_left + f.fleet_ships
        else
            amount_left = amount_left - f.fleet_ships
            if amount_left < 0 then 
                return 0
            end
        end
    end
    return amount_left
end

-- if the planet will be captured without additional help, return amount of time until capture
-- otherwise return 100000000 seconds
function initial_time_to_capture(user, target)
    local bot = BOT_VACUUMBOT[user.n]
    local time_to_capture = 0
    local amount_left = target.ships_value -- make sure it's captured
    local incoming_fleets = bot.map.incoming_fleets[target.n]
    for _i,f in ipairs(incoming_fleets) do
        if target.owner_n == f.owner_n then
            amount_left = amount_left + f.fleet_ships
        else
            amount_left = amount_left - f.fleet_ships
            if amount_left < 0 then 
                if time_to_capture < f.arrival_time then
                    time_to_capture = f.arrival_time
                end
                return time_to_capture
            end
        end
    end
    
end

function error(string)
    print("Vacuumbot: Fatal Error: " .. string)
end

function warning(string)
    if DEBUG then
        print("Vacuumbot: Warning: " .. string)
    end
end