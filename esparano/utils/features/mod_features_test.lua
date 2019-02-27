require("mod_assert")
require("mod_features")
require("mod_map_wrapper")
require("mod_map_builder")
require("mod_testmapgen")

local m, friendlyUser, enemyUser, neutralUser
local function setUpRegularMap()
    m = Map.new(genMap())
    local playerList = m:getUserList(false)
    friendlyUser = playerList[1]
    enemyUser = playerList[2]
    neutralUser = m:getNeutralUser()
end
local function setUpSquareMap()
    local mapBuilder = MapBuilder.new()
    friendlyUser = mapBuilder:addUser(false)
    enemyUser = mapBuilder:addUser(false)
    neutralUser = mapBuilder:addUser(true)

    local fP1 = mapBuilder:addPlanet(0, 0, 10, 50, 100, friendlyUser)
    local fP2 = mapBuilder:addPlanet(10, 5, 10, 100, 50, friendlyUser)
    local eP1 = mapBuilder:addPlanet(10, 15, 10, 50, 50, enemyUser)
    local eP2 = mapBuilder:addPlanet(0, 10, 10, 100, 100, enemyUser)
    mapBuilder:addFleet(5, 5, 1, 50, enemyUser, fP1)

    m = Map.new(mapBuilder:build())
end

function test_prodFraction()
    setUpRegularMap()

    local friendlyProdFrac = features.prodFraction(m, friendlyUser, enemyUser)
    local enemyProdFrac = features.prodFraction(m, enemyUser, friendlyUser)
    local totalProdFrac = friendlyProdFrac + enemyProdFrac
    assert.equals_epsilon(1, totalProdFrac)
end

function test_shipsFraction()
    setUpRegularMap()

    local friendlyShipsFrac = features.shipsFraction(m, friendlyUser, enemyUser)
    local enemyShipsFrac = features.shipsFraction(m, enemyUser, friendlyUser)
    local totalShipsFrac = friendlyShipsFrac + enemyShipsFrac
    assert.equals_epsilon(1, totalShipsFrac)
end

function test_prodCenterOfMassDistance()
    setUpSquareMap()

    local dist = features.prodCenterOfMassDistance(m, friendlyUser, enemyUser)
    -- friendly prodCOM: {3.3333333, 1.6666666}
    -- enemy prodCOM: {3.3333, 11.66666}
    assert.equals_epsilon(10 / 300, dist)
end

function test_shipsCenterOfMassDistance()
    setUpSquareMap()

    local dist = features.shipsCenterOfMassDistance(m, friendlyUser, enemyUser)
    -- friendly shipsCOM: {6.666667, 3.333}
    -- enemy shipsCOM: {3.75, 10}
    assert.equals_epsilon(7.2767704 / 300, dist)
end

require("mod_test_runner")
