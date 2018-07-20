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
    
    bot.neutral_user = bot.neutral_user or bot_vacuumbot_get_user_neutral()
    bot.map = bot_vacuumbot_get_map()
    bot_vacuumbot_calculate_closest_planets(user)
    
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
    bot_vacuumbot_update_incoming_fleets(user)
    
    -- TEST TUNNELS
    --[[  
    local path = ""
    local tunnel = bot.map.planets[4].tunnel[5]
    for k,v in pairs(tunnel) do
        path = path .. v.n .. " "
    end
    g2.status = path
    --]]
    
    -- TEST TUNNEL DISTANCE
    --g2.status = bot.map.planets[4].tunnel_dist[5]

    
    -- sort according to predicted number of ships gained in HORIZON seconds divided by number of ships spent to capture
    -- takes into account estimated time to capture the planet
    --DOES NOT TAKE INTO ACCOUNT THE FACT THAT NEARBY PLANETS CAPTURED IN THE FUTURE WILL CONTRIBUTE TO EXTRA PRODUCTION
    local planets = g2.search("planet neutral")
    
    
    -- doesn't take distance into account
    --[[
    table.sort(planets, function(p1,p2) 
        if p1 ~= nil and p2 ~= nil then 
            if p1.ships_production / (p1.ships_value + 1) 
                > p2.ships_production / (p2.ships_value + 1)  then 
                return true 
            end 
        end 
    end)
    --]]
    -- use estimated time to capture
    ---[[
    table.sort(planets, function(p1,p2) 
        local horizon = 15
        local time_to_capture1 = simplified_estimated_time_to_capture(user, p1)
        local time_to_capture2 = simplified_estimated_time_to_capture(user, p2)
        if p1 ~= nil and p2 ~= nil then 
            if (prod_to_ships(p1.ships_production) * (horizon - time_to_capture1) - p1.ships_value) / (p1.ships_value + 1) 
                > (prod_to_ships(p2.ships_production) * (horizon - time_to_capture2) - p2.ships_value) / (p2.ships_value + 1)  then 
                return true 
            end 
        end 
    end)
    --]]

    -- DOES NOT TAKE INTO ACCOUNT PLANETS THAT HAVE MORE THAN ONE GOOD TARGET IN THE VISCINITY
    for _i,target in pairs(planets) do
        local amount_left = target.ships_value + 1 -- make sure it's captured
        
        local incoming_fleets = bot.map.incoming_fleets[target.n]
        -- sum incoming fleets... and figure out how many more ships to send  -- FLEET ARRIVAL TIME NOT TAKEN INTO ACCOUNT
        for _i,f in ipairs(incoming_fleets) do
            if target.owner_n == f.owner_n then
                amount_left = amount_left + f.fleet_ships
            else
                amount_left = amount_left - f.fleet_ships
            end
        end
    
        -- send ships from friendly planets to the target in increasing order
        -- of distance from the target
        local closest_planets = bot.map.planets[target.n].neighbors
        local time_elapsed = 0
        local attacking_prod = 0
        for _i,p_n in pairs(closest_planets) do
            local p = bot.map.planets[p_n]
            if p.owner_n == user.n then
                -- if p has ships to send
                local new_time_elapsed = dist_to_time(p.dist[target.n]) -- replace with tunnel distance later 
                local diff = new_time_elapsed - time_elapsed
                time_elapsed = new_time_elapsed
                amount_left = amount_left - diff*prod_to_ships(attacking_prod) -- production from all CLOSER planets
                if p.ships_value > amount_left then -- there are enough stored ships in this planet to capture
                    local ships_sent = send_exact(user, g2.item(p.n), target, amount_left)
                    amount_left = amount_left - ships_sent
                    break
                else
                    local ships_sent = send_exact(user, g2.item(p.n), target, target.ships_value)
                    amount_left = amount_left - ships_sent
                end
                if p.ships_production_enabled then
                    attacking_prod = attacking_prod + p.ships_production -- make sure planet is owned by user.. and ships production enabled
                end
            end
        end

    end
       
end

function estimated_time_to_capture(user, target)
    local bot = BOT_VACUUMBOT[user.n]
    
    local amount_left = target.ships_value + 1 -- make sure it's captured
    
    local incoming_fleets = bot.start_state.incoming_fleets[target.n]
    -- sum incoming fleets... and figure out how many more ships to send  -- FLEET ARRIVAL TIME NOT TAKEN INTO ACCOUNT
    for _i,f in ipairs(incoming_fleets) do
        if target.owner_n == f.owner_n then
            amount_left = amount_left + f.fleet_ships
        else
            amount_left = amount_left - f.fleet_ships
        end
    end

    -- send ships from friendly planets to the target in increasing order
    -- of distance from the target
    local closest_planets = bot.map.planets[target.n].neighbors
    local time_elapsed = 0
    local attacking_prod = 0
    for _i,p_n in pairs(closest_planets) do
        local p = bot.map.planets[p_n]
        if p.owner_n == user.n then
            local new_time_elapsed = dist_to_time(p.dist[target.n]) -- replace with tunnel distance later 
            local diff = new_time_elapsed - time_elapsed
            time_elapsed = new_time_elapsed
            amount_left = amount_left - diff*prod_to_ships(attacking_prod) -- production from all CLOSER planets
            if p.ships_value > amount_left then -- there are enough stored ships in this planet to capture
                break
            else
                amount_left = amount_left - p.ships_value
            end
            if p.ships_production_enabled then
                attacking_prod = attacking_prod + p.ships_production -- make sure planet is owned by user.. and ships production enabled
            end
        end
    end
    
    local time_to_capture = time_elapsed
    
    -- TEMPORARY:  LARGEST FLEET DISTANCE IS TIME TO CAPTURE
    for _i,f in ipairs(incoming_fleets) do
        if target.owner_n == f.owner_n then
            if f.arrival_time > time_to_capture then
                time_to_capture = f.arrival_time
            end
        end
    end
    
    return time_to_capture
end

function simplified_estimated_time_to_capture(user, target)
    local bot = BOT_VACUUMBOT[user.n]
    
    local amount_left = target.ships_value + 1 -- make sure it's captured
    
    local incoming_fleets = bot.map.incoming_fleets[target.n]
    -- sum incoming fleets... and figure out how many more ships to send  -- FLEET ARRIVAL TIME NOT TAKEN INTO ACCOUNT
    for _i,f in ipairs(incoming_fleets) do
        if target.owner_n == f.owner_n then
            amount_left = amount_left + f.fleet_ships
        else
            amount_left = amount_left - f.fleet_ships
        end
    end

    -- send ships from friendly planets to the target in increasing order
    -- of distance from the target
    local closest_planets = bot.map.planets[target.n].neighbors
    local time_elapsed = 0
    local attacking_prod = 0
    for _i,p_n in pairs(closest_planets) do
        local p = bot.map.planets[p_n]
        if p.owner_n == user.n then
            local new_time_elapsed = dist_to_time(p.dist[target.n]) -- replace with tunnel distance later 
            local diff = new_time_elapsed - time_elapsed
            time_elapsed = new_time_elapsed
            amount_left = amount_left - diff*prod_to_ships(attacking_prod) -- production from all CLOSER planets
            if p.ships_value > amount_left then -- there are enough stored ships in this planet to capture
                break
            else
                amount_left = amount_left - p.ships_value
            end
            if p.ships_production_enabled then
                attacking_prod = attacking_prod + p.ships_production -- make sure planet is owned by user.. and ships production enabled
            end
        end
    end
    
    local time_to_capture = time_elapsed
    
    return time_to_capture
end

function error(string)
    print("Vacuumbot: Fatal Error: " .. string)
end

function warning(string)
    if DEBUG then
        print("Vacuumbot: Warning: " .. string)
    end
end