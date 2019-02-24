require("mod_assert")
require("mod_features")
require("mod_map_helper")
require("mod_mapgenhelper")
require("mod_testmapgen")

local m, friendlyUser, enemyUser, neutralUser
local function setUpRegularMap()
    m = map.new(genMap())
    local playerList = m:getUserList(false)
    friendlyUser = playerList[1]
    enemyUser = playerList[2]
    neutralUser = m:getNeutralUser()
end
local function setUpSquareMap()
    local mapgen = mapgenhelper.new()
    friendlyUser = mapgen:createUser(false)
    enemyUser = mapgen:createUser(false)
    neutralUser = mapgen:createUser(true)

    local fP1 = mapgen:createPlanet(0, 0, 10, 50, 100, friendlyUser)
    local fP2 = mapgen:createPlanet(10, 5, 10, 100, 50, friendlyUser)
    local eP1 = mapgen:createPlanet(10, 15, 10, 50, 50, enemyUser)
    local eP2 = mapgen:createPlanet(0, 10, 10, 100, 100, enemyUser)
    mapgen:createFleet(5, 5, 1, 50, enemyUser, fP1)

    m = map.new(mapgen:build())
end

function test_prodFraction()
    setUpRegularMap()

    local friendlyProdFrac = features.prodFraction(m, friendlyUser, enemyUser)
    local enemyProdFrac = features.prodFraction(m, enemyUser, friendlyUser)
    local totalProdFrac = friendlyProdFrac + enemyProdFrac
    assert.equals_epsilon(1, totalProdFrac, 0.000001)
end

function test_shipsFraction()
    setUpRegularMap()
    
    local friendlyShipsFrac = features.shipsFraction(m, friendlyUser, enemyUser)
    local enemyShipsFrac = features.shipsFraction(m, enemyUser, friendlyUser)
    local totalShipsFrac = friendlyShipsFrac + enemyShipsFrac
    assert.equals_epsilon(1, totalShipsFrac, 0.000001)
end

function test_prodCenterOfMassDistance()
    setUpSquareMap()

    local dist = features.prodCenterOfMassDistance(m, friendlyUser, enemyUser)
    -- friendly prodCOM: {3.3333333, 1.6666666}
    -- enemy prodCOM: {3.3333, 11.66666}
    assert.equals_epsilon(10, dist, 0.000001)
end

function test_shipsCenterOfMassDistance()
    setUpSquareMap()
    
    local dist = features.shipsCenterOfMassDistance(m, friendlyUser, enemyUser)
    -- friendly shipsCOM: {6.666667, 3.333}
    -- enemy shipsCOM: {3.75, 10}
    assert.equals_epsilon(7.2767704, dist, 0.0000001)
end

require("mod_test_runner")
