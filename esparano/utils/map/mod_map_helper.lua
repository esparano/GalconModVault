-- TODO: documentation
-- Precalculates things for speeding up future calculations
-- Provides API for quickly and efficiently accessing aspects about the map
function _map_init()
    local map = {}

    function map.new(items)
        local instance = {}
        for k, v in pairs(map) do
            instance[k] = v
        end

        instance:initialCalculations(items)
        instance:update(items)

        return instance
    end

    function map:initialCalculations(items)
    end

    local function searchItems(items, f)
        local matches = {}
        for _, item in pairs(items) do
            if f(item) then
                matches[#matches + 1] = item
            end
        end
        return matches
    end

    function map:update(items)
        self.items = items
        self.userList = nil
        self.planetList = nil
        self.totalProdVal = nil
        self.fleetList = nil
    end

    function map:getPlanetList()
        if not self.planetList then
            self.planetList =
                searchItems(
                self.items,
                function(item)
                    return item.is_planet
                end
            )
        end
        return self.planetList
    end

    -- TODO:
    function map:totalProd()
        -- memoize all functions? update clears some functions?
        if self.totalProdVal ~= nil then
            return self.totalProdVal
        end
        local planetList = self:getPlanetList()
        -- TODO: functional programming library?
        local sum = 0
        for _, planet in ipairs(planetList) do
            sum = sum + planet.production
        end
        self.totalProdVal = sum
        return sum
    end

    function map:totalPlayerProd(playerId)
    end

    -- TODO:
    function map:totalShips()
    end

    function map:totalPlayerShips(playerId)
    end

    return map
end
map = _map_init()
_map_init = nil
