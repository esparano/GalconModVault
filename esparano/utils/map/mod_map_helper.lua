require("mod_memoize")

-- TODO: documentation
-- Precalculates things for speeding up future calculations
-- Provides API for quickly and efficiently accessing aspects about the map
function _map_init()
    local map = {}

    local cachedFunctions = {
        "getPlanetList",
        "totalProd",
        "totalShips",
    }

    function map.new(items)
        local instance = {}
        for k, v in pairs(map) do
            instance[k] = v
        end

        -- set up memoization of key functions
        instance.caches = {}
        for _, s in pairs(cachedFunctions) do
            instance.caches[s] = {}
            instance[s] = memoize(instance[s], instance.caches[s])
        end

        instance.items = items

        return instance
    end

    function map:_resetCaches()
        for _, s in pairs(cachedFunctions) do
            local t = self.caches[s]
            for k in pairs(t) do
                t[k] = nil
            end
        end
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
        self:_resetCaches()
    end

    function map:getPlanetList(ownerId)
        return searchItems(
            self.items,
            function(item)
                return item.is_planet and (ownerId == nil or ownerId == item.owner)
            end
        )
    end
    
    -- TODO: functional programming library?
    local function sumProperty(l, p)
        local sum = 0
        for _, v in ipairs(l) do
            sum = sum + v[p]
        end
        return sum
    end

    -- playerId is optional
    function map:totalProd(ownerId)
        return sumProperty(self:getPlanetList(ownerId), "production")
    end

    function map:totalShips(ownerId)
        return sumProperty(self:getPlanetList(ownerId), "ships")
    end

    return map
end
map = _map_init()
_map_init = nil
