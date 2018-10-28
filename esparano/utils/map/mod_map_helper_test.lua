require("mod_assert")
require("mod_testmapgen")
require("mod_map_helper")
require("mod_profiler")

function test_available_functions()
    assert.not_equals(nil, map)
end

function test_memoization_benchmark()
    local items = genMap()
    assert.not_equals(0, #items)

    local m = map.new(items)
    
    local p = profiler.new()
    p:profile(m)    

    for i = 1, 1000 do
        m:totalShips()
        m:_resetCaches()
    end
    assert.equals(1000, p:getN(m, "getPlanetList"))

    for i = 1, 1000 do
        m:totalShips()
    end
    assert.equals(1001, p:getN(m, "getPlanetList"))
end

-- TODO: test memoization for getting ships for a certain player
-- TODO: test updating items

require("mod_test_runner")
