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
        for k, v in pairs(ExpandMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "Expand"

        instance.plannedCapturesData = {}

        return instance
    end

    function ExpandMind:processPlan(plan)
        local satisfied, fullAttackData = self:updatePlannedCapture(plan.data.targetN)
        if satisfied then 
            plan.satisfied = true
        else
            table.insert(self.plannedCapturesData, fullAttackData)
        end
    end

    -- TODO: shuttle ships towards planets that will be expanded so that we can expand faster if we want? Shuttle ships towards planets that are close to + shipdiff and good returns/prod?

    -- return whether plan is satisfied already, 
    -- and if not satisfied yet, returns fullAttackData
    function ExpandMind:updatePlannedCapture(targetN)
        local target = self.map._items[targetN]

        assert.is_true(target.is_planet, "planned expansion target was not a planet!!")

        -- target was already captured
        if not target.neutral then return true end

        local fullAttackData = self:getFullAttackData(target)

        -- abandon plan if no longer viable
        if not self:isFullAttackViable(fullAttackData) then 
            print("abandoning plan to capture " .. self:getNeutralDesc(fullAttackData.target))
            return true 
        end

        self.mapTunnels:setTunnelable(target)

        self.mapFuture:updateReservations(fullAttackData.newReservations)

        return false, fullAttackData
    end

    function ExpandMind:suggestActions(plans)
        local candidates = {}

        -- run this just to better calculate tunnels
        -- TODO: this can lead to situations where the bot sends at a planet and can't actually capture it...
        -- TODO: this also leads to situatiosn where the bot miscounts front planets because a back planet may tunnel through a low-value neutral unplanned for capture (or enemy) instead of a 
        -- planned front planet.
        -- getNeutralsDataWithPositiveRoi(self.map, self.mapTunnels, self.botUser)

        candidates = common_utils.combineLists(candidates, self:suggestFullAttackSafeActions())
        -- TODO: send towards "good" areas, summing prod for each branch/front planet etc.

        return candidates
    end

    function ExpandMind:gradeAction(action, plans)
    end

    ----------------------------------------------------

    -- TODO: performance issues when there are many planets
    function ExpandMind:suggestFullAttackSafeActions()
        local candidates = {}
    
        local safeNeutralData = self:getFullAttackSafeNeutralData()
        -- plannedCaptures were already verified to be full-attack safe.
        safeNeutralData = common_utils.combineLists(safeNeutralData, self.plannedCapturesData)
        -- only send if the neutral won't already be captured by incoming fleets
        safeNeutralData = common_utils.filter(safeNeutralData, function (data) return self:getNetIncomingAndPresentShips(data.target) >= 0 end)  
        
        for i,data in ipairs(safeNeutralData) do         
            local initialPriority = self:getFullAttackSafeCapturePriority(data)

            local isPreplanned = common_utils.findFirst(self.plannedCapturesData, function (p) return p == data end)

            local capturingSource = data.capturingSources[#data.capturingSources]
            if capturingSource.is_planet then
                -- TODO: This just gets the last friendly planet before capture, even if we need to wait for more production to help capture. 
                -- Instead, we should return whether or not the attack needs to wait for prod or whether an actual planet can send some ships now  
                local capturingSourceShipsNeeded = data.newReservations[capturingSource.n]
                if capturingSourceShipsNeeded > 0 or (capturingSourceShipsNeeded == 0 and data.target.ships == 0) then 
                    
                    local percent = game_utils.percentToUse(capturingSource, capturingSourceShipsNeeded)
                    local to = self.mapTunnels:getTunnelAlias(capturingSource.n, data.target.n)

                    local sources = {capturingSource}

                    for i,source in ipairs(data.capturingSources) do 
                        if self.settings.multiSelect and source.is_planet and source ~= capturingSource then 
                            local thisPercent = game_utils.percentToUse(source, data.newReservations[source.n])
                            local thisTo = self.mapTunnels:getTunnelAlias(source.n, data.target.n)
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
                            plan = self:constructPlan(data.target)
                        end
                        local desc = isPreplanned and "Planned@" or "New@"
                        local neutralDesc = self:getNeutralDesc(data.target)

                        -- print("sending " .. percent .. " to " .. to.ships .. " which needs " .. capturingSourceShipsNeeded)
                        -- for i,source in ipairs(sources) do 
                        --     print("source " .. source.ships)
                        -- end

                        local action = Action.newSend(initialPriority, self, desc .. neutralDesc, {plan}, sources, to, percent)
                        table.insert(candidates, action)
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

        local isPreplanned = common_utils.findFirst(self.plannedCapturesData, function (p) return p == data end)
        local planContinuityBonus = isPreplanned and 15 * self.planContinuityBonus or 0

        local initialPriority = self.fullAttackCaptureEase * captureEase / 10 + planContinuityBonus + gainBonus
        initialPriority = initialPriority * self.fullAttackOverallWeight
        return initialPriority
    end

    function ExpandMind:constructPlan(target)
        local data = {targetN = target.n}
        return Plan.new(self.name, data)
    end

    function ExpandMind:getFullAttackSafeNeutralData()
        local candidates = common_utils.filter(self.map:getNeutralPlanetList(), function (target) return 
            -- don't attack neutrals that are already planned to be captured
            not common_utils.findFirst(self.plannedCapturesData, function (data) return data.target.n == target.n end)
            -- only send if the neutral won't already be captured by incoming fleets
            and self:getNetIncomingAndPresentShips(target) >= 0
        end)
        local safeNeutralData = {}
        for _,target in ipairs(candidates) do
            local fullAttackData = self:getFullAttackData(target)
            if self:isFullAttackViable(fullAttackData) then
                table.insert(safeNeutralData, fullAttackData)
            else
                -- print("is not full attack safe: " .. getNeutralDesc(self.map, self.mapTunnels, self.botUser, fullAttackData.target))
            end
        end 
        return safeNeutralData
    end

    -- TODO: discount certain planets completely using some quick-and-dirty method for optimization purposes?

    -- if planet is owned at end, OR if planet is lost but recovers twice its cost by the time the enemy arrives 
    -- (2x cost because of friendly investment plus the enemy doesn't need to invest anymore)
    function ExpandMind:isFullAttackViable(neutralAttackData)
        local safe = neutralAttackData.ownsPlanetAtEnd or neutralAttackData.friendlyProdFromTarget > 2 * neutralAttackData.target.ships
        if not safe then return false end

        print("isFullAttackViable: " .. neutralAttackData.target.ships)
        -- TODO: neutrals to-be-captured are not included in prod for full-attack calculations :(

        local totalReservations = common_utils.copy(self.mapFuture:getReservations())
        self.mapFuture:updateReservations(neutralAttackData.newReservations, totalReservations)

        -- if we reserve ships to attack the neutral planet, will we lose a front planet in a full attack?
        local friendlyPlannedCapturesSet = Set.new({neutralAttackData.target.n})
        -- TODO: wrong front planets???
        local frontPlanets = self.mapTunnels:getFrontPlanets(self.botUser, friendlyPlannedCapturesSet)

        for i,p in ipairs(frontPlanets) do
            -- if the neutral IS a front planet, don't full-attack-test it a second time.
            if p.n ~= neutralAttackData.target.n then 
                local frontAttackData = self:getFullAttackData(p, totalReservations)
                -- TODO: this could be overly cautious. Sometimes you still want to expand despite not owning a planet at the end, \
                -- for example, if the prod gained by the neutral is greater than the sum of lost prod from lost front planets.
                if not frontAttackData.ownsPlanetAtEnd then 
                    local neutralDesc = self:getNeutralDesc(neutralAttackData.target)
                    local frontDesc = self:getNeutralDesc(frontAttackData.target)
                    print(frontDesc .. " is vulnerable by " .. frontAttackData.shipDiff .. " if expanding to " .. neutralDesc)
                    return false
                end 
            end
        end 

        return true
    end

    function ExpandMind:getNeutralDesc(p)
        return getNeutralDesc(self.map, self.mapTunnels, self.botUser, p)
    end

    function ExpandMind:getFullAttackData(target, reservations)
        return getFullAttackData(self.map, self.mapTunnels, self.mapFuture, self.botUser, target, reservations)
    end

    function ExpandMind:getNetIncomingAndPresentShips(p)
        return getNetIncomingAndPresentShips(self.mapFuture, p)
    end

    

    return ExpandMind
end
ExpandMind = _m_init()
_m_init = nil
