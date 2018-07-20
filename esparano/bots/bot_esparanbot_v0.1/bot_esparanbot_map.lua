-- get a representation of the map
-- can only afford one of these per tick before starting to lag
function bot_esparanbot_get_map()
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
    
    -- precompute closest planet ids for each planet (list of planets closest to each planet, in increasing distance)
    for _i, p in pairs(map.planets) do
        local planet1 = map.planets[p.n]
        planet1.neighbors = {}
        for _j, planet2 in pairs(map.planets) do
            table.insert(planet1.neighbors, planet2.n)
        end
        table.sort(planet1.neighbors, 
            function(n1,n2) 
                if n1 ~= nil and n2 ~= nil then 
                    -- taking planet radii into account 
                    if (planet1.dist[n1] - map.planets[n1].planet_r) < 
                        (planet1.dist[n2] - map.planets[n2].planet_r) then 
                        return true 
                    end 
                end 
            end
        )
    end
    
    return map
end

-- return a table containing the shortest possible path from each planet to each other planet, 
-- possibly tunneling through the first planet's user's other planets
-- tunneling subtracts the diameter of all planets along the tunneling path
function bot_esparanbot_compute_tunnels(user) 
    local bot = BOT_ESPARANBOT[user.n]
    for _i,source in pairs(bot.map.planets) do
        if not g2.item(source.owner_n).user_neutral then -- DON'T COMPUTE TUNNELS STARTING AT NEUTRAL PLANETS.... TEMPORARY
            source.tunnel = {}
            source.tunnel_dist = {}
            for _j,dest in pairs(bot.map.planets) do
                if not g2.item(source.owner_n).user_neutral then -- DON'T COMPUTE TUNNELS ENDING AT NEUTRAL PLANETS.... TEMPORARY
                    source.tunnel[dest.n] = _bot_esparanbot_compute_tunnel(user, source, dest)
                    source.tunnel_dist[dest.n] = _bot_esparanbot_compute_tunnel_dist(source, dest)
                end
            end
        end
    end
end

-- private function... compute the shortest tunnel between planet1 and planet2
-- return a table of all planets involved in the tunnel not including source
function _bot_esparanbot_compute_tunnel(user, source, dest)
    local bot = BOT_ESPARANBOT[user.n]
    -- search for potential planets to tunnel through in increasing distance from the source
    for _i,m in pairs(source.neighbors) do
        local middle = bot.map.planets[m]
        -- only tunnel through friendly planets ????????????????????????????????????????????????????????????????????????????????????????????????????????
        if source.owner_n == middle.owner_n then
            if should_tunnel(source, middle, dest) then
               local tunnel1 = _bot_esparanbot_compute_tunnel(user, source, middle)
               local tunnel2 = _bot_esparanbot_compute_tunnel(user, middle, dest)
               return combine_tables(tunnel1, tunnel2)
            elseif source.dist[middle.n] > source.dist[dest.n] then
                break
            end 
        end
    end
    return {dest}
end

-- private function... compute length of the shortest tunnel between planet1 and planet2
function _bot_esparanbot_compute_tunnel_dist(source, dest)
    local tunnel = source.tunnel[dest.n]
    local dist = 0
    local prev = source
    for i,next in ipairs(tunnel) do
        dist = dist + prev.dist[next.n] - prev.planet_r - next.planet_r
        prev = next
    end
    return dist
end

-- return a state with s.planets and s.fleets at the current time
function bot_esparanbot_get_start_state()
    local s = {}
    s.planets = g2.search("planet")
    s.fleets = g2.search("fleet")
    
    -- store incoming fleets per planet
    s.incoming_fleets = {}
    for _i, planet in pairs(s.planets) do
        s.incoming_fleets[planet.n] = {}
    end
    for _i, fleet in pairs(s.fleets) do
        table.insert(s.incoming_fleets[fleet.fleet_target], fleet)
    end
    -- sort incoming fleets by distance
    for _i, planet in pairs(s.planets) do
        table.sort(s.incoming_fleets[planet.n], function(f1,f2) if f1 ~= nil and f2 ~= nil then if g2.distance(planet, f1) < g2.distance(planet, f2) then return true end end end)
        -- TEST FLEET SORTING CODE
        --[[
        for _i, fleet in pairs(s.incoming_fleets[planet.n]) do
            print(g2.distance(planet, fleet))
        end
        --]]
    end
    
    return copy_state(s)
end

-- return a reference to the neutral user.  throw error if no neutral user found.
function bot_esparanbot_get_user_neutral()
    local users = g2.search("user")
    for _i,user in pairs(users) do
        if user.user_neutral then return user end
    end
    error("No neutral user found")
end