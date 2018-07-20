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

-- return a deep copy of the object
function deep_copy(obj)
    local copy = {}
    if type(obj) ~= 'table' then return obj end
    for k,v in pairs(obj) do
        copy[k] = deep_copy(v)
    end
    return copy
end

-- get the distance between two objects with a .position_x and .position_y
function distance(obj1, obj2)
    local dx = obj2.position_x - obj1.position_x 
    local dy = obj2.position_y - obj1.position_y
    return math.sqrt(dx*dx + dy*dy)
end

-- return the longest distance, in seconds, between any planets in the map
function get_horizon(planets)
    local horizon = 0
    for _i, planet1 in pairs(planets) do
        for _j, planet2 in pairs(planets) do
            local dist = distance(planet1, planet2)
            if dist > horizon then horizon = dist end
        end
    end
    return dist_to_time(horizon)
end



