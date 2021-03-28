require("mod_map_tunnels")
require("mod_map_info")
require("mod_common_utils")
require("mod_set")
-- require("mod_profiler")

function firstTurnSetup(params)
    print("first turn setup")
end

-- TODO: in order to solve minimax aspect of "mid" maps, calculate whether capturing a planet allows enemy to deny(gain) a lot of other production.
-- Perhaps calculate "prod secured by maximum greediness" for both players, and if adding any 1 planet to expansion plan
-- causes the enemy's prod secured to be much higher, don't expand to that planet.

-- get actions, merge actions if possible, then evaluate and pick actions?

-- TODO: in addition to safely capturable planets, we can possibly take even more planets if, by examining
-- no-redirect planet futures in a simulated all-out attack, the planet does not change hands.

function isPlanetSafeFromAllOutAttack(map, mapTunnels, user)

end

function getHome(map, mapTunnels, user)
    return common_utils.find(map:getPlanetList(user.n), function(p) return p.production end)
end

function getHomesDistance(map, mapTunnels)
    local users = map:getUserList(false)
    local h1 = getHome(map, mapTunnels, users[1])
    local h2 = getHome(map, mapTunnels, users[2])
    return mapTunnels:getSimplifiedTunnelDist(h1.n, h2.n)
end

function getPositiveRoiNeutralData(map, mapTunnels, user, neutrals)
    local home = getHome(map, mapTunnels, user)
    local enemyHome = getHome(map, mapTunnels, map:getEnemyUser(user))

    local neutralROIs = {}
    for _, p in pairs(neutrals) do 
        local distDifference = mapTunnels:getSimplifiedTunnelDist(enemyHome.n, p.n) - mapTunnels:getSimplifiedTunnelDist(home.n, p.n)
        local prodTime = game_utils.distToTravelTime(distDifference)

        -- planet should be closer to player than enemy
        if prodTime > 0 then
            local shipReturns = game_utils.calcShipsProducedNonNeutral(p, prodTime) - p.ships
            if shipReturns > 0 then 
                local shipCost = math.max(1, p.ships) -- planets always cost at least 1 ship, avoids divide by zero errors
                local roiData = {
                    roi = shipReturns / shipCost,
                    shipReturns = shipReturns,
                    target = p
                }
                table.insert(neutralROIs, roiData)
            end
        end
    end
    table.sort(neutralROIs, function (a, b) return a.roi > b.roi end)
    return neutralROIs
end

function getCapturablePlanetsForMaximumGreediness(map, mapTunnels, user)

end

-- TODO: this should copy mapTunnels instead of modifying permanently?
-- TODO: limit to number of ships that player actually has? (Repeat while total estimated return on investment before enemy arrival is > 0?)
function identifyHighestRoiNeutral(map, mapTunnels, user)
    local notTunnelablePlanets = common_utils.findAll(map:getNeutralPlanetList(), function (p) return not mapTunnels:isTunnelable(p.n) end)
    local positiveRoiNeutralData = getPositiveRoiNeutralData(map, mapTunnels, user, notTunnelablePlanets)
    if #positiveRoiNeutralData > 0 then 
        local bestPositiveRoiNeutral = positiveRoiNeutralData[1].target
        mapTunnels:setTunnelable(bestPositiveRoiNeutral)
        return bestPositiveRoiNeutral
    end
end

-- Repeat while total estimated return on investment before enemy arrival is > 0
--      sort by estimated return on investment before enemy arrival
--      get best return planet, and if total RoI is > 0 with this planet, 
--          add it to tunnelable planets (maybe add enemy's too? hmm)
--          add planet to list of capturable planets.
function getNeutralsDataWithPositiveRoi(map, mapTunnels, user)
    local enemyUser = map:getEnemyUser(user)

    local notTunnelablePlanets = common_utils.findAll(map:getNeutralPlanetList(), function (p) return not mapTunnels:isTunnelable(p.n) end)
    local notTunnelablePlanetIdSet = Set.new(notTunnelablePlanets)
    -- make sure positive-roi neutrals are set to tunnelable. Process positive-roi neutrals one at a time, alternating between enemy and friendly user, 
    -- picking the highest-roi for each user first, because either user being able to tunnel through a planet will affect the captures of other planets
    while true do
        local bestEnemyNeutral = identifyHighestRoiNeutral(map, mapTunnels, enemyUser)
        local bestFriendlyNeutral = identifyHighestRoiNeutral(map, mapTunnels, user)
        if not bestEnemyNeutral and not bestFriendlyNeutral then break end 
    end

    -- now that tunnels have been figured out properly, return positive ROI data for both player and enemy
    return getPositiveRoiNeutralData(map, mapTunnels, user, map:getNeutralPlanetList()), 
        getPositiveRoiNeutralData(map, mapTunnels, enemyUser,map:getNeutralPlanetList())
end

-- a "front" planet is any "owned" (or planned-to-be-captured) planet that does not need to tunnel to attack its closest enemy planet
-- will return empty list if there are no enemy planets
function getFrontPlanets(map, mapTunnels, user, friendlyPlannedCapturesSet, enemyPlannedCapturesSet)
    local friendlyPlanets = common_utils.findAll(map:getPlanetList(), 
        function (p) return p.owner == user.n or friendlyPlannedCapturesSet:contains(p.n) end
    )
    local enemyUser = map:getEnemyUser(user.n)
    local enemyPlanets = common_utils.findAll(map:getPlanetList(), 
        function (p) return p.owner == enemyUser.n or enemyPlannedCapturesSet:contains(p.n) end
    )
    return common_utils.findAll(friendlyPlanets, 
        function (source)
            local closestEnemyPlanet = common_utils.find(enemyPlanets,
                function (target) 
                    return - mapTunnels:getSimplifiedTunnelDist(source.n, target.n) 
                end
            )
            return closestEnemyPlanet ~= nil and mapTunnels:getTunnelAlias(source.n, closestEnemyPlanet.n).n == closestEnemyPlanet.n
        end
    )
end

function testFullFrontalAssault(map, mapTunnels, user)
    -- for each front planet we own, enemy should take closest planets to each front planet and full-attack. 
    -- Method 1: fast forward to "horizon", maybe? then sum ship surpluses or deficits across owned front planets. This assumes ships can be redistributed to help with defending fronts. 
end

function testFullAttack(map, mapTunnels, user)

end

function bot_greed(params, sb_stats)
    ITEMS = params.items
    local botUser = ITEMS[params.user]
    OPTS = params.options or {
        -- TODO: fill these out
        percent = 100,
        debug = {
            drawFriendlyFrontPlanets = false,
            drawEnemyFrontPlanets = false,
            drawFriendlyExpansionPlan = false,
            drawEnemyExpansionPlan = false,
            drawFriendlyTunnels = false,
            drawEnemyTunnels = false,
        }
    }
    MEM = params.memory
    DEBUG = params.debug or {
        debugHighlightPlanets = common_utils.pass,
        debugDrawPaths = common_utils.pass
    }

    MEM.t = (MEM.t or 0) + 1
    if (MEM.t % 4) ~= 1 then
        -- return
    end -- do an action once per second

    local map = Map.new(ITEMS)
    local users = map:getUserList(false)
    if #users ~= 2 then 
        print("ERROR: Match is either FFA or there is no enemy. Skipping turn. #users = " .. #users)
        return
    end
    local enemyUser = map:getEnemyUser(botUser.n)

    MEM.mapTunnelsData = MEM.mapTunnelsData or {}
    mapTunnels = MapTunnels.new(ITEMS, MEM.mapTunnelsData)

    if not MEM.initialized then
        MEM.initialized = true
        firstTurnSetup(params)
    end

    local capturePlan = {
        friendlyPlannedCapturesSet = Set.new(),
        enemyPlannedCapturesSet = Set.new()
    }

    local friendlyPositiveRoiNeutralData, enemyPositiveRoiNeutralData = getNeutralsDataWithPositiveRoi(map, mapTunnels, botUser)
    capturePlan.friendlyPlannedCapturesSet:addAll(common_utils.map(friendlyPositiveRoiNeutralData, function (p) return p.target.n end))
    capturePlan.enemyPlannedCapturesSet:addAll(common_utils.map(enemyPositiveRoiNeutralData, function (p) return p.target.n end))

    -- get expansion plan by taking positiveRoiNeutrals plus good neutrals for which fullFrontalAssault(expansionPlan) test passes, and add to expansion plan.
    -- Take full expansion plan and figure out how many ships to send in each direction... maybe by looking at existing fleet paths and nearby ships, etc... 

    local botFrontPlanets = getFrontPlanets(map, mapTunnels, botUser, capturePlan.friendlyPlannedCapturesSet, capturePlan.enemyPlannedCapturesSet)
    local enemyFrontPlanets = getFrontPlanets(map, mapTunnels, enemyUser, capturePlan.enemyPlannedCapturesSet, capturePlan.friendlyPlannedCapturesSet)

    -- DEBUG DRAWING
    if OPTS.debug.drawFriendlyFrontPlanets then 
        DEBUG.debugHighlightPlanets(botUser, botFrontPlanets, botUser, 7)
    end
    if OPTS.debug.drawEnemyFrontPlanets then 
        DEBUG.debugHighlightPlanets(botUser, enemyFrontPlanets, enemyUser, 7)
    end
    if OPTS.debug.drawFriendlyExpansionPlan then 
        debugDrawExpansionPlan(botUser, capturePlan.friendlyPlannedCapturesSet, botUser)
    end
    if OPTS.debug.drawEnemyExpansionPlan then 
        debugDrawExpansionPlan(botUser, capturePlan.enemyPlannedCapturesSet, enemyUser)
    end
    if OPTS.debug.drawFriendlyTunnels then 
        debugDrawTunnels(botUser, map, mapTunnels, botUser, botFrontPlanets)
    end
    if OPTS.debug.drawEnemyTunnels then 
        debugDrawTunnels(botUser, map, mapTunnels, enemyUser, enemyFrontPlanets)
    end

    local planets = map:getPlanetList()
    local from = common_utils.find(planets,
        function(o)
            if o.owner == botUser.n then
                return o.ships
            end
        end
    )
    if not from then
        return
    end

    local to = common_utils.find(planets,
        function(o)
            if o.owner ~= botUser.n and not o.neutral then
                return o.production - o.ships - 0.2 * game_utils.distance(from, o)
            end
        end
    )
    if not to then
        return
    end

    -- check if we've run out of resources
    local ticks, alloc = sb_stats()
    print("ticks, alloc = " .. ticks .. " , " .. alloc)

    local tunnelAlias = mapTunnels:getTunnelAlias(from.n, to.n)
    -- by using a table for from, you can send from multiple planets and fleets
    return {percent = OPTS.percent, from = {from.n}, to = tunnelAlias.n}
end

function debugDrawExpansionPlan(botUser, plannedCapturesSet, owner)
    local plannedCaptures = {}
    for n in pairs(plannedCapturesSet:getValues()) do 
        table.insert(plannedCaptures, ITEMS[n])
    end
    DEBUG.debugHighlightPlanets(botUser, plannedCaptures, owner)
end

function debugDrawTunnels(botUser, map, mapTunnels, owner, targets)
    local tunnelPairs = {}
    for i,source in ipairs(map:getPlanetList(owner)) do 
        local closestTarget = getClosestTarget(mapTunnels, source, targets)
        if closestTarget ~= nil and source.n ~= closestTarget.n then
            local tunnelAlias = mapTunnels:getTunnelAlias(source.n, closestTarget.n)
            table.insert(tunnelPairs, {source = source, target = tunnelAlias})
        end
    end
    DEBUG.debugDrawPaths(botUser, tunnelPairs, owner)
end

function getClosestTarget(mapTunnels, source, targets)
    return common_utils.find(targets, function (target)
        return -mapTunnels:getSimplifiedTunnelDist(source.n, target.n) 
    end)
end
