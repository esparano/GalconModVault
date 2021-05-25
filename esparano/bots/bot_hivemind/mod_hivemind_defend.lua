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

        local needs = self:reserveMinimum(plans)

        candidates = common_utils.combineLists(candidates, self:sendTowardsWeak(plans))

        return candidates
    end

    -- for testing purposes, use Sparky's method of reservation. (some % to target, distribute rest to nearest planets to fleet)
    function DefendMind:reserveMinimum(plans)
        local enemyUser = self.map:getEnemyUser(self.botUser)

        local newReservations = {}

        for i,fleet in ipairs(self.map:getFleetList(enemyUser)) do 
            local target = self.map._items[fleet.target]
            local totalToReserve = fleet.ships 

            -- TODO: +1 only if fleet is within certain range
            -- TODO: back to +1 when it is figurd out why the bot messes up sometimes.
            -- +1 so it's not cutting it so close
            -- TODO: ONLY add a +1 ONCE to each planet to make sure it has enough. It doesn't need a +1 for each incoming fleet.
            local targetToReserve = totalToReserve
            
            -- TODO: Planet's production is wrongly being double, triple+ counted for each fleet incoming. -- USE SEED 817
            local newTargetReservation, overflow = self:getAmountToReserve(fleet, target, targetToReserve, newReservations)
            if target.owner == self.botUser.n then
                newReservations[target.n] = newReservations[target.n] or 0
                newReservations[target.n] = newReservations[target.n] + newTargetReservation
            else 
                assert.is_true(newTargetReservation == 0, "non-owned planets cannot have reservations!")
                assert.is_true(overflow == targetToReserve, "the entire targetToReserve must overflow if target is not owned")
            end

            local nearbyToReserve = math.max(0, totalToReserve - targetToReserve + overflow)

            -- TODO: check for any instances of memoized stuff being sorted which modifies for future users??
            local closestPlanets = self.map:getPlanetList(self.botUser)
            -- TODO: reserve from nearest planets?
        end

        self.mapFuture.reservations:updateShipReservations(newReservations)
    end

    -- returns amount actually needed for reservation by target (+ prod) and amount of desiredReservation that was unable to be covered by target (+ prod)
    -- TODO: amount covered by prod (and amount of reservation) makes an assumption that the amount that was unable to be reserved can actually make it to another planet in time.
    -- This may not be the case if the fleet is closer to the other planet being considered than this target is.
    function DefendMind:getAmountToReserve(attackingFleet, target, desiredReservation, additionalReservations)
        if target.owner ~= self.botUser.n then return 0, desiredReservation end

        local fleetDirectDist = self.mapTunnels:getApproxFleetDirectDist(attackingFleet, target)
        local prodTime = game_utils.distToTravelTime(fleetDirectDist)
        local producedDuringFlight = game_utils.calcShipsProducedNonNeutral(target, prodTime)
        
        local existingReservations = self.mapFuture.reservations:getShipReservations(target)
        local newReservations = additionalReservations[target.n] or 0
        local totalReservation = existingReservations + newReservations

        local available = target.ships + producedDuringFlight - totalReservation
        
        if available >= desiredReservation then return desiredReservation, 0 end

        local amountUncovered = desiredReservation - available 
        return available, amountUncovered
    end

    function DefendMind:sendTowardsWeak(plans)
        return {}
    end

    -- TODO: figure out how to deal with expansion logic while defending???
    function DefendMind:gradeAction(action, plans)

    end

    return DefendMind
end
DefendMind = _m_init()
_m_init = nil
