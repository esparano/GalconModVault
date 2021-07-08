require("mod_common_utils")
require("mod_game_utils")
require("mod_assert")

function _module_init()
    local MapReservations = {}

    local function _newInterval(low, high)
        return {
            low = low, 
            high = high
        }
    end

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
        if common_utils.toPrecision(ships, 5) == 0 then return 0 end

        planetId = game_utils.toId(planetId)
        local planet = self.items[planetId]
        self.shipReservations[planetId] = self.shipReservations[planetId] or 0
        local newReservations = math.min(planet.ships, self.shipReservations[planetId] + ships)
        local amountReserved = newReservations - self.shipReservations[planetId] 
        self.shipReservations[planetId] = newReservations
        return common_utils.toPrecision(amountReserved, 5)
    end

    function MapReservations:updateShipReservations(newReservations)
        for planetId,requestedReserved in pairs(newReservations) do
            requestedReserved = common_utils.toPrecision(requestedReserved, 5)
            local amountReserved = self:reserveShips(planetId, requestedReserved)
            assert.equals(amountReserved, requestedReserved, "Amount of ships requested could not be reserved!")
        end
    end

    -- reserve all production up until a specific time, returning the amount of ships successfully reserved
    function MapReservations:reserveAllProdUntilTime(planetId, t)
        assert.is_true(t >= 0, "Cannot reserve prod for negative amount of time!")
        if t == 0 then return 0 end

        planetId = game_utils.toId(planetId)
        self.prodReservations[planetId] = self.prodReservations[planetId] or {}

        local prodTimeBefore = self:_sumReservedProdTimeBeforeTime(planetId, t)

        table.insert(self.prodReservations[planetId], _newInterval(0, t))
        self:_simplifyProdIntervals(planetId)

        local prodTimeAfter = self:_sumReservedProdTimeBeforeTime(planetId, t)
        assert.equals(t, prodTimeAfter, "All prod should have been reserved!!")

        local amountReserved = game_utils.calcShipsProducedNonNeutral(self.items[planetId], prodTimeAfter - prodTimeBefore)
        return common_utils.toPrecision(amountReserved, 5)
    end

    -- reserve an amount of production (specified in ships) any time before maxT, returning the number of ships successfully reserved
    function MapReservations:reserveFutureProd(planetId, maxT, ships)
        assert.is_true(maxT >= 0, "Cannot reserve prod starting at negative time!")
        if ships == 0 or maxT == 0 then return 0 end

        planetId = game_utils.toId(planetId)
        self.prodReservations[planetId] = self.prodReservations[planetId] or {}

        local prodTimeBefore = self:_sumReservedProdTimeBeforeTime(planetId, maxT)

        local planet = self.items[planetId]
        local timeToReserve = game_utils.calcTimeToProduceShipsNonNeutral(planet, ships)
        self:_doReserveProdTimeBeforeTime(planetId, maxT, timeToReserve)

        local prodTimeAfter = self:_sumReservedProdTimeBeforeTime(planetId, maxT)

        local amountReserved = game_utils.calcShipsProducedNonNeutral(self.items[planetId], prodTimeAfter - prodTimeBefore)
        return common_utils.toPrecision(amountReserved, 5)
    end

    function MapReservations:_doReserveProdTimeBeforeTime(planetId, high, timeLeftToReserve)
        local t = high

        local intervals = self.prodReservations[planetId]
        for i = #intervals, 1, -1 do
            local interval = intervals[i]
            if t > interval.low then 
                local availableProdTime = math.max(t - interval.high, 0)
                if availableProdTime >= timeLeftToReserve then 
                    t = t - timeLeftToReserve
                    timeLeftToReserve = 0
                    break
                end
                timeLeftToReserve = timeLeftToReserve - availableProdTime
                t = interval.low
            end
        end
        t = math.max(t - timeLeftToReserve, 0)

        table.insert(self.prodReservations[planetId], _newInterval(t, high))
        self:_simplifyProdIntervals(planetId)
    end

    function MapReservations:_sumReservedProdTimeBeforeTime(planetId, t)
        local totals = common_utils.map(self.prodReservations[planetId], function(r) 
            return math.min(t, r.high) - math.min(t, r.low)
        end)
        return common_utils.sumList(totals)
    end
    
    function MapReservations:_simplifyProdIntervals(planetId)
        local intervals = self.prodReservations[planetId]
        if #intervals <= 1 then return end 

        table.sort(intervals, function(r1,r2) return r1.low < r2.low end)

        local newIntervals = {}
        local current 
        for _,r in ipairs(intervals) do
            current = current or _newInterval(r.low, r.high)
            if r.low <= current.high then
                current.low = math.min(r.low, current.low)
                current.high = math.max(r.high, current.high)
            else 
                table.insert(newIntervals, current)
                current = _newInterval(r.low, r.high)
            end    
        end
        table.insert(newIntervals, current)
        self.prodReservations[planetId] = newIntervals
    end

    return MapReservations
end
MapReservations = _module_init()
_module_init = nil
