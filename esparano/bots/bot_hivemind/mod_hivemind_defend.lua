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

    -- for testing purposes, use Sparky's method of reservation.
    function DefendMind:reserveMinimum(plans)
        local enemyUser = self.map:getEnemyUser(self.botUser)

        local newReservations = {}

        for i,fleet in ipairs(self.map:getFleetList(enemyUser)) do 
            local target = self.map._items[fleet.target]
            local totalToReserve = fleet.ships 

            -- TODO: +1 only if fleet is within certain range
            -- TODO: back to +1 when it is figurd out why the bot messes up sometimes.
            -- +1 so it's not cutting it so close
            local targetReservation = totalToReserve + 2
            
            -- TODO: Planet's production is wrongly being double, triple+ counted for each fleet incoming.
            local newTargetReservation, overflow = self:getAmountToReserve(fleet, target, targetReservation, newReservations)
            if target.owner == self.botUser.n then
                newReservations[target.n] = newReservations[target.n] or 0
                newReservations[target.n] = newReservations[target.n] + newTargetReservation
            else 
                assert.is_true(newTargetReservation == 0, "non-owned planets cannot have reservations!")
                assert.is_true(overflow == targetReservation, "the entire targetReservation must overflow if target is not owned")
            end

            local nearbyReservation = totalToReserve - newTargetReservation

            -- TODO: check for any instances of memoized stuff being sorted which modifies for future users??
            local closestPlanets = self.map:getPlanetList(self.botUser)
            -- TODO: reserve from nearest planets?
        end

        self.mapFuture:updateReservations(newReservations)
    end

    -- returns amount actually needed for reservation by target (+ prod) and amount of desiredReservation that was unable to be covered by target (+ prod)
    function DefendMind:getAmountToReserve(attackingFleet, target, desiredReservation, additionalReservations)
        if target.owner ~= self.botUser.n then return 0, desiredReservation end

        local fleetDirectDist = self.mapTunnels:getApproxFleetDirectDist(attackingFleet, target)
        local prodTime = game_utils.distToTravelTime(fleetDirectDist)
        local producedDuringFlight = game_utils.calcShipsProducedNonNeutral(target, prodTime)
        
        -- planet should leave 1 ship minimum so it doesn't cut it so close
        if producedDuringFlight >= desiredReservation then return 0, 0 end
        local amountLeftAfterProd = desiredReservation - producedDuringFlight

        local existingReservations = self.mapFuture:getReservations()[target.n] or 0
        local newReservations = additionalReservations[target.n] or 0
        local totalReservation = existingReservations + newReservations
        local available = target.ships - totalReservation
        assert.is_true(available >= 0, "ship reservations were greater than target has ships!")

        if available >= amountLeftAfterProd then return amountLeftAfterProd, 0 end

        local amountUncovered = amountLeftAfterProd - available 
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
