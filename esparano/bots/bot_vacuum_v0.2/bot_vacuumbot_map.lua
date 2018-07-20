-- get a representation of the map
-- can only afford one of these per tick before starting to lag
function bot_vacuumbot_get_map()
    local map = {}
    
    -- get copy of all planets in the game
    map.planets = {}
    local g2_planets = planet_array or g2.search("planet")
    for _i, p in pairs(g2_planets) do
        map.planets[p.n] = copy_planet(p) 
        
        local planet1 = map.planets[p.n]
        -- array containing precomputed distances from planet1 to every other planet
        planet1.dist = {}
        for _j, planet2 in pairs(g2_planets) do
            planet1.dist[planet2.n] = g2.distance(p, planet2)
        end
    end
    
    for _i, p in pairs(map.planets) do
        p.busy_until = 0
        p.time_to_capture = 0
    end
    
    return map
end

function bot_vacuumbot_calculate_closest_planets(user)
    local bot = BOT_VACUUMBOT[user.n]
    local planets = bot.map.planets
    -- precompute closest planet ids for each planet (list of planets closest to each planet, in increasing distance)
    for _i, p in pairs(planets) do
        local planet1 = planets[p.n]
        planet1.neighbors = {}
        for _j, planet2 in pairs(planets) do
            if _i ~= _j then
                table.insert(planet1.neighbors, planet2.n)
            end
        end
        table.sort(planet1.neighbors, 
            function(n1,n2) 
                -- taking planet radii into account 
                if (planet1.dist[n1] - planets[n1].planet_r) < 
                    (planet1.dist[n2] - planets[n2].planet_r) then 
                    return true 
                end 
            end
        )
    end
end

function bot_vacuumbot_calculate_estimated_time_to_capture(user)
    local bot = BOT_VACUUMBOT[user.n]
    local planets = bot.map.planets
    local planets_to_check = {}
    for _i,p in pairs(planets) do
        p.est_ships_value = est_ships_value(user, p)
        if g2.item(p.owner_n).user_neutral then
            table.insert(planets_to_check, p.n)
        end
    end
    table.sort(planets_to_check, function(p1_n,p2_n) 
        local p1 = planets[p1_n]
        local p2 = planets[p2_n]
        if (prod_to_ships(p1.ships_production) * bot.horizon - p1.est_ships_value) / (p1.est_ships_value + 1) 
            > (prod_to_ships(p2.ships_production) * bot.horizon - p2.est_ships_value) / (p2.est_ships_value + 1)  then 
            return true 
        end 
    end)
    for _i, p in pairs(planets) do
        if g2.item(p.owner_n).user_neutral then
            p.time_to_capture = initial_time_to_capture(user, p)
            p.busy_until = p.time_to_capture
        end
    end
    for _i, p_n in pairs(planets_to_check) do
        local p = planets[p_n]
        if g2.item(p.owner_n).user_neutral then
            p.time_to_capture = estimated_time_to_capture(user, p)
        end
    end
    for _i, p in pairs(planets) do
        p.busy_until = p.time_to_capture
        p.est_ships_value = p.ships_value
    end
end

function bot_vacuumbot_update_incoming_fleets(user)
print("here")
    -- store incoming fleets per planet
    local bot = BOT_VACUUMBOT[user.n]
    print("here")
    bot.map.incoming_fleets = {}
    bot.map.fleets = {}
    
    local fleets = g2.search("fleet")
    
    -- fleet distances to target
    for _i, f in pairs(fleets) do
        local fleet = copy_fleet(f)
        local target_planet = g2.item(f.fleet_target)
        fleet.dist_to_target = g2.distance(f, target_planet) - target_planet.planet_r
        fleet.arrival_time = dist_to_time(fleet.dist_to_target)
        table.insert(bot.map.fleets, fleet)
    end
    
    local incoming_fleets = bot.map.incoming_fleets
    local planets = bot.map.planets
    for _i, planet in pairs(planets) do
        incoming_fleets[planet.n] = {}
    end
    
    local fleets = bot.map.fleets
    for _i, fleet in pairs(fleets) do
        table.insert(incoming_fleets[fleet.fleet_target], fleet)
    end
    
    -- sort incoming fleets by distance
    for _i, planet in pairs(planets) do
        table.sort(incoming_fleets[planet.n], function(f1,f2)  if f1.arrival_time < f2.arrival_time then return true end end)
    end
    
    for _i, planet in pairs(planets) do
        planet.total_incoming_fleets = 0
        local incoming_fleets = incoming_fleets[planet.n]
        for _j, fleet in pairs(incoming_fleets) do
            if planet.owner_n == fleet.owner_n then
                planet.total_incoming_fleets = planet.total_incoming_fleets + fleet.fleet_ships
            else
                planet.total_incoming_fleets = planet.total_incoming_fleets - fleet.fleet_ships
            end
        end
    end
    
    
end

-- return a table containing the shortest possible path from each planet to each other planet, 
-- possibly tunneling through the first planet's user's other planets
-- tunneling subtracts the diameter of all planets along the tunneling path
function bot_vacuumbot_compute_tunnels(user) 
    local bot = BOT_VACUUMBOT[user.n]
    for _i,source in pairs(bot.map.planets) do
        --if not g2.item(source.owner_n).user_neutral then -- DON'T COMPUTE TUNNELS STARTING AT NEUTRAL PLANETS.... TEMPORARY
            source.tunnel = {}
            source.tunnel_dist = {}
            for _j,dest in pairs(bot.map.planets) do
                source.tunnel[dest.n] = _bot_vacuumbot_compute_tunnel(user, source, dest)
                source.tunnel_dist[dest.n] = _bot_vacuumbot_compute_tunnel_dist(source, dest)
            end
        --end
    end
end

-- private function... compute the shortest tunnel between planet1 and planet2
-- return a table of all planets involved in the tunnel not including source
function _bot_vacuumbot_compute_tunnel(user, source, dest)
    local bot = BOT_VACUUMBOT[user.n]
    -- search for potential planets to tunnel through in increasing distance from the source
    for _i,m in pairs(source.neighbors) do
        if m == dest.n then break end -- only check planets BETWEEN source and dest
        local middle = bot.map.planets[m]
        if source.owner_n == middle.owner_n or middle.time_to_capture < bot.horizon then
            -- is tunneling faster?
            if source.dist[m] + middle.dist[dest.n] - 2*middle.planet_r < source.dist[dest.n] then
               local tunnel1 = _bot_vacuumbot_compute_tunnel(user, source, middle)
               local tunnel2 = _bot_vacuumbot_compute_tunnel(user, middle, dest)
               return combine_tables(tunnel1, tunnel2)
            elseif source.dist[middle.n] > source.dist[dest.n] then
                break
            end 
        end
    end
    return {dest}
end

-- private function... compute length of the shortest tunnel between planet1 and planet2
function _bot_vacuumbot_compute_tunnel_dist(source, dest)
    local tunnel = source.tunnel[dest.n]
    local dist = 0
    local prev = source
    for i,next in ipairs(tunnel) do
        dist = dist + prev.dist[next.n] - prev.planet_r - next.planet_r
        prev = next
    end
    return dist
end

-- return a reference to the neutral user.  throw error if no neutral user found.
function bot_vacuumbot_get_user_neutral()
    local users = g2.search("user")
    for _i,user in pairs(users) do
        if user.user_neutral then return user end
    end
    error("No neutral user found")
end