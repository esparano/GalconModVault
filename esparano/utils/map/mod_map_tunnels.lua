require("mod_common_utils")
require("mod_game_utils")

function _module_init()
    local MapTunnels = {}

    local DEFAULT_TUNNEL_SHIPS_SENT = 10

    -- TODO: could modify to take into account bot movement speed, by adding something like ceil(dist_to_time(realDistance(source,target)) / actionRate) * actionRate
    local function estimatedRealDistance(source, target, numShipsSent, costOverride) 
        numShipsSent = numShipsSent or DEFAULT_TUNNEL_SHIPS_SENT
        costOverride = costOverride or 0
        return game_utils.realDistance(source, target, numShipsSent, costOverride)
    end 

    local function initPlanetInfo(items)
        local planetInfo = {}
        for _,item in pairs(items) do
            if item.is_planet then 
                planetInfo[item.n] = {
                    tunnelable = false,
                    n = item.n
                }
            end
        end
        return planetInfo
    end

    local function initPlanetDists(items, planetInfo)
        local dists = {}
        -- necessary to first initialize to avoid nil errors
        for sourceId,_ in pairs(planetInfo) do
            dists[sourceId] = {}
        end
        for sourceId,_ in pairs(planetInfo) do
            local source = items[sourceId]
            for targetId,_ in pairs(planetInfo) do
                if sourceId == targetId then 
                    dists[sourceId][targetId] = 0
                elseif sourceId < targetId then
                    local target = items[targetId]
                    dists[sourceId][targetId] = estimatedRealDistance(source, target)
                    dists[targetId][sourceId] = dists[sourceId][targetId]
                end
            end
        end
        return dists
    end

    local function initTunnelInfo(planetDists, congestionCorrections)
        local tunnelInfo = {}
        for sourceId,_ in pairs(planetDists) do
            tunnelInfo[sourceId] = {}
            for targetId,_ in pairs(planetDists) do
                local directCongestedDist = planetDists[sourceId][targetId] + congestionCorrections[sourceId][targetId] 
                tunnelInfo[sourceId][targetId] = {
                    aliasId = targetId,
                    directDist = directCongestedDist,
                    tunnelDist = directCongestedDist,
                }
            end
        end
        return tunnelInfo
    end

    -- the better tunneling through a planet WOULD have been compared to going around it,
    -- the more (to the second power, as an estimate) congestion the planet adds to paths going around it
    -- TODO: this is imperfect and could use some curve fitting and/or a slightly different approach to estimating congestion. This does a poor job at 
    -- estimating the compounding effects of multiple nearby planets, although it suffices for single congesting planets.
    local function tunnelingDiffToCongestionCorrection(c)
        return c * c / 120
    end

    -- return an effective distance increase in the direct path from sourceId to targetId due to congestion
    local function computeCongestionCorrection(sourceId, targetId, planetDists)
        local totalCorrection = 0
        for proxyId,_ in pairs(planetDists) do
            if proxyId ~= sourceId and proxyId ~= targetId then
                local tunnelDist = planetDists[sourceId][proxyId] + planetDists[proxyId][targetId]
                local diffFromTunneling = math.max(0, planetDists[sourceId][targetId] - tunnelDist)
                local correction = tunnelingDiffToCongestionCorrection(diffFromTunneling)
                totalCorrection = totalCorrection + correction
            end
        end
        return totalCorrection
    end

    local function initCongestionCorrections(planetDists)
        local corrections = {}
        -- necessary to first initialize to avoid nil errors
        for sourceId,_ in pairs(planetDists) do
            corrections[sourceId] = {}
        end
        for sourceId,_ in pairs(planetDists) do
            for targetId,_ in pairs(planetDists) do
                if sourceId == targetId then
                    corrections[sourceId][targetId] = 0
                elseif sourceId < targetId then 
                    corrections[sourceId][targetId] = computeCongestionCorrection(sourceId, targetId, planetDists)
                    corrections[targetId][sourceId] = corrections[sourceId][targetId]
                end
            end
        end
        return corrections
    end

    -- TODO: maybe instead, it's best to construct a grid and precompute congestionCorrections and tunnelDists for each grid bucket?
    -- per unit distance, how large a congestion correction would there be, roughly? probably a fraction between 0.1 to 0.2.
    local function getAvgCongestionCorrectionPerUnitDistance(planetDists, congestionCorrections)
        local sum = 0
        local sumDist = 0
        for sourceId,_ in pairs(planetDists) do
            for targetId,_ in pairs(planetDists) do
                sumDist = sumDist + planetDists[sourceId][targetId]
                sum = sum + congestionCorrections[sourceId][targetId]  
            end
        end
        return sum / sumDist
    end

    function MapTunnels.new(items, data)
        data = data or {}
        data.planetInfo = data.planetInfo or initPlanetInfo(items)
        data.planetDists = data.planetDists or initPlanetDists(items, data.planetInfo)
        data.congestionCorrections = data.congestionCorrections or initCongestionCorrections(data.planetDists)
        data.avgCongestionCorrectionPerDist = data.avgCongestionCorrectionPerDist or getAvgCongestionCorrectionPerUnitDistance(data.planetDists, data.congestionCorrections)
        data.tunnelInfo = data.tunnelInfo or initTunnelInfo(data.planetDists, data.congestionCorrections)

        local instance = {}
        for k, v in pairs(MapTunnels) do
            instance[k] = v
        end

        instance.data = data
        instance.items = items

        instance:updateTunnelablePlanets()

        return instance
    end

    function MapTunnels:updateTunnelablePlanets()
        for planetId, planetInfo in pairs(self.data.planetInfo) do
            local planet = self.items[planetId]
            if not planet.neutral then
                self:setTunnelable(planet)
            end
        end
    end

    function MapTunnels:setTunnelable(sourceId)
        sourceId = game_utils.toId(sourceId)
        if self.data.planetInfo[sourceId].tunnelable then
            return
        end

        self.data.planetInfo[sourceId].tunnelable = true
        self:_updateTunnels(sourceId)
    end

    -- updates all existing tunnels to consider the candidate as an alias
    -- This calculation is repeated until convergence because updating one tunnel may affect other tunnels that pass through the same planets
    -- Floyd-Warshall algorithm modified to process 1 alias at a time
    function MapTunnels:_updateTunnels(aliasCandidateId)
        for sourceId,_ in pairs(self.data.planetInfo) do
            local sourceToCandidateDist = self.data.tunnelInfo[sourceId][aliasCandidateId].tunnelDist
            for targetId,_ in pairs(self.data.planetInfo) do
                if sourceId < targetId then 
                    local throughCandidateDist = sourceToCandidateDist + self.data.tunnelInfo[aliasCandidateId][targetId].tunnelDist
                    local currentTunnelDist = self.data.tunnelInfo[sourceId][targetId].tunnelDist
                    -- avoid floating point errors leading to infinite loops.
                    if throughCandidateDist < currentTunnelDist - 0.00001 then 
                        self.data.tunnelInfo[sourceId][targetId].tunnelDist = throughCandidateDist
                        self.data.tunnelInfo[targetId][sourceId].tunnelDist = throughCandidateDist
                        self.data.tunnelInfo[sourceId][targetId].aliasId = self.data.tunnelInfo[sourceId][aliasCandidateId].aliasId 
                        self.data.tunnelInfo[targetId][sourceId].aliasId = self.data.tunnelInfo[targetId][aliasCandidateId].aliasId 
                    end
                end
            end
        end
    end

    function MapTunnels:getApproxFleetDirectDist(fleetId, targetId)
        fleetId = game_utils.toId(fleetId)
        local fleet = self.items[fleetId]

        targetId = targetId or fleet.target
        targetId = game_utils.toId(targetId)
        local target = self.items[targetId]

        -- Fleet's "realDistance" plus an approximation of congestion corrections for a direct flight to "target".
        return (1 + self.data.avgCongestionCorrectionPerDist) * estimatedRealDistance(fleet, target, fleet.ships, fleet.ships/2)
    end

    -- TODO: would be better to use grid-based precalculation approach rather than recalculating as needed.
    function MapTunnels:getApproxFleetTunnelDist(fleetId, targetId)
        fleetId = game_utils.toId(fleetId)
        targetId = game_utils.toId(targetId)
        -- Fleet's "realDistance" plus an approximation of congestion corrections for a direct flight to "target".
        local bestDist = self:getApproxFleetDirectDist(fleetId, targetId)
        
        -- test if it's better to land fleet nearby and then tunnel to target
        for aliasId,_ in pairs(self.data.planetInfo) do
            local alias = self.items[aliasId]
            if not alias.neutral then 
                local distToAlias = self:getApproxFleetDirectDist(fleetId, aliasId)
                local totalTunnelDist = distToAlias + self:getSimplifiedTunnelDist(aliasId, targetId)
                if totalTunnelDist < bestDist then 
                    bestDist = totalTunnelDist
                end
            end 
        end

        return bestDist
    end

    -- assuming DEFAULT_TUNNEL_SHIPS_SENT at a time are sent through empty (or friendly) planets
    function MapTunnels:getSimplifiedTunnelDist(sourceId, targetId)
        sourceId = game_utils.toId(sourceId)
        targetId = game_utils.toId(targetId)
        return self.data.tunnelInfo[sourceId][targetId].tunnelDist
    end

    function MapTunnels:getTunnelAlias(sourceId, targetId) 
        sourceId = game_utils.toId(sourceId)
        targetId = game_utils.toId(targetId)
        return self.items[self.data.tunnelInfo[sourceId][targetId].aliasId]
    end

    function MapTunnels:isTunnelable(planetId)
        planetId = game_utils.toId(planetId)
        return self.data.planetInfo[planetId].tunnelable 
    end

    -- a "front" planet is any "owned" (or planned-to-be-captured) planet that does not need to tunnel to attack its closest enemy planet
    -- will return empty list if there are no enemy planets
    function MapTunnels:getFrontPlanets(userId, friendlyPlannedCapturesSet, enemyPlannedCapturesSet)
        userId = game_utils.toId(userId)
        friendlyPlannedCapturesSet = friendlyPlannedCapturesSet or Set.new()
        enemyPlannedCapturesSet = enemyPlannedCapturesSet or Set.new()

        local friendlyPlanets = common_utils.filter(self.data.planetInfo, 
            function (info) 
                local p = self.items[info.n]
                return p.owner == userId or friendlyPlannedCapturesSet:contains(info.n) 
            end
        )
        local enemyPlanets = common_utils.filter(self.data.planetInfo,
            function (info)
                local p = self.items[info.n]
                return (p.owner ~= userId and not p.neutral) or enemyPlannedCapturesSet:contains(info.n) 
            end
        )
        local resultInfos = common_utils.filter(friendlyPlanets,
            function (sourceInfo)
                for i,enemyInfo in ipairs(enemyPlanets) do
                    local alias = self:getTunnelAlias(sourceInfo, enemyInfo)
                    -- print("from " .. self.items[sourceInfo.n].ships .. " to " .. self.items[enemyInfo.n].ships .. " alias " .. alias.ships)
                    if alias.owner ~= userId and not friendlyPlannedCapturesSet:contains(alias.n) then return true end 
                end
                return false 
            end
        )
        return common_utils.map(resultInfos, function (info) return self.items[info.n] end)
    end

    return MapTunnels
end
MapTunnels = _module_init()
_module_init = nil
