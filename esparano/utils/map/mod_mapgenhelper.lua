function _mapgenhelper_init()
    local module = {}

    local function createUser(n, team, neutral)
        return {
            is_user = true,
            n = n,
            team = team,
            neutral = neutral
        }
    end
    
    local function createPlanet(n, x, y, r, s, p, owner)
        return {
            is_planet = true,
            n = n,
            x = x,
            y = y,
            r = r,
            ships = s,
            production = p,
            owner = owner.n,
            team = owner.team,
            neutral = owner.neutral
        }
    end
    
    local function createFleet(n, syncId, x, y, r, s, owner, target)
        return {
            is_fleet = true,
            _n = n,
            n = syncId,
            x = x,
            y = y,
            r = r,
            ships = s,
            owner = owner.n,
            team = owner.team,
            target = target.n
        }
    end

    function module.new(items)
        local instance = {}
        for k, v in pairs(module) do
            instance[k] = v
        end
        instance.items = {}
        instance.nextN = 15 -- "item.n"s can be sparse, so ipairs shouldn't work
        return instance
    end

    function module:_addItem(item)
        self.items[item.n] = item 
        self.nextN = self.nextN + 1
        return item
    end

    function module:createUser(neutral)
        local o = createUser(self.nextN, self.nextN, neutral)
        return self:_addItem(o)
    end

    function module:createPlanet(x, y, r, s, p, owner)
        local o = createPlanet(self.nextN, x, y, r, s, p, owner)
        return self:_addItem(o)
    end

    function module:createFleet(x, y, r, s, owner, target)
        local o = createFleet(self.nextN, self.nextN, x, y, r, s, owner, target)
        return self:_addItem(o)
    end

    function module:build()
        return self.items
    end

    return module
end
mapgenhelper = _mapgenhelper_init()
_mapgenhelper_init = nil