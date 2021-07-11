require("mod_hivemind_action")
--[[
-send ships near enemy target and close by planets to enemy fleet.
-adds bonus to moves that help defend
-- if up prod + behidn ships and can defend attack ,maybe?
]]
function _m_init()
    local DefendMind = {}

    function DefendMind.new(params)
        local instance = {}
        for k, v in pairs(DefendMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "Defend"

        return instance
    end

    function DefendMind:suggestActions(plans)
        local candidates = {}

        local needs, reservationInfos = self:reserveMinimum(plans)

        -- send ships reserved by reserveMinimum to their targets
        candidates = common_utils.combineLists(candidates, self:sendReservations(plans, needs, reservationInfos))

        -- if defensive needs could not be met by reserveMinimum, send from outside sources
        candidates = common_utils.combineLists(candidates, self:sendTowardsWeak(plans, needs))

        return candidates
    end

    -- TODO: use a better method, like sorting based on dist to fleet's target + dist to fleet * C, and reserving until past some radius?
    -- for testing purposes, use Sparky's method of reservation. (some % to target, distribute rest to nearest planets to fleet)
    function DefendMind:reserveMinimum(plans)
        local needs = {}
        local reservationInfos = {}
        local enemyUser = self.map:getEnemyUser(self.botUser)

        -- add +1 ships to total reservation of each attacked planet (only once per planet) so it's not cutting it so close
        local targetExtraDefenseSet = Set.new()

        for i,fleet in ipairs(self.map:getFleetList(enemyUser)) do 
            local target = self.map._items[fleet.target]
            local totalToReserve = fleet.ships 

            -- slightly over-reserve for now, and bot can optimize this away if it wants.
            local nearbyToReserve = totalToReserve * (0.3 + self.nearbyReserveProportion - 1)
            -- TODO: reserve wtihin fleet radius distance + some amount?
            -- TODO: don't just reserve from nearest planet. Reserve from others too.
            -- TODO: only reserve from nearest if certain distance??
            local closestFriendlyPlanet = common_utils.find(self.map:getPlanetList(self.botUser),
                function(p) return -self.mapTunnels:getApproxFleetDirectDist(fleet, p) end)
            if closestFriendlyPlanet then
                logger:trace("closest planet to fleet " .. fleet.ships .. " is " .. closestFriendlyPlanet.ships)
                -- TODO: this will only consider closestFriendlyPlanet... because of fleet distance, only nearest is considered nearest?.
                local overflow = self:reserveNearbyProdThenNearbyShips(fleet, closestFriendlyPlanet, nearbyToReserve, needs, reservationInfos)
            end
            
            local targetToReserve = totalToReserve * (0.9 + self.targetReserveProportion - 1)
            if target.owner == self.botUser.n then
                -- logger:debug("processing target " .. totalToReserve)
                if not targetExtraDefenseSet:contains(target.n) then 
                    totalToReserve = totalToReserve + 1
                    targetExtraDefenseSet:add(target.n)
                    logger:trace("extra defense for " .. target.ships)
                end
            end
            self:reserveNearbyProdThenNearbyShips(fleet, target, targetToReserve, needs, reservationInfos)
        end

        -- NOTE: Reserved ships are already determined to be roughly "in the right area" (closer to target than fleet is). Only "needs" need to be satisfied.

        return needs, reservationInfos
    end

    -- sort both fleets and planets by tunnel distance to attackTarget and return related info
    function DefendMind:_getDistSortedSourceData(attackTarget, maxDist)
        local sourceData = common_utils.map(self.map:getPlanetAndFleetList(self.botUser), function (o)
            local data = {
                source = o,
            }
            if o.is_fleet then
                data.dist = self.mapTunnels:getApproxFleetTunnelDist(o, o.target) + self.mapTunnels:getSimplifiedTunnelDist(o.target, attackTarget)
            else
                data.dist = self.mapTunnels:getSimplifiedTunnelDist(o, attackTarget)
            end
            return data
        end)
        sourceData = common_utils.filter(sourceData, function(data) return data.dist <= maxDist end)
        table.sort(sourceData, function (d1, d2) return d1.dist < d2.dist end)
        return sourceData
    end

    -- first, reserve future prod from all friendly planets closer to the target than the fleet is (starting at the target).
    -- Then, reserve ships from all friendly planets closer to the target than the fleet is (starting at the target).
    function DefendMind:reserveNearbyProdThenNearbyShips(attackingFleet, target, amountToReserve, needs, reservationInfos)
        local fleetDirectDist = self.mapTunnels:getApproxFleetDirectDist(attackingFleet, target)
        local arrivalTime = game_utils.distToTravelTime(fleetDirectDist)

        logger:trace("arrivalTime: " .. arrivalTime)

        local sourceDatasWithinFleetDist = self:_getDistSortedSourceData(target, fleetDirectDist)
        for i,sourceData in ipairs(sourceDatasWithinFleetDist) do
            -- TODO: reserve planned-capture prods too.
            if sourceData.source.is_planet and sourceData.source.owner == self.botUser.n then
                amountToReserve = amountToReserve - self.mapFuture.reservations:reserveFutureProd(sourceData.source, arrivalTime, amountToReserve)
            end
        end
        local sourceDatasWithinFleetDistPlusRadius = self:_getDistSortedSourceData(target, fleetDirectDist + attackingFleet.r * self.fleetRadiusDefenseLeniency)
        for i,sourceData in ipairs(sourceDatasWithinFleetDistPlusRadius) do
            if sourceData.source.owner == self.botUser.n then 
                local reservation = self.mapFuture.reservations:reserveShips(sourceData.source, amountToReserve)
                amountToReserve = amountToReserve - reservation

                if sourceData.source.is_planet and reservation > 0 then 
                    local alias = self.mapTunnels:getTunnelAlias(sourceData.source, target)

                    reservationInfos[sourceData.source.n] = reservationInfos[sourceData.source.n] or {} 
                    reservationInfos[sourceData.source.n][alias.n] = reservationInfos[sourceData.source.n][alias.n] or 0
                    reservationInfos[sourceData.source.n][alias.n] = reservationInfos[sourceData.source.n][alias.n] + reservation
                end
            end
        end
        logger:trace("arrivalTime: " .. arrivalTime)
        
        local overflow = common_utils.toPrecision(amountToReserve, 5)
        if overflow > 0 then
            logger:trace("could not reserve near target: " .. overflow)
            -- TODO: needs are being added for enemy fleets...
            table.insert(needs, {
                amount = overflow,
                p = target,
                attacker = attackingFleet,
            })
        end
    
        return overflow
    end

    function DefendMind:sendTowardsNeed(plans, needs)
        local candidates = {}

        -- Accumulate information about the needs and worth of each defense
        local destNeedInfo = self:getDestinationNeedInfo(needs)

        -- sort based on prod / need indicating the best to defend with fewest ships
        -- table.sort()
        for n,needInfo in pairs(destNeedInfo) do 
            -- logger:debug("need " .. needInfo.totalAmount .. " on planet " .. needInfo.p.ships)
        end

        return candidates
    end

    function DefendMind:getDestinationNeedInfo(needs)
        local destNeedInfo = {}
        for i,need in ipairs(needs) do 
            need.dist = self.mapTunnels:getApproxFleetDirectDist(need.attacker, need.p)
            destNeedInfo[need.p.n] = destNeedInfo[need.p.n] or {
                totalAmount = 0,
                needs = {},
                p = need.p
            }
            destNeedInfo[need.p.n].totalAmount = destNeedInfo[need.p.n].totalAmount + need.amount
            table.insert(destNeedInfo[need.p.n].needs, need)
        end
        return destNeedInfo
    end

    function DefendMind:getFriendlyPlanetsAndPlannedCaptures(plans)
        local friendlyPlannedCapturesSet = Set.new()
        for i,p in ipairs(plans) do
            if p.mindName == "Expand" then
                friendlyPlannedCapturesSet:add(p.data.targetN)
            end
        end
        return common_utils.filter(self.map:getPlanetList(), 
            function (p) 
                return p.owner == self.botUser.n or friendlyPlannedCapturesSet:contains(p.n) 
            end
        )
    end

    function DefendMind:sendReservations(plans, needs, reservationInfos)
        local candidates = {}

        for sourceN,reservationInfo in pairs(reservationInfos) do
            local source = self.map._items[sourceN]

            local totalSourceReservations = 0
            for _,totalShips in pairs(reservationInfo) do    
                totalSourceReservations = totalSourceReservations + totalShips
            end

            for aliasN,totalShips in pairs(reservationInfo) do  
                if sourceN ~= aliasN then       
                    local alias = self.map._items[aliasN]         
                    local initialPriority = self:getSendReservationsPriority(source, alias, totalShips)

                    -- subtract the reservations from minimumReservations step to calculate prior reservations
                    local shipsReserved = self.mapFuture.reservations:getShipReservations(source) - totalSourceReservations
                    shipsReserved = common_utils.toPrecision(shipsReserved, 5)
                    assert.is_true(shipsReserved >= 0, "ShipsReserved before minimumReservations must be >= 0 but was " .. shipsReserved)
                    local percent = getPercentToUseWithReservation(source, totalShips, shipsReserved)
                    if getAmountSent(source, percent) > 0 then 
                        local desc = "DefendReserve"
                        -- no plan because this is not a multi-turn action
                        local action = Action.newSend(initialPriority, self, desc, {}, {source}, alias, percent)
                        table.insert(candidates, action)
                    end
                end 
            end

        end

        return candidates
    end

    -- introduce various nonlinearities
    -- TODO: instead of target production, sum nearby dist-discounted production.
    function DefendMind:getSendReservationsPriority(source, alias, amountSent)
        local dist = self.mapTunnels:getSimplifiedTunnelDist(source, alias)

        local priority = amountSent ^ self.sendReservationsAmountSentExponent * self.sendReservationsAmountSentFactor
            / dist ^ self.sendReservationsDistDiscountExponent * 50
        priority = priority * self.sendReservationsOverallWeight + self.sendReservationsOverallBias - 1
        priority = priority * self.overallWeight + self.overallBias - 1
        return priority
    end

    function DefendMind:sendTowardsWeak(plans, needs)
        local candidates = {}
        
        local destNeedInfo = self:getDestinationNeedInfo(needs)
        local targetPlanets = common_utils.filter(self:getFriendlyPlanetsAndPlannedCaptures(plans), function(p)
            return destNeedInfo[p.n] ~= nil
        end)
        local sourcePlanets = common_utils.filter(self.map:getPlanetList(self.botUser), function(p)
            local shipsReserved = self.mapFuture.reservations:getShipReservations(p)
            local percent = getPercentToUseWithReservation(p, 10000000, shipsReserved)
            return getAmountSent(p, percent) > 0
        end)

        for _,target in ipairs(targetPlanets) do 
            local totalNeed = destNeedInfo[target.n].totalAmount
            local fullAttackData = self.mapFuture:simulateFullAttack(self.map, self.mapTunnels, self.botUser, target, nil, plans)

            table.sort(sourcePlanets, function (a, b)
                return self.mapTunnels:getSimplifiedTunnelDist(a, target) < self.mapTunnels:getSimplifiedTunnelDist(b, target)
            end)

            for _,source in ipairs(sourcePlanets) do
                local shipsReserved = self.mapFuture.reservations:getShipReservations(source)
                local percent = getPercentToUseWithReservation(source, totalNeed, shipsReserved)
                local amountAvailable = getAmountSent(source, percent)
                
                totalNeed = totalNeed - amountAvailable
                
                local initialPriority = self:getDefendWeakPriority(source, target, amountAvailable, fullAttackData)
                local alias = self.mapTunnels:getTunnelAlias(source, target)
                local desc = "DefendWeak@" .. getPlanetDesc(self.map, self.botUser, target)
                -- no plan because this is not a multi-turn action
                local action = Action.newSend(initialPriority, self, desc, {}, {source}, alias, percent)
                table.insert(candidates, action)

                if totalNeed <= 0 then break end
            end
        end

        return candidates
    end

    -- introduce various nonlinearities 
    -- TODO: instead of target production, sum nearby dist-discounted production.
    function DefendMind:getDefendWeakPriority(source, target, amountSent, fullAttackData)
        local dist = self.mapTunnels:getSimplifiedTunnelDist(source, target)

        -- TODO: someday, create priority object with named components for easier analysis of dominating terms. 
        local priority = self.defendWeakTargetProdFactor * target.production / dist ^ self.defendWeakDistExponent 
        - dist ^ self.defendWeakDistDiscountExponent * self.defendWeakDistDiscount / 100000
        
        -- TODO: removed temporarily because the minimumReservations from prior defense step could bias these calculations unfairly.
        -- priority = priority - fullAttackData.netShips * self.defendWeakNetShips / 2 + fullAttackData.enemyProdFromTarget * self.defendWeakStolenProd

        priority = priority + amountSent ^ self.defendWeakAmountSentExponent * self.defendWeakAmountSentFactor / 10 
        priority = priority * self.defendWeakOverallWeight + self.defendWeakOverallBias - 1
        priority = priority * self.overallWeight + self.overallBias - 1
        return priority
    end

    function DefendMind:gradeAction(action, plans)
 
    end

    return DefendMind
end
DefendMind = _m_init()
_m_init = nil
