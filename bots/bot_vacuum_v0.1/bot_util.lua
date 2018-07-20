-- Return the number of ships "planet" will have "time" seconds from now
function future_ships(planet, time)
    local ships = planet.ships_value
    if planet.ships_production_enabled then
        ships = ships + prod_to_ships(planet.ships_production) * time
    end
    return ships
end

-- convert distance to time (assumes constant ship movement speed)
function dist_to_time(dist)
	return dist / 40
end

-- convert time to distance (assumes constant ship movement speed)
function time_to_dist(time)
	return time * 40
end

-- convert planet production to ships per second 
function prod_to_ships(prod)
    return prod / 50
end

-- convert ships per second to planet production
function ships_to_prod(ships)
    return ships * 50
end

-- try to send an amount of ships, return the amount sent
function send_exact(user, from, to, ships)
    if from.ships_value < ships then
        from:fleet_send(100, to)
        return from.ships_value
    end
    local perc = ships / from.ships_value * 100
    if perc > 100 then perc = 100 end
    from:fleet_send(perc, to)
    return ships
end

-- create a deep copy of the object, return the copy
-- doesn't seem to work... at least not with planets or other game items
function deep_copy(obj)
    local copy = {}
    if type(obj) ~= 'table' then return obj end
    for k,v in pairs(obj) do
        copy[k] = deep_copy(v)
    end
    return copy
end

-- return a copy of the state s
function copy_state(s) 
    local copy = {}
    
    copy.planets = {}
    for _i,p in pairs(s.planets) do
        copy.planets[p.n] = copy_planet(p)
    end
    
    copy.fleets = {}
    for _i,f in pairs(s.fleets) do
        copy.fleets[f.n] = copy_fleet(f)
    end
    
    copy.incoming_fleets = {}
    for _i, planet in pairs(copy.planets) do
        copy.incoming_fleets[planet.n] = {}
        for _j, fleet in pairs(s.incoming_fleets[planet.n]) do
            copy.incoming_fleets[planet.n][_j] = copy.fleets[fleet.n]
        end
    end
    
    return copy
end

-- return a table with the same properties as the planet
function copy_planet(planet)
    local copy = {}
    copy.n = planet.n
    copy.owner_n = planet.owner_n
    copy.position_x = planet.position_x
    copy.position_y = planet.position_y
    copy.planet_r = planet.planet_r
    copy.ships_production = planet.ships_production
    copy.ships_production_enabled = planet.ships_production_enabled
    copy.ships_value = planet.ships_value
    -- insert other properties to copy...
    return copy
end

-- return a table with the same properties as the fleet
function copy_fleet(fleet)
    local copy = {}
    copy.n = fleet.n
    copy.owner_n = fleet.owner_n
    copy.fleet_target = fleet.fleet_target
    copy.fleet_ships = fleet.fleet_ships
    copy.position_x = fleet.position_x
    copy.position_y = fleet.position_y
    -- insert other properties to copy...
    return copy
end

-- find the best item described by "query" using a evaluation function "eval"
function find(query,eval)
    local res = g2.search(query)
    local best = nil; local value = nil
    for _i,item in pairs(res) do
        _value = eval(item)
        if _value ~= nil and (value == nil or _value > value) then
            best = item
            value = _value
        end
    end
    return best
end

-- append all of the contents of second_table to first_table.  return the merged table
function combine_tables(first_table, second_table)
    for k,v in pairs(second_table) do
        table.insert(first_table, v)
    end
    return first_table
end

-- should the planet (or fleet) tunnel through middle to get to dest?
-- return true if yes and false if no
function should_tunnel(source, middle, dest)
    if (source.n == middle.n) then return false end
    if (middle.n == dest.n) then return false end
    if (source.n == dest.n) then return false end
     -- 2.3 instead of 2 to slightly encourage tunneling... even if inefficient
    local tunnel_distance = g2.distance(source, middle) + g2.distance(middle, dest) - 2.3*middle.planet_r
    local actual_distance = g2.distance(source, dest)
    if tunnel_distance < actual_distance then return true end
    return false
end

-- return the number of ships belonging to user in state s
function sum_ships(s, user)
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
function sum_enemy_ships(s, user)
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