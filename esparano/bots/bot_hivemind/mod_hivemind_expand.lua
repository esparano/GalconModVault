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

    -- return whether plan is satisfied already, 
    -- and if not satisfied yet, returns fullAttackData
    function ExpandMind:updatePlannedCapture(map, mapTunnels, mapFuture, botUser, targetN)
        local target = map._items[targetN]

        -- target was already captured
        if not target.neutral then return true end

        local fullAttackData = getFullAttackData(map, mapTunnels, target, botUser, self.reservations)

        -- abandon plan if no longer viable
        if not isFullAttackViable(fullAttackData) then return true end

        -- set plan's target as tunnelable
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
        
        return candidates
    end

    function ExpandMind:gradeAction(map, mapTunnels, mapFuture, botUser, action)
    end

    ----------------------------------------------------

    function ExpandMind:suggestFullAttackSafeActions(map, mapTunnels, mapFuture, botUser)
        local candidates = {}
    
        local safeNeutralData = self:getFullAttackSafeNeutralData(map, mapTunnels, mapFuture, botUser)
        -- plannedCaptures were already verified to be full-attack safe.
        safeNeutralData = common_utils.combineLists(safeNeutralData, self.plannedCapturesData)

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

            if data.capturingSource.is_planet then
                local capturingSourceShipsNeeded = data.newReservations[data.capturingSource.n]
                local percent = game_utils.percentToUse(data.capturingSource, capturingSourceShipsNeeded)

                local to = mapTunnels:getTunnelAlias(data.capturingSource.n, data.target.n)

                local plan
                -- if plan already exists, no need to add a second plan to capture the same neutral.
                if not isPreplanned then 
                    plan = self:constructPlan(data.target)
                end
                local desc = isPreplanned and "Planned@" or "New@"
                local action = Action.newSend(initialPriority, self, desc .. common_utils.round(data.target.ships), {plan}, {data.capturingSource}, to, percent)
                table.insert(candidates, action)
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
            local fullAttackData = getFullAttackData(map, mapTunnels, target, botUser, self.reservations)
            if isFullAttackViable(fullAttackData) then
               table.insert(safeNeutralData, fullAttackData)
            end
        end
        return safeNeutralData
    end

    -- if planet is owned at end, OR if planet is lost but recovers twice its cost by the time the enemy arrives 
    -- (2x cost because of friendly investment plus the enemy doesn't need to invest anymore)
    function isFullAttackViable(fullAttackData)
        return fullAttackData.ownsPlanetAtEnd or fullAttackData.friendlyProdFromTarget > 2 * fullAttackData.target.ships
    end

    function getFullAttackData(map, mapTunnels, target, botUser, reservations)
        local ownsPlanetAtEnd, shipDiff, friendlyProdFromTarget, capturingSource, newReservations = mapFuture:simulateFullAttack(map, mapTunnels, target, botUser, reservations)
        return {
            target = target,
            ownsPlanetAtEnd = ownsPlanetAtEnd,
            shipDiff = shipDiff,
            friendlyProdFromTarget = friendlyProdFromTarget,
            capturingSource = capturingSource,
            newReservations = newReservations,
        }
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
