require("mod_memoize")

-- TODO: make this part of a library
local function deepcopy(o)
    if type(o) ~= "table" then
        return o
    end
    local r = {}
    for k, v in pairs(o) do
        r[k] = deepcopy(v)
    end
    return r
end

-- TODO: documentation
-- Precalculates things for speeding up future calculations
-- Provides API for quickly and efficiently accessing aspects about the map
function _module_init()
    local Map = {}

    local cachedFunctions = {
        "getPlanetList",
        "getPlanetAndFleetList",
        "getUserList",
        "getNeutralUser",
        "totalProd",
        "totalShips",
        "totalEnemyProd",
        "totalEnemyShips",
        "getEnemyPlanetList",
        "getEnemyPlanetAndFleetList"
    }

    -- return a clone of this map
    function Map.copy(map)
        local itemsClone = deepcopy(map._items)
        return Map.new(itemsClone)
    end

    function Map.new(items)
        local instance = {}
        for k, v in pairs(Map) do
            instance[k] = v
        end

        -- set up memoization of key functions
        instance.caches = {}
        for _, funcName in pairs(cachedFunctions) do
            instance.caches[funcName] = {}
            instance[funcName] = memoize(instance[funcName], instance.caches[funcName])
        end

        instance._items = items

        return instance
    end

    function Map:_resetCaches()
        for _, s in pairs(cachedFunctions) do
            local t = self.caches[s]
            for arg in pairs(t) do
                t[arg] = nil
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

    function Map:update(items)
        self._items = items
        self:_resetCaches()
    end

    -- TODO: refactor searching for planets/users/etc.
    function Map:getPlanetList(ownerId)
        return searchItems(
            self._items,
            function(item)
                return item.is_planet and (ownerId == nil or ownerId == item.owner)
            end
        )
    end

    function Map:getFleetList(ownerId)
        return searchItems(
            self._items,
            function(item)
                return item.is_fleet and (ownerId == nil or ownerId == item.owner)
            end
        )
    end

    -- TODO: test
    function Map:getPlanetAndFleetList(ownerId)
        return searchItems(
            self._items,
            function(item)
                return (item.is_planet or item.is_fleet) and (ownerId == nil or ownerId == item.owner)
            end
        )
    end

    function Map:getUserList(includeNeutral)
        if includeNeutral == nil then
            includeNeutral = true
        end
        return searchItems(
            self._items,
            function(item)
                return item.is_user and (includeNeutral or not item.neutral)
            end
        )
    end

    function Map:getNeutralUser()
        local users = self:getUserList()
        for _, u in ipairs(users) do
            if u.neutral then
                return u
            end
        end
    end

    -- TODO: REFACTOR THIS
    function Map:getEnemyPlanetList(userId)
        return searchItems(
            self._items,
            function(item)
                return item.is_planet and item.owner ~= userId and not item.neutral
            end
        )
    end

    -- TODO: REFACTOR THIS
    function Map:getEnemyPlanetAndFleetList(userId)
        return searchItems(
            self._items,
            function(item)
                return (item.is_planet or item.is_fleet) and item.owner ~= userId and not item.neutral
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
    function Map:totalProd(ownerId)
        return sumProperty(self:getPlanetList(ownerId), "production")
    end

    function Map:totalShips(ownerId)
        return sumProperty(self:getPlanetAndFleetList(ownerId), "ships")
    end

    function Map:totalEnemyProd(ownerId)
        return sumProperty(self:getEnemyPlanetList(ownerId), "production")
    end

    function Map:totalEnemyShips(ownerId)
        return sumProperty(self:getEnemyPlanetAndFleetList(ownerId), "ships")
    end

    return Map
end
Map = _module_init()
_module_init = nil
