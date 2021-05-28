require("mod_assert")
require("mod_map_reservations")
require("mod_common_utils")
require("mod_testmapgen")

local mapReservations

function before_each()
    mapReservations = MapReservations.new(genMap())
end

function test_available_functions()
    assert.not_nil(MapReservations)
    assert.not_nil(MapReservations.new)
    assert.not_nil(MapReservations.copy)
    assert.not_nil(MapReservations.getShipReservations)
    assert.not_nil(MapReservations.reserveShips)
    assert.not_nil(MapReservations.updateShipReservations)
    assert.not_nil(MapReservations.reserveAllProdUntilTime)
    assert.not_nil(MapReservations.reserveFutureProd)
    assert.not_nil(MapReservations._simplifyProdIntervals)
    assert.not_nil(MapReservations._sumReservedProdTimeBeforeTime)
end

function test_simplifyProdIntervals_noOverlap()
    mapReservations.prodReservations[5003] = {
        {low = 0, high = 3},
        {low = 3.1, high = 7},
    }
    mapReservations:_simplifyProdIntervals(5003)
    local r = mapReservations.prodReservations[5003]

    assert.equals(2, #r)
    -- TODO: deep equals assertions
    assert.equals(0, r[1].low)
    assert.equals(3, r[1].high)
    assert.equals(3.1, r[2].low)
    assert.equals(7, r[2].high)
end

function test_simplifyProdIntervals_noOverlap_unordered()
    mapReservations.prodReservations[5003] = {
        {low = 3.1, high = 7},
        {low = 0, high = 3},
    }
    mapReservations:_simplifyProdIntervals(5003)
    local r = mapReservations.prodReservations[5003]

    assert.equals(2, #r)
    -- TODO: deep equals assertions
    assert.equals(0, r[1].low)
    assert.equals(3, r[1].high)
    assert.equals(3.1, r[2].low)
    assert.equals(7, r[2].high)
end


function test_simplifyProdIntervals_overlap()
    mapReservations.prodReservations[5003] = {
        {low = 0, high = 3},
        {low = 0, high = 7},
    }
    mapReservations:_simplifyProdIntervals(5003)
    local r = mapReservations.prodReservations[5003]
    
    assert.equals(1, #r)
    assert.equals(0, r[1].low)
    assert.equals(7, r[1].high)
end

function test_simplifyProdIntervals_overlapEquals()
    mapReservations.prodReservations[5003] = {
        {low = 0, high = 3},
        {low = 3, high = 7},
    }
    mapReservations:_simplifyProdIntervals(5003)
    local r = mapReservations.prodReservations[5003]
    
    assert.equals(1, #r)
    assert.equals(0, r[1].low)
    assert.equals(7, r[1].high)
end

function test_simplifyProdIntervals_overlapEquals_unordered()
    mapReservations.prodReservations[5003] = {
        {low = 3, high = 7},
        {low = 0, high = 3},
    }
    mapReservations:_simplifyProdIntervals(5003)
    local r = mapReservations.prodReservations[5003]
    
    assert.equals(1, #r)
    assert.equals(0, r[1].low)
    assert.equals(7, r[1].high)
end

function test_simplifyProdIntervals_empty()
    mapReservations.prodReservations[5003] = {
    }
    mapReservations:_simplifyProdIntervals(5003)
    local r = mapReservations.prodReservations[5003]
    
    assert.equals(0, #r)
end

function test_simplifyProdIntervals_oneReservation()
    mapReservations.prodReservations[5003] = {
        {low = 0, high = 3}
    }
    mapReservations:_simplifyProdIntervals(5003)
    local r = mapReservations.prodReservations[5003]
    
    assert.equals(1, #r)
    assert.equals(0, r[1].low)
    assert.equals(3, r[1].high)
end

function test_sumReservedProdTimeBeforeTime()
    mapReservations.prodReservations[5003] = {
        {low = 0, high = 3}
    }
    
    assert.equals(0, mapReservations:_sumReservedProdTimeBeforeTime(5003, -1))
    assert.equals(0, mapReservations:_sumReservedProdTimeBeforeTime(5003, 0))
    assert.equals(1.234, mapReservations:_sumReservedProdTimeBeforeTime(5003, 1.234))
    assert.equals(3, mapReservations:_sumReservedProdTimeBeforeTime(5003, 3))
    assert.equals(3, mapReservations:_sumReservedProdTimeBeforeTime(5003, 10))
end


function test_sumReservedProdTimeBeforeTime_multiple()
    mapReservations.prodReservations[5003] = {
        {low = 2, high = 3},
        {low = 4, high = 5.5},
    }
    
    assert.equals(0, mapReservations:_sumReservedProdTimeBeforeTime(5003, -1))
    assert.equals(0, mapReservations:_sumReservedProdTimeBeforeTime(5003, 2))
    assert.equals_epsilon(0.234, mapReservations:_sumReservedProdTimeBeforeTime(5003, 2.234), 0.000000000000001)
    assert.equals(1, mapReservations:_sumReservedProdTimeBeforeTime(5003, 3))
    assert.equals(1, mapReservations:_sumReservedProdTimeBeforeTime(5003, 3.5))
    assert.equals(1, mapReservations:_sumReservedProdTimeBeforeTime(5003, 4))
    assert.equals_epsilon(1.6, mapReservations:_sumReservedProdTimeBeforeTime(5003, 4.6), 0.000000000000001)
    assert.equals(2.5, mapReservations:_sumReservedProdTimeBeforeTime(5003, 5.5))
    assert.equals(2.5, mapReservations:_sumReservedProdTimeBeforeTime(5003, 1000))
end

function test_reserveAllProdUntilTime()
    mapReservations.prodReservations[5003] = {
        {low = 2, high = 3},
        {low = 4, high = 5.5},
    }
    
    mapReservations.items[5003].production = 100
    
    assert.equals(1 * 2, mapReservations:reserveAllProdUntilTime(5003, 1))
    assert.equals(0, mapReservations:reserveAllProdUntilTime(5003, 1))
    assert.equals_epsilon(0.234 * 2, mapReservations:reserveAllProdUntilTime(5003, 1.234), 0.000000000000001)
    assert.equals(1.766 * 2, mapReservations:reserveAllProdUntilTime(5003, 4.5))
    assert.equals(0.5 * 2, mapReservations:reserveAllProdUntilTime(5003, 6))
    assert.equals(0, mapReservations:reserveAllProdUntilTime(5003, 3))
end

function test_reserveAllProdUntilTime_empty()
    mapReservations.items[5003].production = 100
    
    assert.equals(1 * 2, mapReservations:reserveAllProdUntilTime(5003, 1))
    assert.equals(0, mapReservations:reserveAllProdUntilTime(5003, 1))
    assert.equals_epsilon(0.234 * 2, mapReservations:reserveAllProdUntilTime(5003, 1.234), 0.000000000000001)
    assert.equals(3.766 * 2, mapReservations:reserveAllProdUntilTime(5003, 5))
    assert.equals(1 * 2, mapReservations:reserveAllProdUntilTime(5003, 6))
    assert.equals(0, mapReservations:reserveAllProdUntilTime(5003, 3))
end

function test_reserveFutureProd()
    mapReservations.prodReservations[5003] = {
        {low = 2, high = 3},
        {low = 4, high = 5.5},
    }
    mapReservations.items[5003].production = 100
    
    -- should take 5 seconds for 100-prod to produce 10 ships, leaving 0.5 seconds left
    assert.equals(10, mapReservations:reserveFutureProd(5003, 8, 10))

    local r = mapReservations.prodReservations[5003]
    
    assert.equals(1, #r)
    assert.equals(0.5, r[1].low)
    assert.equals(8, r[1].high)

    assert.equals(1, mapReservations:reserveFutureProd(5003, 8, 10))
    assert.equals(0, mapReservations:reserveFutureProd(5003, 8, 10))
    assert.equals(0, mapReservations:reserveFutureProd(5003, 0, 10))
    assert.equals(0, mapReservations:reserveFutureProd(5003, 4, 10))
    assert.equals(0, mapReservations:reserveFutureProd(5003, 7, 10))
    assert.equals(4, mapReservations:reserveFutureProd(5003, 10, 4))
    assert.equals(2, mapReservations:reserveFutureProd(5003, 15, 2))
    assert.equals(3, mapReservations:reserveFutureProd(5003, 16, 3))
    assert.equals(7, mapReservations:reserveFutureProd(5003, 15, 100))

    r = mapReservations.prodReservations[5003]
    assert.equals(1, #r)
    assert.equals(0, r[1].low)
    assert.equals(16, r[1].high)
end

function test_reserveFutureProd_empty()
    mapReservations.items[5003].production = 100
    
    -- should take 5 seconds for 100-prod to produce 10 ships, leaving 0.5 seconds left
    assert.equals(10, mapReservations:reserveFutureProd(5003, 8, 10))
    assert.equals(4, mapReservations:reserveFutureProd(5003, 2, 4))
    assert.equals(2, mapReservations:reserveFutureProd(5003, 4, 4))
    assert.equals(0, mapReservations:reserveFutureProd(5003, 8, 1))

    local r = mapReservations.prodReservations[5003]
    
    assert.equals(1, #r)
    assert.equals(0, r[1].low)
    assert.equals(8, r[1].high)
end

function test_reserveFutureProd_doubles()
    mapReservations.items[5003].production = 100
    
    -- should take 5 seconds for 100-prod to produce 10 ships, leaving 0.5 seconds left
    assert.equals_epsilon(5.232, mapReservations:reserveFutureProd(5003, 4, 5.232), 0.000000000000001)
    assert.equals_epsilon(1.253, mapReservations:reserveFutureProd(5003, 2, 1.253), 0.000000000000001)
    assert.equals_epsilon(1.515, mapReservations:reserveFutureProd(5003, 4, 4), 0.000000000000001)
    assert.equals(0, mapReservations:reserveFutureProd(5003, 4, 1))

    local r = mapReservations.prodReservations[5003]
    
    assert.equals(1, #r)
    assert.equals(0, r[1].low)
    assert.equals(4, r[1].high)
end

function init()
end

function loop(t)
end

function event(e)
end

require("mod_test_runner")
