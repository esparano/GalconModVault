require("mod_memoize")
require("mod_common_utils")

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

    local function toUserId(user)
        if type(user) == "number" then return user end
        return user.n
    end

    -- return a clone of this map
    function Map.copy(map)
        local itemsClone = common_utils.copy(map._items)
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

    function Map:update(items)
        self._items = items
        self:_resetCaches()
    end

    -- TODO: refactor searching for planets/users/etc.
    function Map:getPlanetList(ownerId)
        if ownerId then ownerId = toUserId(ownerId) end
        return common_utils.findAll(
            self._items,
            function(item)
                return item.is_planet and (ownerId == nil or ownerId == item.owner)
            end
        )
    end

    function Map:getFleetList(ownerId)
        if ownerId then ownerId = toUserId(ownerId) end
        return common_utils.findAll(
            self._items,
            function(item)
                return item.is_fleet and (ownerId == nil or ownerId == item.owner)
            end
        )
    end

    -- TODO: test
    function Map:getPlanetAndFleetList(ownerId)
        if ownerId then ownerId = toUserId(ownerId) end
        return common_utils.findAll(
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
        return common_utils.findAll(
            self._items,
            function(item)
                return item.is_user and (includeNeutral or not item.neutral)
            end
        )
    end

    function Map:getEnemyUser(userId)
        if userId then userId = toUserId(userId) end
        local users = self:getUserList(false)
        for _, u in ipairs(users) do
            if u.n ~= userId then
                return u
            end
        end
    end

    function Map:getNeutralUser()
        local users = self:getUserList()
        for _, u in ipairs(users) do
            if u.neutral then
                return u
            end
        end
    end

    function Map:getNeutralPlanetList()
        return self:getPlanetList(self:getNeutralUser())
    end

    function Map:getEnemyPlanetList(userId)
        return self:getPlanetList(self:getEnemyUser(userId))
    end

    function Map:getEnemyPlanetAndFleetList(userId)
        return self:getPlanetAndFleetList(self:getEnemyUser(userId))
    end

    local function sumProperty(l, p)
        local vs = common_utils.map(l, function (o) return o[p] end)
        return common_utils.sumList(vs)
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
