require("mod_assert")
require("mod_testmapgen")
require("mod_map_helper")

function test_available_functions()
    assert.not_equals(nil, map)
end

function test_get_and_set_default_map()
    local items = genMap()
    assert.not_equals(0, #items)

    local m = map.new(items)
    print(m:totalProd())
    print(m:totalProd())
    print(m:totalProd())
end

require("mod_test_runner")