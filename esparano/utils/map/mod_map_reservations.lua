require("mod_common_utils")
require("mod_game_utils")
require("mod_assert")

function _module_init()
    local MapReservations = {}

    function MapReservations.new(items)
        local instance = {}
        for k, v in pairs(MapReservations) do
            instance[k] = v
        end

        instance.shipReservations = {}
        instance.prodReservations = {}
        instance.items = items

        return instance
    end

    function MapReservations:copy()
        -- don't copy items
        local instance = MapReservations.new(self.items)
        instance.shipReservations = common_utils.copy(self.shipReservations)
        instance.prodReservations = common_utils.copy(self.prodReservations)
        return instance
    end

    function MapReservations:getShipReservations(planetId)
        planetId = game_utils.toId(planetId)
        return self.shipReservations[planetId] or 0
    end

    -- reserve a number of ships currently on a planet. Returns number of ships actually reserved.
    function MapReservations:reserveShips(planetId, ships)
        local planetId = game_utils.toId(planetId)
        local planet = self.items[planetId]
        self.shipReservations[planetId] = self.shipReservations[planetId] or 0
        local newReservations = math.min(planet.ships, self.shipReservations[planetId] + ships)
        local amountReserved = newReservations - self.shipReservations[planetId] 
        self.shipReservations[planetId] = newReservations
        return amountReserved
    end

    -- reserve all production up until a specific time, returning the amount of ships successfully reserved
    function MapReservations:reserveAllProdUntilTime(planetId, t)
        -- TODO:
    end

    -- reserve an amount of production any time before t, returning the number of ships successfully reserved
    function MapReservations:reserveProdBeforeTime(planetId, t, ships)
        -- TODO: 
    end

    --[[
        reservations = {
            (2,3)
            (4,6) 
        }
        t = 4.5, ships = 2.5
        -> reservations = {
            (0.5,6) 
        }, return 2.5

    --]]

    function MapReservations:updateShipReservations(newReservations)
        for planetId,requestedReserved in pairs(newReservations) do
            local amountReserved = self:reserveShips(planetId, requestedReserved)
            assert.equals(amountReserved, requestedReserved, "Amount of ships requested could not be reserved!")
        end
    end

    return MapReservations
end
MapReservations = _module_init()
_module_init = nil
