-- TODO: documentation
function _game_utils_init()
    local game_utils = {}

    function game_utils.toId(o)
        if type(o) == "table" then return o.n end
        return o
    end
    
    -- Return the number of ships "planet" will have "time" seconds from now
    function game_utils.futureShips(planet, time)
        return planet.ships + game_utils.produced(planet, time)
    end

    -- return the number of ships produced by planet after a time
    function game_utils.calcShipsProduced(planet, time)
        if planet.neutral then return 0 end
        return game_utils.calcShipsProducedNonNeutral(planet, time)
    end

    function game_utils.calcShipsProducedNonNeutral(planet, time)
        return game_utils.prodToShipsPerSec(planet.production) * time
    end

    -- convert distance to time (assumes constant, default ship movement speed)
    function game_utils.distToTravelTime(dist)
        return dist / 40
    end

    -- convert time to distance (assumes constant, default ship movement speed)
    function game_utils.travelTimeToDist(time)
        return time * 40
    end

    -- convert planet production to ships per second
    function game_utils.prodToShipsPerSec(prod)
        return prod / 50
    end

    -- convert ships per second to planet production
    function game_utils.shipsPerSecToProd(ships)
        return ships * 50
    end

    -- what percent the planet should send at to send at least this number of ships
    -- increments of 5%, max 100%.
    -- TODO: if number of ships sent is < 1, no ships will be sent!
    function game_utils.percentToUse(planet, ships)
        local available = math.floor(planet.ships)
        if available == 0 then return 100 end
        local pct = math.ceil((ships + 1) / available * 100 / 5) * 5
        return common_utils.clamp(pct, 5, 100)
    end

    -- if planet "to" is attacked from planet "from" and captured,
    -- how many net ships will it produce before "horizon" seconds?
    -- return negative planet cost if planet farther than "horizon"
    function game_utils.estimateReturnOnNeutral(from, to, horizon)
        local travelTime = game_utils.distToTravelTime(game_utils.realDistance(from, to))
        local productionTime = math.max(0, horizon - travelTime)
        return game_utils.calcShipsProducedNonNeutral(to, productionTime) - to.ships
    end

    function game_utils.distance(a, b)
        local dx, dy = b.x - a.x, b.y - a.y 
        return math.sqrt(dx*dx + dy*dy)
    end

    -- from curve fitting actual data
    -- used https://mycurvefit.com/
    function game_utils.realShipsToPhysicalShips(x)
        return 58 * x / (48 + x)
    end

    -- from curve fitting actual data
    -- TODO: add time taken per move converted to distance and or discretize into mod(move time)
    -- actual distance traveled by the fleet before capturing / landing (avg time to capture OR avg time to land first ship)
    function game_utils.realDistance(source, target, numShipsSent, costOverride)
        -- TODO: make sure this cost stuff and override works.
        local cost = target.ships
        -- TODO: only works in 1v1... might not work for predicting tunnels where current owner is different, etc.
        if not target.is_neutral then 
            cost = 0
        end
        cost = costOverride or cost

        local costPhysicalShips =  game_utils.realShipsToPhysicalShips(cost)
        local fleetPhysicalShips =  game_utils.realShipsToPhysicalShips(numShipsSent)

        -- second-order 3d polynomial fit to real costPhysicalShips and fleetPhysicalShips data
        -- this adjusts the predicted distance based on fleets spawning outside planets and taking a while to capture when cost > 0
        local x, y = costPhysicalShips, fleetPhysicalShips
        -- Really cool - The existing calculation of subtracting planet_r and ship_radius (twice) is so accurate that
        -- no distAdjustment is needed at all when cost = 0 and the fleet is small (1 physical ship)
        local c = 0 
        local a = 4.12
        local b = -1.97
        local ab = -0.0946
        local aa = 0.0351
        local bb = 0.0258
        local distAdjustment = c + a * x + b * y + ab * x * y + aa * x^2 + bb * y^2

        local dist = game_utils.distance(source, target) + distAdjustment

        local ship_radius = 6
        -- TODO: should it be subtracted if a fleet too?
        if source.has_planet then
            -- TODO: subtract additional amount based on size of sending planet?
            dist = dist - source.r - ship_radius
        end
        dist = dist - target.r - ship_radius

        return math.max(0, dist)
    end

    return game_utils
end
game_utils = _game_utils_init()
_game_utils_init = nil
