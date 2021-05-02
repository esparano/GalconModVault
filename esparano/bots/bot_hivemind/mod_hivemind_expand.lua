require("mod_hivemind_action")
require("mod_game_utils")
require("mod_common_utils")

--[[
-most complex mind, should it be broken up?
-add bonus if move sends ships closer to good neutrals
-send towards good neutrals
-for each capturable neutral, find soonest to capture maybe? Then attempt attacking (multi-select?) neutral
-equal prod, planet exists where full on attack can defend
]]
function _m_init()
    local ExpandMind = {}

    function ExpandMind.new(params)
        local instance = {}
        for k, v in pairs(ExpandMind) do
            instance[k] = v
        end

        instance.name = "Expand"
        instance.roiWeight = params.roiWeight
        instance.shipReturnsWeight = params.roiWeight

        return instance
    end

    function ExpandMind:suggestActions(map, mapTunnels, mapFuture, botUser)
        local candidates = {}

        candidates = common_utils.combineLists(candidates, self:suggestPositiveRoiActions(map, mapTunnels, mapFuture, botUser))
        
        return candidates
    end

    function ExpandMind:gradeAction(map, mapTunnels, mapFuture, botUser, action)
    end

    ----------------------------------------------------

    function ExpandMind:suggestPositiveRoiActions(map, mapTunnels, mapFuture, botUser)
        local candidates = {}
        -- TODO: mind for not sending as much from planets that have incoming friendly planets for efficiency purposes?

        -- TODO: A TEMPORARY HACK, tunnel from highest ships value
        -- TODO: send towards planet "vacuum style"
        -- See mod_watson, attackNeutral()
        -- TODO: take into account enemy planets and/or examine planet futures
        local from = common_utils.find(map:getPlanetList(botUser), function(o) return o.ships end)
        if not from then
            return candidates
        end
    
        local friendlyPositiveRoiNeutralData, enemyPositiveRoiNeutralData = getNeutralsDataWithPositiveRoi(map, mapTunnels, botUser)
        for i,data in ipairs(friendlyPositiveRoiNeutralData) do 
            local initialPriority = self.roiWeight * data.roi + self.shipReturnsWeight * data.shipReturns 
    
            local to = mapTunnels:getTunnelAlias(from.n, data.target.n)
            
            local shipsRequired = self:getMinShipsToCapture(map, mapFuture, botUser, data.target)

            -- only send if the neutral won't already be captured by incoming fleets
            if shipsRequired >= 0 then
                local percent = game_utils.percentToUse(from, shipsRequired)

                local action = Action.newSend(initialPriority, self, "+RoI", {from}, data.target, percent)
                table.insert(candidates, action)
            end
        end

        return candidates
    end

    function ExpandMind:getMinShipsToCapture(map, mapFuture, botUser, target)
        return target.ships - mapFuture:getNetIncomingShips(target)
    end
    
    -- TODO: this is really an approximation. A bit hacky
    function getHome(map, mapTunnels, user)
        return common_utils.find(map:getPlanetList(user.n), function(p) return p.production end)
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

        -- make sure positive-roi neutrals are set to tunnelable. Process positive-roi neutrals one at a time, alternating between enemy and friendly user, 
        -- picking the highest-roi for each user first, because either user being able to tunnel through a planet will affect the captures of other planets
        while true do
            local bestEnemyNeutral = identifyHighestRoiNeutral(map, mapTunnels, enemyUser)
            local bestFriendlyNeutral = identifyHighestRoiNeutral(map, mapTunnels, user)
            if not bestEnemyNeutral and not bestFriendlyNeutral then break end 
        end

        -- now that tunnels have been figured out properly, return positive ROI data for both player and enemy
        return getPositiveRoiNeutralData(map, mapTunnels, user, map:getNeutralPlanetList()), 
            getPositiveRoiNeutralData(map, mapTunnels, enemyUser, map:getNeutralPlanetList())
    end

    return ExpandMind
end
ExpandMind = _m_init()
_m_init = nil
