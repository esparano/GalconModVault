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

        candidates = common_utils.combineLists(candidates, self:sendTowardsWeak(plans, needs))

        return candidates
    end

    -- for testing purposes, use Sparky's method of reservation. (some % to target, distribute rest to nearest planets to fleet)
    function DefendMind:reserveMinimum(plans)
        local needs = {}
        local enemyUser = self.map:getEnemyUser(self.botUser)

        -- add +1 ships to total reservation of each attacked planet (only once per planet) so it's not cutting it so close
        local targetExtraDefenseSet = Set.new()
        for i,fleet in ipairs(self.map:getFleetList(enemyUser)) do 
            local target = self.map._items[fleet.target]
            local totalToReserve = fleet.ships 
            -- logger:debug("processing target " .. totalToReserve)
            if not targetExtraDefenseSet:contains(target.n) then 
                totalToReserve = totalToReserve + 1
                targetExtraDefenseSet:add(target.n)
            end

            local targetToReserve = 0
            -- TODO: reserve prod on planned-capture neutrals
            if target.owner == self.botUser.n then
                local desiredTargetReservation = totalToReserve / 1 -- TODO: update fraction to be configurable

                local overflow = self:reserveNearbyProdThenShips(fleet, target, desiredTargetReservation)
                if overflow > 0 then
                    logger:debug("could not reserve: " .. overflow)
                    table.insert(needs, {
                        need = overflow,
                        p = target,
                        attacker = fleet,
                    })
                end
                targetToReserve = desiredTargetReservation - overflow
            end
            
            local nearbyToReserve = math.max(0, totalToReserve - targetToReserve)

            -- TODO: reserve from nearest planets?
            -- TODO: check for any instances of memoized stuff being sorted which modifies for future users??
            -- local closestPlanets = self.map:getPlanetList(self.botUser)
        
        end

        for i,p in ipairs(self.map:getPlanetList(self.botUser)) do 

        end

        return needs
    end

    -- first, reserve future prod from all friendly planets closer to the target than the fleet is.
    -- Then, reserve ships on the target planet if needed.
    -- TODO: reserve planned-neutral prods too.
    function DefendMind:reserveNearbyProdThenShips(attackingFleet, target, amountToReserve)
        assert.is_true(target.owner == self.botUser.n, "Cannot reserve ships on planet not owned by user!")

        local fleetDirectDist = self.mapTunnels:getApproxFleetDirectDist(attackingFleet, target)
        local arrivalTime = game_utils.distToTravelTime(fleetDirectDist)

        logger:trace("arrivalTime: " .. arrivalTime)

        local ownedPlanets = self.map:getPlanetList(self.botUser)
        table.sort(ownedPlanets, function(a,b)
            return self.mapTunnels:getSimplifiedTunnelDist(a, target) < self.mapTunnels:getSimplifiedTunnelDist(b, target)
        end)
        for i,p in ipairs(ownedPlanets) do
            if self.mapTunnels:getSimplifiedTunnelDist(p, target) > fleetDirectDist then break end
            amountToReserve = amountToReserve - self.mapFuture.reservations:reserveFutureProd(p, arrivalTime, amountToReserve)
        end
        logger:trace("arrivalTime: " .. arrivalTime)

        amountToReserve = amountToReserve - self.mapFuture.reservations:reserveShips(target, amountToReserve)

        return common_utils.toPrecision(amountToReserve, 5)
    end

    function DefendMind:sendTowardsWeak(plans, needs)
        return {}
    end

    -- TODO: figure out how to deal with expansion logic while defending???
    function DefendMind:gradeAction(action, plans)

    end

    return DefendMind
end
DefendMind = _m_init()
_m_init = nil
