require("mod_common_utils")
require("mod_game_utils")

function _module_init()
    local MapTunnels = {}

    local DEFAULT_TUNNEL_SHIPS_SENT = 10

    local function initPlanetInfo(items)
        local planetInfo = {}
        for _,item in pairs(items) do
            if item.is_planet then 
                planetInfo[item.n] = {
                    tunnelable = false
                }
            end
        end
        return planetInfo
    end

    local function initTunnelInfo(planetInfo)
        local tunnelInfo = {}
        for sourceId,_ in pairs(planetInfo) do
            tunnelInfo[sourceId] = {}
            for targetId,_ in pairs(planetInfo) do
                tunnelInfo[sourceId][targetId] = {
                    aliasId = targetId,
                }
            end
        end
        return tunnelInfo
    end

    -- TODO: could modify to take into account bot movement speed, by adding something like ceil(dist_to_time(realDistance(source,target)) / actionRate) * actionRate
    local estimatedRealDistance = game_utils.realDistance

    -- the better tunneling through a planet WOULD have been compared to going around it,
    -- the more (to the second power, as an estimate) congestion the planet adds to paths going around it
    -- TODO: this is imperfect and could use some curve fitting and/or a slightly different approach to estimating congestion. This does a poor job at 
    -- estimating the compounding effects of multiple nearby planets, although it suffices for single congesting planets.
    local function tunnelingDiffToCongestionCorrection(c)
        return c * c / 120
    end

    -- return an effective distance
    local function computeCongestionCorrection(sourceId, targetId, items, planetInfo, numShipsSent, costOverride)
        numShipsSent = numShipsSent or DEFAULT_TUNNEL_SHIPS_SENT
        costOverride = costOverride or 0

        local source = items[sourceId]
        local target = items[targetId]

        local totalCorrection = 0
        for proxyId,_ in pairs(planetInfo) do
            if proxyId ~= sourceId and proxyId ~= targetId then
                local proxy = items[proxyId]
                local tunnelDist = estimatedRealDistance(source, proxy, numShipsSent, costOverride) + estimatedRealDistance(proxy, target, numShipsSent, costOverride)
                local diffFromTunneling = estimatedRealDistance(source, target, numShipsSent, costOverride) - tunnelDist
                local correction = tunnelingDiffToCongestionCorrection(math.max(0, diffFromTunneling))
                totalCorrection = totalCorrection + correction
            end
        end
        return totalCorrection
    end

    local function initCongestionCorrections(items, planetInfo)
        local corrections = {}
        -- necessary to first initialize to avoid nil errors
        for sourceId,_ in pairs(planetInfo) do
            corrections[sourceId] = {}
        end
        for sourceId,_ in pairs(planetInfo) do
            for targetId,_ in pairs(planetInfo) do
                if sourceId == targetId then
                    corrections[sourceId][targetId] = 0
                else 
                    corrections[sourceId][targetId] = corrections[sourceId][targetId] or computeCongestionCorrection(sourceId, targetId, items, planetInfo)
                end
                corrections[targetId][sourceId] = corrections[sourceId][targetId]
            end
        end
        return corrections
    end

    -- TODO: maybe instead, it's best to construct a grid and precompute congestionCorrections and tunnelDists for each grid bucket?
    -- per unit distance, how large a congestion correction would there be, roughly? probably a fraction between 0.1 to 0.2.
    local function getAvgCongestionCorrectionPerUnitDistance(items, planetInfo, congestionCorrections)
        local sum = 0
        local sumDist = 0
        for sourceId,_ in pairs(planetInfo) do
            local source = items[sourceId]
            for targetId,_ in pairs(planetInfo) do
                if sourceId ~= targetId then
                    local target = items[targetId]
                    sum = sum + congestionCorrections[sourceId][targetId]
                    sumDist = sumDist + estimatedRealDistance(source, target, DEFAULT_TUNNEL_SHIPS_SENT, 0)
                end
            end
        end
        return sum / sumDist
    end

    function MapTunnels.new(items, data)
        data = data or {}
        data.planetInfo = data.planetInfo or initPlanetInfo(items)
        data.tunnelInfo = data.tunnelInfo or initTunnelInfo(data.planetInfo)
        data.congestionCorrections = data.congestionCorrections or initCongestionCorrections(items, data.planetInfo)
        data.avgCongestionCorrectionPerDist = data.avgCongestionCorrectionPerDist or getAvgCongestionCorrectionPerUnitDistance(items, data.planetInfo, data.congestionCorrections)

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

    function MapTunnels:setTunnelable(source)
        if self.data.planetInfo[source.n].tunnelable then
            return
        end

        self.data.planetInfo[source.n].tunnelable = true
        self:updateTunnels(source)
    end

    -- TODO: this precalculated congestionCorrectedDistance makes assumptions that IGNORE the passed in numShipsSent/costOverride
    function MapTunnels:getCongestionCorrectedDistance(sourceId, targetId, numShipsSent, costOverride)
        local source = self.items[sourceId]
        local target = self.items[targetId]
        local congestionCorrection = self.data.congestionCorrections[sourceId][targetId]
        return estimatedRealDistance(source, target, numShipsSent, costOverride) + congestionCorrection
    end

    -- TODO: would be better to use grid-based precalculation approach rather than recalculating as needed.
    function MapTunnels:getApproxFleetTunnelDist(fleetId, targetId)
        local fleet = self.items[fleetId]
        local target = self.items[targetId]

        -- Fleet's "realDistance" plus an approximation of congestion corrections for a direct flight to "target".
        local bestDist = (1 + self.data.avgCongestionCorrectionPerDist) * estimatedRealDistance(fleet, target, fleet.ships, fleet.ships/2)
        
        -- test if it's better to land fleet nearby and then tunnel to target
        for aliasId,_ in pairs(self.data.planetInfo) do
            local alias = self.items[aliasId]
            if not alias.neutral then 
                local distToAlias = (1 + self.data.avgCongestionCorrectionPerDist) * estimatedRealDistance(fleet, alias, fleet.ships, fleet.ships/2)
                local totalTunnelDist = distToAlias + self:getSimplifiedTunnelDist(aliasId, targetId)
                if totalTunnelDist < bestDist then 
                    bestDist = totalTunnelDist
                end
            end 
        end

        return bestDist
    end

    function MapTunnels:getTunnelDist(sourceId, targetId, numShipsSent, costOverride)
        numShipsSent = numShipsSent or DEFAULT_TUNNEL_SHIPS_SENT

        local sum = 0
        while sourceId ~= targetId do
            local aliasId = self.data.tunnelInfo[sourceId][targetId].aliasId

            sum = sum + self:getCongestionCorrectedDistance(sourceId, aliasId, numShipsSent, costOverride)

            sourceId = aliasId
        end
        return sum
    end

    -- assuming DEFAULT_TUNNEL_SHIPS_SENT at a time are sent through friendly planets
    function MapTunnels:getSimplifiedTunnelDist(sourceId, targetId)
        if not self.data.tunnelInfo[sourceId][targetId].tunnelDist then
            self.data.tunnelInfo[sourceId][targetId].tunnelDist = self:getTunnelDist(sourceId, targetId, DEFAULT_TUNNEL_SHIPS_SENT, 0)
        end
        return self.data.tunnelInfo[sourceId][targetId].tunnelDist
    end

    function MapTunnels:invalidateTunnelDists()
        for _,s in pairs(self.data.tunnelInfo) do
            for _,tunnelInfo in pairs(s) do
                tunnelInfo.tunnelDist = nil
            end
        end
    end

    -- updates all existing tunnels to consider the candidate as an alias
    -- This calculation is repeated until convergence because updating one tunnel may affect other tunnels that pass through the same planets
    function MapTunnels:updateTunnels(aliasCandidate)
        local converged = false
        local iterations = 0
        while not converged do 
            converged = true
            iterations = iterations + 1

            -- get pairs of source/target and sort by increasing current tunnelDistance
            local sortedPairs = {}
            for sourceId,s in pairs(self.data.tunnelInfo) do
                if aliasCandidate.n ~= sourceId then 
                    for targetId,_ in pairs(s) do
                        if aliasCandidate.n ~= targetId then
                            table.insert(sortedPairs, {sourceId = sourceId, targetId = targetId})
                        end
                    end
                end
            end
            table.sort(sortedPairs, function(p1, p2) 
                return self:getSimplifiedTunnelDist(p1.sourceId, p1.targetId) < self:getSimplifiedTunnelDist(p2.sourceId, p2.targetId)
            end)

            for i,p in ipairs(sortedPairs) do
                local sourceId = p.sourceId 
                local targetId = p.targetId
                local tunnelInfo = self.data.tunnelInfo[sourceId][targetId]
                -- is going DIRECTLY to candidate better (NOT tunneling to candidate first)?
                local sourceToCandidateDist = self:getCongestionCorrectedDistance(sourceId, aliasCandidate.n, DEFAULT_TUNNEL_SHIPS_SENT, 0)

                local currentTunnelDist = self:getSimplifiedTunnelDist(sourceId, targetId)
                local candidateToTargetTunnelDist = self:getSimplifiedTunnelDist(aliasCandidate.n, targetId)

                -- if "candidateAlias" is a faster way to get to "alias", then 
                -- only update if more than 1 distance unit faster, to avoid floating point errors leading to infinite loops.
                if common_utils.toPrecision(sourceToCandidateDist + candidateToTargetTunnelDist, 1) < common_utils.toPrecision(currentTunnelDist, 1) then 
                    tunnelInfo.aliasId = aliasCandidate.n
                    -- other tunnels may be affected by this, causing a cascade of recalculations to be necessary
                    self:invalidateTunnelDists()
                    tunnelInfo.tunnelDist = sourceToCandidateDist + candidateToTargetTunnelDist
                
                    converged = false
                end
            end
            if iterations > 5 then 
                print("WARNING: took more than " .. iterations .. " iterations to converge")
                break 
            end 
        end
    end

    function MapTunnels:getTunnelAlias(sourceId, targetId) 
        return self.items[self.data.tunnelInfo[sourceId][targetId].aliasId]
    end

    function MapTunnels:isTunnelable(planetId)
        return self.data.planetInfo[planetId].tunnelable 
    end

    return MapTunnels
end
MapTunnels = _module_init()
_module_init = nil
