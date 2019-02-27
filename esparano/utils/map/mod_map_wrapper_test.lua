require("mod_assert")
require("mod_testmapgen")
require("mod_map_wrapper")
require("mod_profiler")

local m
local p
function before_each()
    local items = genMap()
    m = Map.new(items)
    p = profiler.new()
    p:profile(m)
end

function test_available_functions()
    assert.not_nil(Map)
end

function test_totalShips_memoization()
    m:totalShips()
    m:totalShips()
    assert.equals(1, p:getN(m, "getPlanetList"))
    m:_resetCaches()
    m:totalShips()
    assert.equals(2, p:getN(m, "getPlanetList"))
end

function test_totalProd_memoization()
    m:totalProd()
    m:totalProd()
    assert.equals(1, p:getN(m, "getPlanetList"))
    m:_resetCaches()
    m:totalProd()
    assert.equals(2, p:getN(m, "getPlanetList"))
end

function test_totalShips_ownerId_memoization()
    local users = m:getUserList()
    local total = 0
    for _, u in ipairs(users) do
        total = total + m:totalShips(u.n)
    end
    assert.equals_epsilon(m:totalShips(), total)
    assert.equals(4, p:getN(m, "getPlanetList"))

    for _, u in pairs(users) do
        total = total + m:totalShips(u.n)
    end
    m:totalShips()
    assert.equals(4, p:getN(m, "getPlanetList"))
end

function test_totalProd_ownerId_memoization()
    local users = m:getUserList()
    local total = 0
    for _, u in ipairs(users) do
        total = total + m:totalProd(u.n)
    end
    assert.equals_epsilon(m:totalProd(), total)
    assert.equals(4, p:getN(m, "getPlanetList"))

    for _, u in pairs(users) do
        total = total + m:totalProd(u.n)
    end
    m:totalProd()
    assert.equals(4, p:getN(m, "getPlanetList"))
end

function test_update_items()
    local oldTotalProd = m:totalProd()
    m:totalProd()
    assert.equals(1, p:getN(m, "getPlanetList"))

    m:update(genMap())
    local newTotalProd = m:totalProd()
    m:totalProd()
    assert.not_equals(oldTotalProd, newTotalProd)
    assert.equals(2, p:getN(m, "getPlanetList"))
end

function test_getUserList()
    local allUsers = m:getUserList()
    assert.equals(3, #allUsers)
    local stillAllUsers = m:getUserList(true)
    assert.equals(3, #stillAllUsers)
    local humanUsers = m:getUserList(false)
    assert.equals(2, #humanUsers)
end

require("mod_test_runner")
