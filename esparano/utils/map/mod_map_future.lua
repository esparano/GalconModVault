require("mod_common_utils")
require("mod_game_utils")
require("mod_assert")
require("mod_map_reservations")
require("mod_full_attack_simulation")

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
        instance.reservations = MapReservations.new(items)

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
    function MapFuture:getNetIncomingShips(planetId)
        planetId = game_utils.toId(planetId)
        return self.planetInfo[planetId].netIncomingShips
    end

    -- simulate until all fleets landed and last planet has arrived (and prod is felt)
    -- Returns whether the capturingUser owns the planet at end of simulation and the difference in ships at end
    -- Also returns the planets/fleets in distance order from the target from the first time a planet either changes hands or finds enemy resistance.
    --  negative netShips indicates planet was overcome
    --  positive netShips but owned = false indicates enemy presence was too strong to capture
    --  positive netShips and owned = true indicates that the defense succeeded by "netShips" ships
    function MapFuture:simulateFullAttack(map, mapTunnels, capturingUser, targetId, reservations, capturePlans)
        -- TODO: redo using future prod reservations??
        reservations = reservations or self.reservations

        local fullAttackSim = FullAttackSimulation.new(map, mapTunnels, capturingUser, targetId, reservations, capturePlans)
        local results = fullAttackSim:getResults()
        return results.owned, 
            results.netShips, 
            results.friendlyProdFromTarget, 
            results.enemyProdFromTarget, 
            results.neutralCapturingSources, 
            results.newReservations, 
            results.neutralCaptureDist
    end

    return MapFuture
end
MapFuture = _module_init()
_module_init = nil
