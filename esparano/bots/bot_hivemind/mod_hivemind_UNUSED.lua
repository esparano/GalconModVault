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

-- NOTE: This does not consider how many ships the user has or whether the user has enough ships to capture all high-RoI neutrals simultaneously.
function identifyHighestRoiNeutral(map, mapTunnels, user)
    local notTunnelablePlanets = common_utils.filter(map:getNeutralPlanetList(), function (p) return not mapTunnels:isTunnelable(p.n) end)
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

    -- make sure positive-roi neutrals are set to tunnelable. Process positive-roi neutrals one at a time, alternating between enemy and friendly user, 
    -- picking the highest-roi for each user first, because either user being able to tunnel through a planet will affect the captures of other planets
    while true do
        local bestEnemyNeutral = identifyHighestRoiNeutral(map, mapTunnels, enemyUser)
        local bestFriendlyNeutral = identifyHighestRoiNeutral(map, mapTunnels, user)
        if not bestEnemyNeutral and not bestFriendlyNeutral then break end 
    end

    -- now that tunnels have been figured out properly, return positive ROI data for both player and enemy
    return getPositiveRoiNeutralData(map, mapTunnels, user, map:getNeutralPlanetList())
end
