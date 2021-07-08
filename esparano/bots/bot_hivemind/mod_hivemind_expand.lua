require("mod_game_utils")
require("mod_common_utils")
require("mod_set")
require("mod_hivemind_action")
require("mod_hivemind_plan")
require("mod_hivemind_utils")
 
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
        for k,v in pairs(ExpandMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "Expand"

        instance.plannedCapturesData = {}

        return instance
    end

    function ExpandMind:processPlan(plan, confirmedPlans)
        local viable, fullAttackData = self:updatePlannedCapture(plan, confirmedPlans)
        if viable then 
            table.insert(self.plannedCapturesData, fullAttackData)           
        end
        return viable
    end

    -- return whether plan is viable, 
    -- and if viable, returns fullAttackData
    function ExpandMind:updatePlannedCapture(plan, confirmedPlans)
        local target = self.map._items[plan.data.targetN]

        assert.is_true(target.is_planet, "planned expansion target was not a planet!!")

        -- target was already captured
        if not target.neutral then return false end

        -- abandon plan if no longer viable
        logger:trace("examining plan" .. target.ships)
        local viable, fullAttackData = self:isFullAttackViable(target, confirmedPlans)
        logger:trace("finished examining plan")
        if not viable then
            logger:trace("abandoning plan to capture " .. self:getPlanetDesc(target))
            return false 
        end

        -- update estimated distance until capture for this planned target
        plan.data.neutralCaptureDist = fullAttackData.neutralCaptureDist

        self.mapTunnels:setTunnelable(target)
        
        self.mapFuture.reservations:updateShipReservations(fullAttackData.newReservations)

        return true, fullAttackData
    end

    function ExpandMind:suggestActions(plans)
        local candidates = {}

        logger:trace("plans: " .. common_utils.dump(plans))
        -- run this just to better calculate tunnels
        -- TODO: this can lead to situations where the bot sends at a planet and can't actually capture it...
        -- TODO: this also leads to situations where the bot miscounts front planets because a back planet may tunnel through a low-value neutral unplanned for capture (or enemy) instead of a 
        -- planned front planet.
        -- getNeutralsDataWithPositiveRoi(self.map, self.mapTunnels, self.botUser)

        candidates = common_utils.combineLists(candidates, self:suggestFullAttackSafeActions(plans))
        -- TODO: send towards "good" areas, summing prod for each branch/front planet etc.
        -- TODO: shuttle ships towards planets that will be expanded so that we can expand faster if we want? Shuttle ships towards planets that are close to + netShips and good returns/prod?

        return candidates
    end

    function ExpandMind:gradeAction(action, plans)
    end

    ----------------------------------------------------

    -- TODO: performance issues when there are many planets
    function ExpandMind:suggestFullAttackSafeActions(plans)
        local candidates = {}
    
        local safeNeutralData = self:getFullAttackSafeNeutralData(plans)
        -- plannedCaptures were already verified to be full-attack safe.
        safeNeutralData = common_utils.combineLists(safeNeutralData, self.plannedCapturesData)
        -- only send if the neutral won't already be captured by incoming fleets
        safeNeutralData = common_utils.filter(safeNeutralData, function (data) return self:getNetIncomingAndPresentShips(data.target) >= 0 end)  
        
        for i,data in ipairs(safeNeutralData) do         
            local initialPriority = self:getFullAttackSafeCapturePriority(data)

            local isPreplanned = common_utils.findFirst(self.plannedCapturesData, function (p) return p == data end)

            local capturingSource = data.capturingSources[#data.capturingSources]
            -- if there are no capturingSources, this means prod captured, not a friendly source.
            if #data.capturingSources > 0 and capturingSource.is_planet then
                local sourceCaptureDist = self.mapTunnels:getSimplifiedTunnelDist(capturingSource, data.target)
                -- only send if this is the final planet that actually captures the neutral AND the neutral wasn't simply captured later by future prod!
                if sourceCaptureDist == data.neutralCaptureDist then 
                    -- TODO: This just gets the last friendly planet before capture, even if we need to wait for more production to help capture. 
                    -- Instead, we should return whether or not the attack needs to wait for prod or whether an actual planet can send some ships now  
                    local capturingSourceShipsNeeded = data.newReservations[capturingSource.n]
                    if capturingSourceShipsNeeded > 0 or (capturingSourceShipsNeeded == 0 and data.target.ships == 0) then     
                        -- Note: don't use reserved ships because these were already taken into account during the fullAttack calculation. 
                        -- This is likely the source of the reservation in the first place!
                        local percent = game_utils.percentToUse(capturingSource, capturingSourceShipsNeeded)
                        local to = self.mapTunnels:getTunnelAlias(capturingSource, data.target)

                        local sources = {capturingSource}

                        for i,source in ipairs(data.capturingSources) do 

                            if self.settings.multiSelect and source.is_planet and source ~= capturingSource then 
                                local thisTo = self.mapTunnels:getTunnelAlias(source, data.target)

                                -- only add planet to multi-select if it can afford matching sending percentage AFTER taking into account existing reserved ships
                                local thisPercent = game_utils.percentToUse(source, data.newReservations[source.n])
                                if thisPercent >= percent and thisTo.n == to.n then 
                                    table.insert(sources, source)
                                end
                            end
                        end

                        -- figure out how many ships will actually be sent (planets can't send if < 1 full ship)
                        local total = 0
                        for i,source in ipairs(sources) do
                            total = total + getAmountSent(source, percent)
                        end

                        if total >= 1 then 
                            -- add other sources to the plan if they have the same target and can afford the sending (without reservations etc.)

                            local plan
                            -- if plan already exists, no need to add a second plan to capture the same neutral.
                            if not isPreplanned then
                                plan = self:constructPlan(data.target.n, data.neutralCaptureDist)
                            end
                            local desc = isPreplanned and "Planned@" or "New@"
                            local neutralDesc = self:getPlanetDesc(data.target)

                            -- print("sending " .. percent .. " to " .. to.ships .. " which needs " .. capturingSourceShipsNeeded)
                            -- for i,source in ipairs(sources) do
                            --     print("source " .. source.ships)
                            -- end

                            local action = Action.newSend(initialPriority, self, desc .. neutralDesc, {plan}, sources, to, percent)
                            table.insert(candidates, action)
                        end
                    end
                end
            else
                -- TODO: how to redirect fleets to help capture?? check whether fleet has any reservations, if no reservations AND not already headed towards planet, then redirect

                -- we have to wait for a fleet to land before it makes sense to start tunneling ships towards the target
                -- print("capture of " .. data.target.ships .. " already handled by fleet " .. data.capturingSource.ships .. " targeting " .. map._items[data.capturingSource.target].ships)
            end
        end

        return candidates
    end

    -- introduce various nonlinearities 
    function ExpandMind:getFullAttackSafeCapturePriority(data)
        local captureEase = common_utils.clamp(self.fullAttackDiffWeight * data.netShips + 10 - 10 * self.fullAttackDiffIntercept, 
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

        local isPreplanned = common_utils.findFirst(self.plannedCapturesData, function (p) return p == data end)
        local planContinuityBonus = isPreplanned and 15 * self.planContinuityBonus or 0

        local priority = self.fullAttackCaptureEase * captureEase / 10 + planContinuityBonus + gainBonus
        priority = priority * self.overallWeight + self.overallBias - 1
        return priority
    end

    function ExpandMind:constructPlan(targetN, neutralCaptureDist)
        local data = {
            targetN = targetN,
            neutralCaptureDist = neutralCaptureDist,
        }
        return Plan.new(self.name, data)
    end

    function ExpandMind:getFullAttackSafeNeutralData(plans)
        local candidates = common_utils.filter(self.map:getNeutralPlanetList(), function (target) return 
            -- don't attack neutrals that are already planned to be captured
            not common_utils.findFirst(self.plannedCapturesData, function (data) return data.target.n == target.n end)
            -- only send if the neutral won't already be captured by incoming fleets
            and self:getNetIncomingAndPresentShips(target) >= 0 -- TODO: this could lead to bugs where enemy is floating past neutral being expanded to.
        end)
        local safeNeutralData = {}
        for _,target in ipairs(candidates) do
            local viable, fullAttackData = self:isFullAttackViable(target, plans)
            if viable then
                table.insert(safeNeutralData, fullAttackData)
            else
                -- print("is not full attack safe: " .. self:getPlanetDesc(fullAttackData.target))
            end
        end 
        return safeNeutralData
    end

    -- TODO: if fleet is headed towards planned capture, past another planned capture and it can tunnel through second planned capture, redirect? Make sure ships headed to neutral
    -- are counted properly in planning of capture of first neutral.
    -- TODO: discount certain planets completely from expansion consideration using some quick-and-dirty method for optimization purposes?

    -- TODO: This does not capture the case where a front planet (or this planet) falls briefly, causing others to also fall in a chain reaction.
    -- if planet is owned at end, OR if planet is lost but recovers twice its cost by the time the enemy arrives 
    -- (2x cost because of friendly investment plus the enemy doesn't need to invest anymore)
    function ExpandMind:isFullAttackViable(target, plans)
        local neutralAttackData = self:getFullAttackData(target, self.mapTunnels, nil, plans)
        
        logger:trace(common_utils.dump(neutralAttackData))

        -- case 1: owns planet at end, but had to pay cost of neutral, and bot and enemy produced some ships. Diff in produced ships must be > cost.
        -- case 2: DOES NOT own planet at end, but had to pay cost of neutral, and bot and enemy produced some ships, AND enemy doesn't have to pay cost.
        -- Diff in produced ships must be > 2 * cost.
        -- TODO: make this trainable.
        -- local netShipsMinusCost = (neutralAttackData.friendlyProdFromTarget - neutralAttackData.enemyProdFromTarget) - neutralAttackData.target.ships
        -- local safe = neutralAttackData.ownsPlanetAtEnd and netShipsMinusCost > 0 or netShipsMinusCost > neutralAttackData.target.ships
        -- TODO: This is overly cautious!! If planet is lost to enemy very briefly but regained, it can still be worth taking.
        local safe = neutralAttackData.ownsPlanetAtEnd and neutralAttackData.enemyProdFromTarget == 0
        if not safe then return false end

        local totalReservations = self.mapFuture.reservations:copy()
        totalReservations:updateShipReservations(neutralAttackData.noEnemyReservations)    
        
        assert.is_true(target.neutral, "target was not neutral!!")
        local updatedMapTunnels = common_utils.copy(self.mapTunnels)
        assert.is_false(updatedMapTunnels:isTunnelable(neutralAttackData.target), "planet should not be tunnelable at this point!")
        updatedMapTunnels:setTunnelable(neutralAttackData.target)
        assert.is_false(self.mapTunnels:isTunnelable(neutralAttackData.target), "updating hypothetical mapTunnels updated real mapTunnels!")

        local friendlyPlannedCapturesSet = Set.new({neutralAttackData.target.n})
        local frontPlanets = updatedMapTunnels:getFrontPlanets(self.botUser, friendlyPlannedCapturesSet)

        local plansIncludingNeutral = common_utils.copy(plans)
        table.insert(plansIncludingNeutral, self:constructPlan(neutralAttackData.target.n, neutralAttackData.noEnemyNeutralCaptureDist))

        -- NOTE: These calculations assume that the enemy does not attempt to capture the neutral we just tested during a full-attack of another front planet.
        -- if we reserve ships to attack the neutral planet, will we lose a front planet in a full attack?
        for i,p in ipairs(frontPlanets) do
            -- if the neutral IS a front planet, don't full-attack-test it a second time.
            if p.n ~= neutralAttackData.target.n then
                local frontAttackData = self:getFullAttackData(p, updatedMapTunnels, totalReservations, plansIncludingNeutral)
                -- TODO: this could be overly cautious. Sometimes you still want to expand despite not owning a planet at the end, \
                -- for example, if the prod gained by the neutral is greater than the sum of lost prod from lost front planets.

                -- planet was assumed to be owned during previous calculation, so subtract double the enemy's stolen prod (enemy gained + bot lost)
                -- netShipsMinusCost = netShipsMinusCost - 2 * frontAttackData.enemyProdFromTarget
                -- local safe = frontAttackData.owns PlanetAtEnd and netShipsMinusCost > 0 or netShipsMinusCost > neutralAttackData.target.ships
                 -- TODO: THIS IS OVERLY CAUTIOUS AND WON'T WORK AGAINST FLOATING OR CAPTURING ENEMY PLANETS
                local safe = frontAttackData.ownsPlanetAtEnd and frontAttackData.enemyProdFromTarget == 0
                if not safe then
                    local neutralDesc = self:getPlanetDesc(neutralAttackData.target)
                    local frontDesc = self:getPlanetDesc(frontAttackData.target)
                    logger:trace(frontDesc .. " is vulnerable by " .. frontAttackData.netShips .. " if expanding to " .. neutralDesc)
                    return false
                end
            end
        end

        -- TODO: have enemy fullAttack all neutrals with better ship/cost than this neutral before and after reserving for this expansion.
        -- If the enemy is now able to capture any more efficient neutral as a result of this expansion, DO NOT EXPAND. This is the crucial minimax aspect of expansion.

        return true, neutralAttackData
    end

    function ExpandMind:getPlanetDesc(p)
        return getPlanetDesc(self.map, self.botUser, p)
    end

    function ExpandMind:getFullAttackData(target, mapTunnels, reservations, capturePlans)
        return self.mapFuture:simulateFullAttack(self.map, mapTunnels, self.botUser, target, reservations, capturePlans)
    end

    function ExpandMind:getNetIncomingAndPresentShips(p)
        return getNetIncomingAndPresentShips(self.mapFuture, p)
    end

    return ExpandMind
end
ExpandMind = _m_init()
_m_init = nil
