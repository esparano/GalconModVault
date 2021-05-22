require("mod_common_utils")
require("mod_game_utils")
require("mod_assert")

function _module_init()
    local MapFuture = {}

    local function initPlanetInfo(items)
        local planetInfo = {}
        for _,item in pairs(items) do
            if item.is_planet then 
                planetInfo[item.n] = {
                    netIncomingShips = 0,
                    totalFriendlyIncoming = 0,
                    totalEnemyIncoming = 0
                }
            end
        end
        return planetInfo
    end

    function MapFuture.new(items, botUser)
        local instance = {}
        for k, v in pairs(MapFuture) do
            instance[k] = v
        end

        instance.botUser = botUser
        instance.items = items
        instance.planetInfo = initPlanetInfo(items)
        instance.reservations = {}

        instance:_constructFutures()

        return instance
    end

    function MapFuture:_constructFutures()
        for _,fleet in pairs(self.items) do
            if fleet.is_fleet then 
                local target = self.planetInfo[fleet.target]
                -- TODO: TEST THIS
                if fleet.owner == self.botUser.n then 
                    target.netIncomingShips = target.netIncomingShips + fleet.ships
                    target.totalFriendlyIncoming = target.totalFriendlyIncoming + fleet.ships
                else 
                    target.netIncomingShips = target.netIncomingShips - fleet.ships
                    target.totalEnemyIncoming = target.totalEnemyIncoming + fleet.ships
                end
            end
        end
    end

    -- net incoming ships from all fleets, not counting ships already on the planet
    function MapFuture:getNetIncomingShips(planet)
        return self.planetInfo[planet.n].netIncomingShips
    end

    function MapFuture:getReservations()
        return self.reservations
    end

    function MapFuture:updateReservations(updater, updatee)
        updatee = updatee or self.reservations
        for k,v in pairs(updater) do
            updatee[k] = updatee[k] or 0
            updatee[k] = updatee[k] + v
        end
    end

    function MapFuture:getPlannedCaptureSources(capturePlans, map, excludeTarget)
        local pseudoSources = {}
        for i,p in ipairs(capturePlans) do 
            -- production and cost of neutral excludeTarget is already handled implicitly by simulateFullAttack
            if excludeTarget.n ~= p.data.targetN then
                local target = map._items[p.data.targetN]
                assert.is_true(target.neutral)
                table.insert(pseudoSources, {
                    source = target,
                    dist = p.data.neutralCaptureDist,
                    pseudo = true,
                })
            else
                print('SUCCESSFULLY FILTERED!!!')
                print("capture plans: " .. common_utils.dump(capturePlans))
                print("excludeTarget: " .. excludeTarget.ships)
                -- print("pseudoSources: " .. common_utils.dump(pseudoSources))
            end
        end

        return pseudoSources
    end

    function MapFuture:isTargetPlannedCapture(fleet, capturePlans)
        return common_utils.findFirst(capturePlans, function(p) return p.data.targetN == fleet.target end) ~= nil
    end

    -- simulate until all fleets landed and last planet has arrived (and prod is felt)
    -- Returns whether the capturingUser owns the planet at end of simulation and the difference in ships at end
    -- Also returns the planets/fleets in distance order from the target from the first time a planet either changes hands or finds enemy resistance.
    --  negative shipDiff indicates planet was overcome
    --  positive shipDiff but owned = false indicates enemy presence was too strong to capture
    --  positive shipDiff and owned = true indicates that the defense succeeded by "shipDiff" ships
    function MapFuture:simulateFullAttack(map, mapTunnels, capturingUser, target, reservations, capturePlans)
        reservations = reservations or self.reservations
        capturePlans = capturePlans or {}

        -- sort both fleets and planets by tunnel distance to target
        local sourceData = common_utils.map(map:getNonNeutralPlanetAndFleetList(), function (o)
            local data = {
                source = o,
                pseudo = false,
            }
            if o.is_fleet then
                -- ALWAYS allow enemy to redirect
                -- if a friendly fleet is not headed towards a planned capture, it can redirect if it wants
                if o.owner ~= capturingUser.n or (map._items[o.target].neutral and not self:isTargetPlannedCapture(o, capturePlans)) then
                    -- TODO: discretize into 1/4 second increment buckets?
                    data.dist = mapTunnels:getApproxFleetTunnelDist(o.n, target.n)
                else
                    data.dist = mapTunnels:getApproxFleetTunnelDist(o.n, o.target) + mapTunnels:getSimplifiedTunnelDist(o.target, target.n)
                end
            else
                data.dist = mapTunnels:getSimplifiedTunnelDist(o.n, target.n)
            end
            return data
        end)

        -- pseudo-sources for planned-capture neutrals with new dist based on estimated capture time and then travel time to target
        -- TODO: add "virtual ships" to spend against planned targets; And also convert plans into pseudo-sources. Add estimated capture time to plans.
        local capturedNeutralSourceData = self:getPlannedCaptureSources(capturePlans, map, target)

        sourceData = common_utils.combineLists(sourceData, capturedNeutralSourceData)
        table.sort(sourceData, function (d1, d2) return d1.dist < d2.dist end)

        local lastDist = 0
        local netProdInRadius = 0
        local shipDiff = 0

        local owned = target.owner == capturingUser.n
        local isNeutral = target.neutral

        local neutralCapturingSources = {}
        local neutralCaptureDist
        -- can be used to count "stolen" prod from enemy target, or gained prod for neutral even if recaptured by enemy.
        local friendlyProdFromTarget = 0
        local enemyProdFromTarget = 0
        local newReservations = {}

        for _,data in ipairs(sourceData) do
            assert.is_true(data.dist >= 0, "distance of source in full-attack was negative!")

            local diff = data.dist - lastDist
            assert.is_true(diff >= 0, "distance of source in full-attack was not sorted properly!")
            lastDist = data.dist
            local timeDiff = game_utils.distToTravelTime(diff)

            -- net-prod within radius has produced some ships in this time
            -- NOTE: assumes that planet does not change hands in this time.
            -- TODO: if this production will allow the planet to capture before another planet arrives, suppress sending until planet produces enough to capture.
            -- TODO: if this production allows capture, retroactively determine capture time as (timeDiff - (target.ships + 1 - shipDiff / prod) or whatever it is, then apply
            -- remainder of prod if non-neutral.)
            shipDiff = shipDiff + game_utils.prodToShipsPerSec(netProdInRadius) * timeDiff

            local isFriendly = data.source.owner == capturingUser.n
            if data.source.is_planet then
                -- if the planet is completely unreserved or is not fully reserved, we can use its production (TODO: this underestimates the amount of production we can gain)
                -- if not reservations[data.source.n] or reservations[data.source.n] < data.source.ships then
                    netProdInRadius = netProdInRadius + data.source.production * common_utils.boolToSign(isFriendly or data.pseudo)
                -- end
            end

            if owned then
                friendlyProdFromTarget = friendlyProdFromTarget + game_utils.prodToShipsPerSec(target.production) * timeDiff
            elseif not neutral then 
                enemyProdFromTarget = enemyProdFromTarget + game_utils.prodToShipsPerSec(target.production) * timeDiff
            end

            local contribution = data.source.ships

            -- NOTE: if redirects are not allowed and fleet will land on neutral OTHER than the target, THERE IS NO NEED to  
            -- subtract fleet target's ships from contribution of that fleet, because as part of the plan to capture the fleet's target, the fleet should have already been given
            -- reservations.

            -- add source's ships only if not already reserved
            if reservations[data.source.n] then 
                assert.is_true(isFriendly, "non-friendly planet has reservations")
                assert.is_false(data.pseudo, "pseudo sources should not have reservations!")

                contribution = math.max(0, contribution - reservations[data.source.n])
            end
            -- planned-capture neutrals only contribute production, not ships.
            if data.pseudo then contribution = 0 end
            shipDiff = shipDiff + contribution * common_utils.boolToSign(isFriendly)

            -- if target is neutral, can we capture it yet?
            -- note: The enemy doesn't ever capture. It hovers nearby and lands the moment we land.
            if isNeutral then
                -- NOTE: this may happen even if the current source is ENEMY because + friendly prod - enemy source ships may still be > target.ships.
                local amountNeededToCapture = target.ships + 1
                if shipDiff > amountNeededToCapture then 
                    shipDiff = shipDiff - target.ships
                    netProdInRadius = netProdInRadius + target.production
                    owned = true
                    isNeutral = false
                    neutralCaptureDist = data.dist 

                    -- overcapture by "shipDiff" amount; contribution may be < shipDiff if high friendly prod outweighs enemy source's ships or if source is a planned-capture neutral
                    local capturingSourceShipsNeeded = contribution - shipDiff + 1

                    if isFriendly and capturingSourceShipsNeeded >= 0 then 
                        capturingSourceShipsNeeded = math.max(0, capturingSourceShipsNeeded)
                        newReservations[data.source.n] = capturingSourceShipsNeeded
                        table.insert(neutralCapturingSources, data.source)
                    end
                else
                    -- reserve the entire source towards this plan
                    if isFriendly then
                        newReservations[data.source.n] = contribution
                        table.insert(neutralCapturingSources, data.source)
                    end
                end
            -- has planet changed hands? 
            elseif shipDiff < 0 and owned then 
                owned = false
                netProdInRadius = netProdInRadius - 2 * target.production
            elseif shipDiff > 0 and not owned then 
                owned = true
                netProdInRadius = netProdInRadius + 2 * target.production
            end
        end

        -- if common_utils.round(target.ships) == 77 then 
        --     print(owned, shipDiff, friendlyProdFromTarget, neutralCapturingSources, newReservations)
        -- end

        return owned, shipDiff, friendlyProdFromTarget, enemyProdFromTarget, neutralCapturingSources, newReservations, neutralCaptureDist
    end

    return MapFuture
end
MapFuture = _module_init()
_module_init = nil
