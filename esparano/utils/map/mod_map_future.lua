require("mod_common_utils")
require("mod_game_utils")

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

    -- simulate until all fleets landed and last planet has arrived (and prod is felt)
    -- Returns whether the capturingUser owns the planet at end of simulation and the difference in ships at end
    --  negative shipDiff indicates planet was overcome
    --  positive shipDiff but owned = false indicates enemy presence was too strong to capture
    --  positive shipDiff and owned = true indicates that the defense succeeded by "shipDiff" ships
    function MapFuture:simulateAllOutAttack(map, mapTunnels, target, capturingUser)
        -- sort both fleets and planets by tunnel distance to target
        local sourceData = common_utils.map(map:getNonNeutralPlanetAndFleetList(), function (o) 
            local data = {
                source = o,
            }
            if o.is_fleet then
                data.dist = mapTunnels:getApproxFleetTunnelDist(o.n, target.n)
            else
                data.dist = mapTunnels:getSimplifiedTunnelDist(o.n, target.n)
            end
            return data
        end)
        table.sort(sourceData, function (d1, d2) return d1.dist < d2.dist end)

        local lastDist = 0
        local netProdInRadius = 0
        local shipDiff = 0

        local owned = target.owner == capturingUser.n
        local isNeutral = target.neutral
        for _,data in ipairs(sourceData) do 
            local diff = data.dist - lastDist
            lastDist = data.dist
            local timeDiff = game_utils.distToTravelTime(diff)

            -- net-prod within radius has produced some ships in this time
            -- NOTE: assumes that planet does not change hands in this time.
            shipDiff = shipDiff + game_utils.prodToShipsPerSec(netProdInRadius) * timeDiff
            if data.source.is_planet then
                netProdInRadius = netProdInRadius + data.source.production * common_utils.boolToSign(data.source.owner == capturingUser.n)
            end

            -- add arriving ships
            shipDiff = shipDiff + data.source.ships * common_utils.boolToSign(data.source.owner == capturingUser.n)

            -- if target is neutral, can we capture it yet?
            -- note: The enemy doesn't ever capture. It hovers nearby and lands the moment we land.
            if isNeutral then 
                if shipDiff >= target.ships then 
                    shipDiff = shipDiff - target.ships 
                    netProdInRadius = netProdInRadius + target.production
                    owned = true
                    isNeutral = false
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

        return owned, shipDiff
    end

    return MapFuture
end
MapFuture = _module_init()
_module_init = nil
