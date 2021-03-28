require("mod_common_utils")
require("mod_game_utils")

-- game_utils.realDistance = memoize(game_utils.realDistance)

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

    local function initTunnelInfo(items, planetInfo)
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

    function MapTunnels.new(items, data)
        data = data or {}
        data.planetInfo = data.planetInfo or initPlanetInfo(items)
        data.tunnelInfo = data.tunnelInfo or initTunnelInfo(items, data.planetInfo)

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

    -- TODO: add tunnelTime, which could predict time to arrival, summing ceil(dist_to_time(realDistance(source,target)) / actionRate) * actionRate
    function MapTunnels:setTunnelable(source)
        if self.data.planetInfo[source.n].tunnelable then
            return
        end

        self.data.planetInfo[source.n].tunnelable = true
        self:updateTunnels(source)
    end

    function MapTunnels:getTunnelDist(sourceId, targetId, numShipsSent, costOverride)
        numShipsSent = numShipsSent or DEFAULT_TUNNEL_SHIPS_SENT

        local sum = 0
        while sourceId ~= targetId do
            local source = self.items[sourceId]
            local aliasId = self.data.tunnelInfo[sourceId][targetId].aliasId
            local alias = self.items[aliasId]

            -- TODO: use "intervening planets" correction to account for ships getting stuck on planets...
            local estDist = game_utils.realDistance(source, alias, numShipsSent, costOverride)
            sum = sum + estDist

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
        for sourceId,s in pairs(self.data.tunnelInfo) do
            for targetId,tunnelInfo in pairs(s) do
                self.data.tunnelInfo[sourceId][targetId].tunnelDist = nil
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

            for sourceId,s in pairs(self.data.tunnelInfo) do
                if aliasCandidate.n ~= sourceId then 
                    local source = self.items[sourceId]
                    local sourceToCandidateDist = game_utils.realDistance(source, aliasCandidate, DEFAULT_TUNNEL_SHIPS_SENT, 0)
                    for targetId,tunnelInfo in pairs(s) do
                        if aliasCandidate.n ~= targetId then 

                            local currentTunnelDist = self:getSimplifiedTunnelDist(sourceId, targetId)
                            local candidateToTargetTunnelDist = self:getSimplifiedTunnelDist(aliasCandidate.n, targetId)

                            -- if "candidateAlias" is a faster way to get to "alias", then 
                            if common_utils.toPrecision(sourceToCandidateDist + candidateToTargetTunnelDist, 1) < common_utils.toPrecision(currentTunnelDist, 1) then 
                                tunnelInfo.aliasId = aliasCandidate.n
                                -- other tunnels may be affected by this, causing a cascade of recalculations to be necessary
                                self:invalidateTunnelDists()
                                tunnelInfo.tunnelDist = sourceToCandidateDist + candidateToTargetTunnelDist
                            
                                converged = false
                            end
                        end
                    end
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
