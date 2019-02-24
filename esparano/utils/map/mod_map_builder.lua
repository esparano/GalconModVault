function _module_init()
    local MapBuilder = {}

    function MapBuilder.makeUser(n, team, neutral)
        return {
            is_user = true,
            n = n,
            team = team,
            neutral = neutral
        }
    end

    function MapBuilder.makePlanet(n, x, y, r, s, p, owner)
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

    function MapBuilder.makeFleet(n, syncId, x, y, r, s, owner, target)
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

    function MapBuilder.new(items)
        local instance = {}
        for k, v in pairs(MapBuilder) do
            instance[k] = v
        end
        instance.items = {}
        instance.nextN = 5000 -- "item.n"s can be sparse, so ipairs shouldn't work
        return instance
    end

    function MapBuilder:_addItem(item)
        self.items[item.n] = item
        self.nextN = self.nextN + 1
        return item
    end

    function MapBuilder:addUser(neutral)
        local o = MapBuilder.makeUser(self.nextN, self.nextN, neutral)
        return self:_addItem(o)
    end

    function MapBuilder:addPlanet(x, y, r, s, p, owner)
        local o = MapBuilder.makePlanet(self.nextN, x, y, r, s, p, owner)
        return self:_addItem(o)
    end

    function MapBuilder:addFleet(x, y, r, s, owner, target)
        local o = MapBuilder.makeFleet(self.nextN, self.nextN, x, y, r, s, owner, target)
        return self:_addItem(o)
    end

    function MapBuilder:build()
        return self.items
    end

    return MapBuilder
end
MapBuilder = _module_init()
_module_init = nil
