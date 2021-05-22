require("mod_hivemind_action")
require("mod_hivemind_utils")

--[[
    Attack from front planets to enemy front planets, especially if they are weak or very close and can be overwhelmed
    Otherwise attack back planets?
]]
function _m_init()
    local AttackMind = {}

    function AttackMind.new(params)
        local instance = {}
        for k,v in pairs(AttackMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "Attack"

        return instance
    end

    --[[
        #Num moves suggested as configurable per mind?? Max num?#  
    ]]
    function AttackMind:suggestActions(plans)
        local candidates = {}

        candidates = common_utils.combineLists(candidates, self:suggestBasicAttacks(plans))

        return candidates
    end

    function AttackMind:suggestBasicAttacks(plans)
        local enemyUser = self.map:getEnemyUser(self.botUser)
        
        local friendlyPlannedCapturesSet = Set.new()
        for i,p in ipairs(plans) do 
            -- add expansion targets here
            if p.mindName == "Expand" then
                friendlyPlannedCapturesSet:add(p.data.targetN)
            end
        end

        -- TODO: memoize/centralize getFrontPlanets calls
        local frontPlanets = self.mapTunnels:getFrontPlanets(self.botUser, friendlyPlannedCapturesSet)
        local enemyFrontPlanets = self.mapTunnels:getFrontPlanets(enemyUser)

        -- gather stats on front planets (full-attack info, various near-prod/cluster-value metrics, then create moves based on that information (if not neutral))
        local enemyFrontNearbyEnemyProds = common_utils.map(enemyFrontPlanets, function(front) return self:getNearbyUserProd(front, enemyUser) end)
        local enemyFrontNearbyEnemyShips = common_utils.map(enemyFrontPlanets, function(front) return self:getNearbyUserShips(front, enemyUser) end)
        local friendlyFrontNearbyFriendlyProds = common_utils.map(frontPlanets, function(front) return self:getNearbyUserProd(front, self.botUser) end)
        local enemyFrontNearbyCapturableProds = common_utils.map(enemyFrontPlanets, function(front) return self:getNearbyCapturableProd(front) end)
        local friendlyFrontFullAttacks = common_utils.map(frontPlanets, function(front) return self:getFullAttackData(front, plans) end)
        local enemyFrontFullAttacks = common_utils.map(enemyFrontPlanets, function(front) return self:getFullAttackData(front, plans) end)

        local candidates = {}

        for i,front in ipairs(frontPlanets) do 
            if not front.neutral then 
                local shipsReserved = self.mapFuture:getReservations()[front.n] or 0
                local percent = getPercentToUseWithReservation(front, front.ships, shipsReserved)
                local availableShips = getAmountSent(front, percent)
                if availableShips > 0 then
                    for j,enemyFront in ipairs(enemyFrontPlanets) do 
                        local initialPriority = self:getInitialPriority(front, availableShips, friendlyFrontFullAttacks[i], friendlyFrontNearbyFriendlyProds[i], 
                            enemyFront, enemyFrontFullAttacks[j], enemyFrontNearbyEnemyProds[j], enemyFrontNearbyCapturableProds[j], enemyFrontNearbyEnemyShips[j])
                        
                        local alias = self.mapTunnels:getTunnelAlias(front.n, enemyFront.n)
                        local desc = "Attack@" .. getPlanetDesc(self.map, self.botUser, enemyFront)
                        local action = Action.newSend(initialPriority, self, desc, {}, {front}, alias, percent)
                        table.insert(candidates, action)
                    end
                end
            end
        end

        return candidates
    end
    
    function AttackMind:getInitialPriority(front, availableShips, frontFullAttack, frontNearbyProd, target, targetFullAttack, targetNearbyProd, targetClusterWorth, targetNearbyShips)
        local priority = 0

        -- attack along ship differentials
        local incomingShips = getNetIncomingAndPresentShips(self.mapFuture, front)
        local incomingTargetShips = getNetIncomingAndPresentShips(self.mapFuture, target)
        local naiveShipDiff = incomingShips - incomingTargetShips
        priority = priority + self.naiveShipDiffWeight * naiveShipDiff / 10

        -- attack towards production
        local naiveProdDiff = self.targetProdWeight * target.production
        local nearbyProdDiff = self.targetNearbyProdWeight * targetNearbyProd

        -- if enemy can capture planet:
        if frontFullAttack.enemyProdFromTarget > 0 then
            -- if planet will be recaptured captured back in the future, wait for support
            -- if frontFullAttack.shipDiff > 0 then 
                priority = priority - 2 * frontFullAttack.enemyProdFromTarget * self.delayCaptureWeight 
            -- end
            -- TODO: desperado?
        end

        local overcapture = math.max(0, availableShips - self.overcaptureIncomingShipsWeight * incomingTargetShips - self.overcapturedNearbyEnemyShipsWeight * targetNearbyShips)
        priority = priority - overcapture * self.overcapturePenalty / 10

        priority = priority + self.targetClusterWeight * targetClusterWorth / (self.emptyClusterIntercept * 5 + self.emptyClusterBonus * targetNearbyShips)

        -- attack according to excess ships and strength/weakness
        priority = priority + self.frontShipDiffWeight * frontFullAttack.shipDiff +  self.targetShipDiffWeight * targetFullAttack.shipDiff

        -- positive priority is a function of distance...
        local dist = self.mapTunnels:getSimplifiedTunnelDist(front.n, target.n)
        priority = priority / (5 * self.distIntercept + self.distWeight * dist ^ (self.distExponent))

        priority = priority * availableShips ^ self.availableShipsExponent

        priority = priority * self.overallWeight + self.overallBias - 1

        return priority
    end

    function AttackMind:getNearbyCapturableProd(target)
        local planets = self.map:getPlanetList()
        local total = 0
        for i,p in ipairs(planets) do
            if not p.neutral and p.n ~= target.n then 
                local dist = self.mapTunnels:getSimplifiedTunnelDist(target.n, p.n)
                total = total + 50 * (p.production ^ self.nearbyCapturableProdProdExponent) / ((dist + 5 * self.nearbyCapturableProdDistIntercept) ^ self.nearbyCapturableProdDistExponent)
            end
        end
        return total
    end

    function AttackMind:getNearbyUserProd(target, owner)
        local planets = self.map:getPlanetList(owner)
        local total = 0
        for i,p in ipairs(planets) do
            if p.n ~= target.n then 
                local dist = self.mapTunnels:getSimplifiedTunnelDist(target.n, p.n)
                total = total + 50 * (p.production ^ self.nearbyUserProdProdExponent) / ((dist + 5 * self.nearbyUserProdDistIntercept) ^ self.nearbyUserProdDistExponent)
            end
        end
        return total
    end

    function AttackMind:getNearbyUserShips(target, owner)
        local planets = self.map:getPlanetList(owner)
        local total = 0
        for i,p in ipairs(planets) do
            if p.n ~= target.n then 
                local dist = self.mapTunnels:getSimplifiedTunnelDist(target.n, p.n)
                total = total + 50 * (p.ships ^ self.nearbyUserShipsShipsExponent) / ((dist + 5 * self.nearbyUserShipsDistIntercept) ^ self.nearbyUserShipsDistExponent)
            end
        end
        return total
    end

    function AttackMind:getFullAttackData(target, plans)
        return getFullAttackData(self.map, self.mapTunnels, self.mapFuture, self.botUser, target, plans)
    end

    function AttackMind:getPlanetDesc(p)
        return getPlanetDesc(self.map, self.botUser, p)
    end

    function AttackMind:gradeAction(action, plans)
    end

    return AttackMind
end
AttackMind = _m_init()
_m_init = nil
