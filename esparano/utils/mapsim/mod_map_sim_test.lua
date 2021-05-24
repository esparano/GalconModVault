require("mod_assert")
require("mod_testmapgen")
require("mod_map_info")
require("mod_map_sim")

local function printPlanet(p, name)
    if name == nil then
        name = "p"
    end
    print(name .. "__ x: " .. p.x .. ", y: " .. p.y .. ", r: " .. p.r)
end

local function printFleet(f, name)
    if name == nil then
        name = "f"
    end
    print(name .. "__ x: " .. f.x .. ", y: " .. f.y .. ", r: " .. f.r)
end

local map
local user
local home
function before_each()
    local items = genMap()
    map = Map.new(items)
    user = map:getUserList(false)[1]
    assert.not_nil(user)
    home = map:getPlanetList(user)[1]
end

function test_available_functions()
    assert.not_nil(Map)
end

function test_send_vertical()
    local target = map:getPlanetList(map:getNeutralUser())[1]
    local fleets = map:getFleetList()
    assert.equals(0, #fleets)

    home.ships = 100
    target.x = home.x
    target.y = home.y + 100

    MapSim.send(map, home, target, 75)

    assert.equals(25, home.ships)

    fleets = map:getFleetList()
    assert.equals(1, #fleets)

    local fleet = fleets[1]
    assert.equals(75, fleet.ships)
    assert.equals(target.n, fleet.target)
    assert.equals_epsilon(home.x, fleet.x)
    assert.equals_epsilon(home.y + home.r, fleet.y)
end

function test_send_horizontal()
    local target = map:getPlanetList(map:getNeutralUser())[1]
    target.x = home.x + 100
    target.y = home.y

    MapSim.send(map, home, target, 100)

    local fleet = map:getFleetList()[1]
    assert.equals_epsilon(home.x + home.r, fleet.x)
    assert.equals(home.y, fleet.y)
end

function test_redirect()
    local target = map:getPlanetList(map:getNeutralUser())[1]
    home.ships = 60

    MapSim.send(map, home, target, 50)
    local fleet = map:getFleetList()[1]
    assert.equals_epsilon(30, home.ships)
    assert.equals_epsilon(30, fleet.ships)

    MapSim.redirect(map, fleet, home)
    assert.equals(home.n, fleet.target)

    MapSim.land(map, fleet)

    assert.equals_epsilon(60, home.ships)
    assert.equals(0, #map:getFleetList())
end

function test_land_capture()
    local target = map:getPlanetList(map:getNeutralUser())[1]
    home.ships = 60
    target.ships = 50

    MapSim.send(map, home, target, 50)
    local fleet = map:getFleetList()[1]
    MapSim.land(map, fleet)

    assert.equals_epsilon(20, target.ships)
    assert.equals(map:getNeutralUser().n, target.owner)
    assert.is_true(target.neutral)

    MapSim.send(map, home, target, 100)
    fleet = map:getFleetList()[1]
    MapSim.land(map, fleet)

    assert.equals_epsilon(10, target.ships)
    assert.equals(home.owner, target.owner)
    assert.is_false(target.neutral)
end

function test_simulate_fleet_flying_and_landing()
    local target = map:getPlanetList(map:getNeutralUser())[1]
    home.ships = 10
    home.x = 0
    home.r = 5
    target.ships = 50
    target.x = 100
    target.y = home.y
    target.r = 5

    MapSim.send(map, home, target, 100)

    local fleet = map:getFleetList()[1]
    assert.equals(home.y, fleet.y)
    assert.equals_epsilon(5, fleet.x)

    -- default quarter second step
    MapSim.simulate(map)
    assert.equals_epsilon(15, fleet.x)

    MapSim.simulate(map, 0.5)
    assert.equals_epsilon(35, fleet.x)

    MapSim.simulate(map, 1.499)
    assert.equals(1, #map:getFleetList(), "should not have crashed yet")
    assert.equals_epsilon(50, target.ships, 0.01)

    MapSim.simulate(map, 0.002)
    assert.equals(0, #map:getFleetList(), "should have crashed now")
    assert.equals_epsilon(40, target.ships, 0.01)
end

function test_simulate_production()
    local someNeutral = map:getPlanetList(map:getNeutralUser())[1]
    home.ships = 10
    home.production = 50
    someNeutral.ships = 50
    someNeutral.production = 100

    MapSim.simulate(map, 0.543)

    assert.equals_epsilon(10.543, home.ships)
    assert.equals(50, someNeutral.ships)
end

require("mod_test_runner")
