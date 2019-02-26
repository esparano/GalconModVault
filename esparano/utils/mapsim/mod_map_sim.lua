require("mod_map_builder")

-- TODO: break this up into a utils class
--///////////////////////////////////////////////////////////
local function dist(a, b)
    return math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))
end

local function timeToDist(time)
    return time * 40
end

local function prodToShips(prod)
    return prod / 50
end

local function angle(from, to)
    return math.atan2(to.y - from.y, to.x - from.x)
end

local function getVectorComponents(angle, dist)
    return dist * math.cos(angle), dist * math.sin(angle)
end

-- Return the number of ships "planet" will have "time" seconds from now
local function futureShips(planet, time)
    if planet.neutral then
        return planet.ships
    end
    return planet.ships + prodToShips(planet.production) * time
end
--///////////////////////////////////////////////////////////

-- TODO: validity assertions
function _module_init()
    local MapSim = {}

    local DEFAULT_TIMESTEP = 0.25
    local NEW_FLEET_N = 10000

    function MapSim.send(map, from, to, perc)
        -- TODO: min 1 ship, rounding? etc.
        local numToSend = math.min(from.ships * perc / 100, from.ships)
        -- TODO: lots of asserts to make sure all this is valid
        from.ships = math.max(from.ships - numToSend, 0)

        -- TODO: fleet radius estimation
        local fromOwner = map._items[from.owner]
        local xSpawnOffset, ySpawnOffset = getVectorComponents(angle(from, to), from.r)
        local createdFleet =
            MapBuilder.makeFleet(
            NEW_FLEET_N,
            NEW_FLEET_N,
            from.x + xSpawnOffset,
            from.y + ySpawnOffset,
            5,
            numToSend,
            fromOwner,
            to
        )
        -- TODO: make sure this doesn't overwrite an object
        map._items[createdFleet.n] = createdFleet
        NEW_FLEET_N = NEW_FLEET_N + 1

        -- TODO: optimize this?
        map:_resetCaches()

        return createdFleet
    end

    function MapSim.redirect(map, from, to)
        from.target = to.n
        -- not necessary at the moment but might be some day?
        map:_resetCaches()
    end

    -- TODO: gradual fleet landing
    -- land the fleet, even if it's far away
    function MapSim.land(map, fleet)
        local target = map._items[fleet.target]

        -- update ships as fleet lands on planet
        if fleet.owner == target.owner then
            target.ships = target.ships + fleet.ships
        else
            local diff = target.ships - fleet.ships
            if diff < 0 then
                -- change ownership
                target.ships = -diff
                target.owner = fleet.owner
                target.team = fleet.team
                target.neutral = false
            else
                target.ships = diff
            end
        end

        map._items[fleet.n] = nil

        -- TODO: optimize this?
        map:_resetCaches()
    end

    function MapSim.simulate(map, timestep)
        if timestep == nil then
            timestep = DEFAULT_TIMESTEP
        end
        if timestep == 0 then
            return
        end

        -- first, add production
        local planets = map:getPlanetList()
        for n, p in pairs(planets) do
            p.ships = futureShips(p, timestep)
        end

        -- second, move fleets towards goal.
        -- TODO: It's possible to figure out WHEN the fleet actually lands, then
        -- adjust production and capturing more accurately. But it's irrelevant
        -- for small enough timestep
        local fleets = map:getFleetList()
        local fleetUpdateDist = timeToDist(timestep)
        for n, f in pairs(fleets) do
            local target = map._items[f.target]
            local fDist = dist(f, target)
            -- TODO: add 1 ship radius?
            if fDist - fleetUpdateDist < target.r then
                MapSim.land(map, f)
            else
                local xDelta, yDelta = getVectorComponents(angle(f, target), fleetUpdateDist)
                f.x = f.x + xDelta
                f.y = f.y + yDelta
            end
        end
        -- TODO: fleet radius and fleets getting stuck on neutrals
        -- TODO: planets settle, fleets settle

        -- TODO: optimize this?
        map:_resetCaches()
    end

    return MapSim
end
MapSim = _module_init()
_module_init = nil
