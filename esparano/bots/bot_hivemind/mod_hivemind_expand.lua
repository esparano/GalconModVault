require("mod_hivemind_action")
require("mod_hivemind_plan")
require("mod_game_utils")
require("mod_common_utils")
require("mod_set")
 
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

        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.plannedCapturesData = {}
        instance.reservations = {}

        return instance
    end

    function ExpandMind:processPlan(map, mapTunnels, mapFuture, botUser, plan)
        local satisfied, fullAttackData = self:updatePlannedCapture(map, mapTunnels, mapFuture, botUser, plan.data.targetN)
        if satisfied then 
            plan.satisfied = true
        else
            table.insert(self.plannedCapturesData, fullAttackData)
        end
    end

    -- TODO: shuttle ships towards planets that will be expanded so that we can expand faster if we want? Shuttle ships towards planets that are close to + shipdiff and good returns/prod?

    -- return whether plan is satisfied already, 
    -- and if not satisfied yet, returns fullAttackData
    function ExpandMind:updatePlannedCapture(map, mapTunnels, mapFuture, botUser, targetN)
        local target = map._items[targetN]

        -- target was already captured
        if not target.neutral then return true end

        local fullAttackData = getFullAttackData(map, mapTunnels, target, botUser, self.reservations)

        -- abandon plan if no longer viable
        if not self:isFullAttackViable(map, mapTunnels, mapFuture, botUser, fullAttackData) then 
            -- print("abandoning plan to capture " .. getNeutralDesc(map, mapTunnels, botUser, fullAttackData.target))
            return true 
        end

        mapTunnels:setTunnelable(target)

        -- update reservations
        for k,v in pairs(fullAttackData.newReservations) do 
            self.reservations[k] = self.reservations[k] or 0
            self.reservations[k] = self.reservations[k] + v
        end

        return false, fullAttackData
    end

    function ExpandMind:suggestActions(map, mapTunnels, mapFuture, botUser)
        local candidates = {}

        -- run this just to better calculate tunnels
        getNeutralsDataWithPositiveRoi(map, mapTunnels, botUser)

        candidates = common_utils.combineLists(candidates, self:suggestFullAttackSafeActions(map, mapTunnels, mapFuture, botUser))
        -- TODO: send towards "good" areas, summing prod for each branch/front planet etc.

        return candidates
    end

    function ExpandMind:gradeAction(map, mapTunnels, mapFuture, botUser, action)
    end

    ----------------------------------------------------

    -- TODO: performance issues when there are many planets
    function ExpandMind:suggestFullAttackSafeActions(map, mapTunnels, mapFuture, botUser)
        local candidates = {}
    
        local safeNeutralData = self:getFullAttackSafeNeutralData(map, mapTunnels, mapFuture, botUser)
        -- plannedCaptures were already verified to be full-attack safe.
        safeNeutralData = common_utils.combineLists(safeNeutralData, self.plannedCapturesData)
        -- only send if the neutral won't already be captured by incoming fleets
        safeNeutralData = common_utils.filter(safeNeutralData, function (data) return getMinShipsToCapture(map, mapFuture, botUser, data.target) >= 0 end)  
        
        for i,data in ipairs(safeNeutralData) do
            local isPreplanned = common_utils.findFirst(self.plannedCapturesData, function (p) return p == data end)
            local planContinuityBonus = isPreplanned and 5 * self.planContinuityBonus or 0
            
            -- introduce various nonlinearities
            local captureEase = common_utils.clamp(self.fullAttackDiffWeight * data.shipDiff + 10 - 10 * self.fullAttackDiffIntercept, 
                self.fullAttackDiffMin * -10, self.fullAttackDiffMax * 10)
            local gainBonus = (data.friendlyProdFromTarget * self.gainedShipsWeight - 2 * data.target.ships * self.targetCostWeight)
            -- if planet is owned at the end, add production, otherwise, only add ships gained
            if data.ownsPlanetAtEnd then
                if gainBonus < 0 then 
                    gainBonus = math.max(10 - 10 * self.ownedPlanetMaxShipLoss, gainBonus * self.negativeRoiReductionFactor * 0.3)
                end
                gainBonus = gainBonus + self.fullAttackProdWeight * data.target.production / 3
            else
                gainBonus = (data.friendlyProdFromTarget * self.gainedShipsWeight - 2 * data.target.ships * self.targetCostWeight) + data.target.production / 10
            end

            local initialPriority = self.fullAttackCaptureEase * captureEase / 10 + planContinuityBonus + gainBonus
            initialPriority = initialPriority * self.fullAttackOverallWeight

            local capturingSource = data.capturingSources[#data.capturingSources]
            if capturingSource.is_planet then
                local capturingSourceShipsNeeded = data.newReservations[capturingSource.n]
                if capturingSourceShipsNeeded >= 0 then 
                    
                    local percent = game_utils.percentToUse(capturingSource, capturingSourceShipsNeeded)
                    local to = mapTunnels:getTunnelAlias(capturingSource.n, data.target.n)

                    local sources = {capturingSource}

                    for i,source in ipairs(data.capturingSources) do 
                        if self.settings.multiSelect and source.is_planet and source ~= capturingSource then 
                            local thisPercent = game_utils.percentToUse(source, data.newReservations[source.n])
                            local thisTo = mapTunnels:getTunnelAlias(source.n, data.target.n)
                            if thisPercent >= percent and thisTo.n == to.n then 
                                table.insert(sources, source)
                            end
                        end
                    end

                    -- add other sources to the plan if they have the same target and can afford the sending (without reservations etc.)

                    local plan
                    -- if plan already exists, no need to add a second plan to capture the same neutral.
                    if not isPreplanned then 
                        plan = self:constructPlan(data.target)
                    end
                    local desc = isPreplanned and "Planned@" or "New@"
                    local neutralDesc = getNeutralDesc(map, mapTunnels, botUser, data.target)

                    -- print("sending " .. percent .. " to " .. to.ships .. " which needs " .. capturingSourceShipsNeeded)
                    -- for i,source in ipairs(sources) do 
                    --     print("source " .. source.ships)
                    -- end

                    local action = Action.newSend(initialPriority, self, desc .. neutralDesc, {plan}, sources, to, percent)
                    table.insert(candidates, action)
                end
            else
                -- TODO: how to redirect fleets to help capture??

                -- we have to wait for a fleet to land before it makes sense to start tunneling ships towards the target
                -- print("capture of " .. data.target.ships .. " already handled by fleet " .. data.capturingSource.ships .. " targeting " .. map._items[data.capturingSource.target].ships)
            end
        end

        return candidates
    end

    function ExpandMind:constructPlan(target)
        local data = {targetN = target.n}
        return Plan.new(self.name, data)
    end

    function ExpandMind:getFullAttackSafeNeutralData(map, mapTunnels, mapFuture, botUser)
        local mind = self
        local candidates = common_utils.filter(map:getNeutralPlanetList(), function (target) return 
            -- don't attack neutrals that are already planned to be captured
            not common_utils.findFirst(mind.plannedCapturesData, function (data) return data.target.n == target.n end)
            -- only send if the neutral won't already be captured by incoming fleets
            and getMinShipsToCapture(map, mapFuture, botUser, target) >= 0
        end)
        local safeNeutralData = {}
        for _,target in ipairs(candidates) do
            local fullAttackData = getFullAttackData(map, mapTunnels, target, botUser)
            if self:isFullAttackViable(map, mapTunnels, mapFuture, botUser, fullAttackData) then
                -- print("is full attack safe: " .. getNeutralDesc(map, mapTunnels, botUser, fullAttackData.target))
                table.insert(safeNeutralData, fullAttackData)
            else 
                -- print("is not full attack safe: " .. getNeutralDesc(map, mapTunnels, botUser, fullAttackData.target))
            end
        end 
        return safeNeutralData
    end

    -- if planet is owned at end, OR if planet is lost but recovers twice its cost by the time the enemy arrives 
    -- (2x cost because of friendly investment plus the enemy doesn't need to invest anymore)
    function ExpandMind:isFullAttackViable(map, mapTunnels, mapFuture, botUser, neutralAttackData)
        local safe = neutralAttackData.ownsPlanetAtEnd or neutralAttackData.friendlyProdFromTarget > 2 * neutralAttackData.target.ships
        if not safe then return false end

        local totalReservations = common_utils.copy(mapFuture:getReservations())
        mapFuture:updateReservations(neutralAttackData.newReservations, totalReservations)

        -- if we reserve ships to attack the neutral planet, will we lose a front planet in a full attack?
        local friendlyPlannedCapturesSet = Set.new({neutralAttackData.target.n})
        local frontPlanets = getFrontPlanets(map, mapTunnels, botUser, friendlyPlannedCapturesSet)
        -- print("#frointplanets .. " .. #frontPlanets)
        for i,p in ipairs(frontPlanets) do
            local frontAttackData = getFullAttackData(map, mapTunnels, p, botUser, totalReservations)
            -- TODO: this could be overly cautious. Sometimes you still want to expand despite not owning a planet at the end...
            if not frontAttackData.ownsPlanetAtEnd then 
                local neutralDesc = getNeutralDesc(map, mapTunnels, botUser, neutralAttackData.target)
                -- print("planet " .. p.ships .. " is vulnerable by " .. neutralAttackData.shipDiff .. " if expanding to " .. neutralDesc)
                return false 
            end 
        end 

        return true
    end

    function getFullAttackData(map, mapTunnels, target, botUser, reservations)
        local ownsPlanetAtEnd, shipDiff, friendlyProdFromTarget, capturingSources, newReservations = mapFuture:simulateFullAttack(map, mapTunnels, target, botUser, reservations)
        return {
            target = target,
            ownsPlanetAtEnd = ownsPlanetAtEnd,
            shipDiff = shipDiff,
            friendlyProdFromTarget = friendlyProdFromTarget,
            capturingSources = capturingSources,
            newReservations = newReservations,
        }
    end

    -- a "front" planet is any "owned" (or planned-to-be-captured) planet that does not need to tunnel to attack its closest enemy planet
    -- will return empty list if there are no enemy planets
    function getFrontPlanets(map, mapTunnels, user, friendlyPlannedCapturesSet, enemyPlannedCapturesSet)
        friendlyPlannedCapturesSet = friendlyPlannedCapturesSet or Set.new()
        enemyPlannedCapturesSet = enemyPlannedCapturesSet or Set.new()
        local friendlyPlanets = common_utils.filter(map:getPlanetList(), 
            function (p) return p.owner == user.n or friendlyPlannedCapturesSet:contains(p.n) end
        )
        local enemyUser = map:getEnemyUser(user.n)
        local enemyPlanets = common_utils.filter(map:getPlanetList(), 
            function (p) return p.owner == enemyUser.n or enemyPlannedCapturesSet:contains(p.n) end
        )
        return common_utils.filter(friendlyPlanets, 
            function (source)
                local closestEnemyPlanet = common_utils.find(enemyPlanets,
                    function (target) 
                        return - mapTunnels:getSimplifiedTunnelDist(source.n, target.n) 
                    end
                )
                return closestEnemyPlanet ~= nil and mapTunnels:getTunnelAlias(source.n, closestEnemyPlanet.n).owner ~= user.n
            end
        )
    end

    function getNeutralDesc(map, mapTunnels, botUser, neutral)
        local home = getHome(map, mapTunnels, botUser)
        local enemyHome = getHome(map, mapTunnels, map:getEnemyUser(botUser))
        local ownership = "My"
        if mapTunnels:getSimplifiedTunnelDist(enemyHome.n, neutral.n) < mapTunnels:getSimplifiedTunnelDist(home.n, neutral.n) then 
            ownership = "Their"
        end
        return ownership .. common_utils.round(neutral.ships)
    end

    function getMinShipsToCapture(map, mapFuture, botUser, target)
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

    return ExpandMind
end
ExpandMind = _m_init()
_m_init = nil
