-- Return the number of ships "planet" will have "time" seconds from now
function futureShips(planet, time)
    return planet.ships + produced(planet, time)
end

-- return the number of ships produced by planet after a time
function calcShipsProduced(planet, time)
    if planet.neutral then return 0 end
    return calcShipsProducedNonNeutral(planet, time)
end

function calcShipsProducedNonNeutral(planet, time)
    return prodToShips(planet.production) * time
end

-- convert distance to time (assumes constant, default ship movement speed)
function distToTravelTime(dist)
    return dist / 40
end

-- convert time to distance (assumes constant, default ship movement speed)
function travelTimeToDist(time)
    return time * 40
end

-- convert planet production to ships per second
function prodToShipsPerSec(prod)
    return prod / 50
end

-- convert ships per second to planet production
function shipsPerSecToProd(ships)
    return ships * 50
end

-- if planet "to" is attacked from planet "from" and captured,
-- how many net ships will it produce before "horizon" seconds?
-- return negative planet cost if planet farther than "horizon"
function estimateReturnOnNeutral(from, to, horizon)
    local travelTime = distToTravelTime(realDistance(from, to))
    local productionTime = math.max(0, horizon - travelTime)
    return producedNonNeutral(to, productionTime) - to.ships
end

-- distance subtracting planet radii if item1 or item2 are planets
function realDistance(item1, item2)
    local dist = distance(item1, item2)
    if item1.is_planet then
        dist = dist - item1.r
    end
    if item2.is_planet then
        dist = dist - item2.r
    end
    return math.max(0, dist)
end
