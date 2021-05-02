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

    return MapFuture
end
MapFuture = _module_init()
_module_init = nil
