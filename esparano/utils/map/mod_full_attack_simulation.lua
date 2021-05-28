require("mod_common_utils")
require("mod_game_utils")
require("mod_assert")

function _module_init()
    local FullAttackSimulation = {}

    function FullAttackSimulation.new(map, mapTunnels, capturingUserId, targetId, reservations, capturePlans)
        local instance = {}
        for k, v in pairs(FullAttackSimulation) do
            instance[k] = v
        end

        -- injected dependencies
        targetId = game_utils.toId(targetId)
        instance.attackTarget = map._items[targetId]
        instance.map = map
        instance.mapTunnels = mapTunnels
        instance.capturingUserId = game_utils.toId(capturingUserId)
        instance.reservations = reservations
        instance.capturePlans = capturePlans or {}

        -- member variables
        instance.owned = instance.attackTarget.owner == instance.capturingUserId
        instance.isNeutral = instance.attackTarget.neutral
        instance.lastDist = 0
        instance.netProdInRadius = 0
        instance.netShips = 0
        instance.neutralCapturingSources = {}
        -- only set if the attackTarget is a neutral and was captured
        instance.neutralCaptureDist = nil
        -- can be used to count "stolen" prod from enemy, or gained prod for neutral even if recaptured by enemy.
        instance.friendlyProdFromTarget = 0
        instance.enemyProdFromTarget = 0
        instance.newReservations = {}
        instance.totalFriendlyShips = 0

        instance.MAX_TIMESTEP = 1

        return instance
    end

    -- simulate until all fleets landed and last planet has arrived (and prod is felt)
    -- Returns whether the capturingUser owns the planet at end of simulation and the difference in ships at end
    -- Also returns the planets/fleets in distance order from the target from the first time a planet either changes hands or finds enemy resistance.
    --  negative netShips indicates planet was overcome
    --  positive netShips but owned = false indicates enemy presence was too strong to capture
    --  positive netShips and owned = true indicates that the defense succeeded by "netShips" ships
    function FullAttackSimulation:getResults()
        self.results = self.results or self:_simulateFullAttack()
        return self.results
    end

    -- TODO: add pseudo sources as simply neutral ships with prod before capture time completely reserved!
    function FullAttackSimulation:_getPlannedCaptureSources()
        local excludeTargetId = game_utils.toId(self.attackTarget)
        local pseudoSources = {}
        for i,p in ipairs(self.capturePlans) do 
            -- production and cost of neutral excludeTarget is already handled implicitly by simulateFullAttack
            if excludeTargetId ~= p.data.targetN then
                local fleetTarget = self.map._items[p.data.targetN]
                assert.is_true(fleetTarget.neutral)
                table.insert(pseudoSources, {
                    source = fleetTarget,
                    dist = p.data.neutralCaptureDist,
                    pseudo = true,
                })
            end
        end

        return pseudoSources
    end

    function FullAttackSimulation:_isTargetPlannedCapture(fleet)
        return common_utils.findFirst(self.capturePlans, function(p) return p.data.targetN == fleet.target end) ~= nil
    end

    -- sort both fleets and planets by tunnel distance to attackTarget and return related info
    function FullAttackSimulation:_getDistSortedShipSources()
        return common_utils.map(self.map:getNonNeutralPlanetAndFleetList(), function (o)
            local data = {
                source = o,
                pseudo = false,
            }
            if o.is_fleet then
                -- ALWAYS allow enemy to redirect
                -- if a friendly fleet is not headed towards a planned capture, it can redirect if it wants
                if o.owner ~= self.capturingUserId or (self.map._items[o.target].neutral and not self:_isTargetPlannedCapture(o)) then
                    -- TODO: discretize into 1/4 second increment buckets?
                    data.dist = self.mapTunnels:getApproxFleetTunnelDist(o, self.attackTarget)
                else
                    data.dist = self.mapTunnels:getApproxFleetTunnelDist(o, o.target) + self.mapTunnels:getSimplifiedTunnelDist(o.target, self.attackTarget)
                end
            else
                data.dist = self.mapTunnels:getSimplifiedTunnelDist(o, self.attackTarget)
            end
            return data
        end)
    end

    function FullAttackSimulation:_getNeutralCaptureThreshold()
        return self.attackTarget.ships + 1
    end

    function FullAttackSimulation:_detectCapture(data, dist, contribution)
        -- if target is neutral, can we capture it yet?
        -- note: The enemy doesn't ever capture. It hovers nearby and lands the moment we land.
        if self.isNeutral then
            -- NOTE: this may happen even if the current source is ENEMY because + friendly prod - enemy source ships may still be > target.ships.
            local amountNeededToCapture = self:_getNeutralCaptureThreshold()
            if self.netShips > amountNeededToCapture then 
                local overcapture = self.netShips - amountNeededToCapture
                self.netShips = self.netShips - self.attackTarget.ships
                self.netProdInRadius = self.netProdInRadius + self.attackTarget.production
                self.owned = true
                self.isNeutral = false
                self.neutralCaptureDist = dist

                -- only add capturing source if a data source captured, not prod.
                if data then
                    -- only reserve what we really need from this capturing source
                    local capturingSourceShipsNeeded = contribution - overcapture

                    local isFriendly = data.source.owner == self.capturingUserId
                    if isFriendly and capturingSourceShipsNeeded >= 0 then 
                        capturingSourceShipsNeeded = math.max(0, capturingSourceShipsNeeded)
                        self.newReservations[data.source.n] = capturingSourceShipsNeeded
                        table.insert(self.neutralCapturingSources, data.source)
                    end
                end
            elseif data then 
                -- reserve the entire source towards this plan
                local isFriendly = data.source.owner == self.capturingUserId
                if isFriendly then
                    self.newReservations[data.source.n] = contribution
                    table.insert(self.neutralCapturingSources, data.source)
                end
            end
        -- has planet changed hands? 
        elseif self.netShips < 0 and self.owned then 
            self.owned = false
            self.netProdInRadius = self.netProdInRadius - 2 * self.attackTarget.production
        elseif self.netShips > 0 and not self.owned then 
            self.owned = true
            self.netProdInRadius = self.netProdInRadius + 2 * self.attackTarget.production
        end
    end

    -- NOTE: assumes that planet does not change hands in this time.
    function FullAttackSimulation:_advanceProductionWithNoCapture(data, timeDiff)
        self.netShips = self.netShips + game_utils.prodToShipsPerSec(self.netProdInRadius) * timeDiff

        if self.owned then
            self.friendlyProdFromTarget = self.friendlyProdFromTarget + game_utils.prodToShipsPerSec(self.attackTarget.production) * timeDiff
        elseif not neutral then 
            self.enemyProdFromTarget = self.enemyProdFromTarget + game_utils.prodToShipsPerSec(self.attackTarget.production) * timeDiff
        end
    end

    function FullAttackSimulation:_advanceProduction(data, timeDiff)
        if timeDiff == 0 then return end
        local prodAssumingNoCapture = game_utils.prodToShipsPerSec(self.netProdInRadius) * timeDiff
        local newNetShips = self.netShips + prodAssumingNoCapture

        local netShipsCaptureThreshold = 0
        if self.isNeutral then netShipsCaptureThreshold = self:_getNeutralCaptureThreshold() end

        -- predict whether a capture will occur due to this production
        if self.netShips < netShipsCaptureThreshold and newNetShips > netShipsCaptureThreshold or 
            self.netShips > netShipsCaptureThreshold and newNetShips < netShipsCaptureThreshold then 
            assert.is_false(self.isNeutral and newNetShips < netShipsCaptureThreshold, "Cannot uncapture neutral!!")

            local timeOfCapture = timeDiff * (netShipsCaptureThreshold - self.netShips) / prodAssumingNoCapture
            assert.is_true(timeOfCapture >= 0, "timeOfCapture must be non-negative!")
            timeOfCapture = timeOfCapture + 0.00001 -- slightly more to make sure capture works

            -- advance until just after we predict the capture will occur
            self:_advanceProductionWithNoCapture(data, timeOfCapture)

            -- Detect capture, updating prod and ownership, etc.
            -- Note: capture occured due to production BEFORE "data", so subtract dist until timeOfCapture
            local distOfCapture = data.dist - game_utils.travelTimeToDist(timeDiff - timeOfCapture)
            local prodBefore = self.netProdInRadius
            local ownedBefore = self.owned
            self:_detectCapture(nil, distOfCapture, 0)
            assert.not_equals(prodBefore, self.netProdInRadius, "Capture should have modified prod!")
            assert.not_equals(ownedBefore, self.owned, "Capture should have modified ownership!")

            self:_advanceProductionWithNoCapture(data, timeDiff - timeOfCapture)
        else
            self:_advanceProductionWithNoCapture(data, timeDiff)
        end
    end

    function FullAttackSimulation:_nextSource(data)
        assert.is_true(data.dist >= 0, "distance of source in full-attack was negative!")

        local diff = data.dist - self.lastDist
        assert.is_true(diff >= 0, "distance of source in full-attack was not sorted properly!")
        self.lastDist = data.dist
        local timeDiff = game_utils.distToTravelTime(diff)

        self:_advanceProduction(data, timeDiff)
            
        -- update production
        local isFriendly = data.source.owner == self.capturingUserId
        if data.source.is_planet then
            self.netProdInRadius = self.netProdInRadius + data.source.production * common_utils.boolToSign(isFriendly or data.pseudo)
        end

        -- land all unreserved ships from source
        local contribution = math.max(0, data.source.ships - self.reservations:getShipReservations(data.source))
        if self.reservations:getShipReservations(data.source) > 0 then 
            assert.is_true(isFriendly, "non-friendly planet has reservations")
            assert.is_false(data.pseudo, "pseudo sources should not have reservations!")
        end

        -- NOTE: if redirects are not allowed and fleet will land on neutral OTHER than the target, THERE IS NO NEED to  
        -- subtract fleet target's ships from contribution of that fleet, because as part of the plan to capture the fleet's target, the fleet should have already been given
        -- reservations.

        -- planned-capture neutrals only contribute production, not ships.
        if data.pseudo then contribution = 0 end

        self.netShips = self.netShips + contribution * common_utils.boolToSign(isFriendly)
        self:_detectCapture(data, data.dist, contribution)
    end

    function FullAttackSimulation:_simulateFullAttack()
        local sourceData = self:_getDistSortedShipSources()
        -- pseudo-sources for planned-capture neutrals with new dist based on estimated capture time and then travel time to target
        local capturedNeutralSourceData = self:_getPlannedCaptureSources()
        sourceData = common_utils.combineLists(sourceData, capturedNeutralSourceData)

        table.sort(sourceData, function (d1, d2) return d1.dist < d2.dist end)

        for _,data in ipairs(sourceData) do
            self:_nextSource(data)
        end

        return {
            target = self.attackTarget,
            ownsPlanetAtEnd = self.owned, 
            netShips = self:_getNetShips(), 
            friendlyProdFromTarget = self.friendlyProdFromTarget, 
            enemyProdFromTarget = self.enemyProdFromTarget, 
            capturingSources = self.neutralCapturingSources, 
            newReservations = self.newReservations,
            neutralCaptureDist = self.neutralCaptureDist,
        }
    end

    return FullAttackSimulation
end
FullAttackSimulation = _module_init()
_module_init = nil
