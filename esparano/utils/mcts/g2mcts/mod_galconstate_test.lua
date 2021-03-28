require("mod_assert")
require("mod_testmapgen")
require("mod_map_info")
require("mod_galconplayer")
require("mod_galconstate")

local agent
local enemyAgent
local state
local map
function before_each()
    map = Map.new(genMap())
    local users = map:getUserList(false)
    agent = GalconPlayer.new(users[1].n)
    enemyAgent = GalconPlayer.new(users[2].n)
    state = GalconState.new(map, agent, enemyAgent)
end

function test_available_functions()
    assert.not_nil(GalconState)
    assert.not_nil(GalconState.new)
    local root = GalconState.new()
    for k, v in pairs(root) do
        --print(k)
    end
end

function test_local_functions()
    assert.is_nil(new)
    assert.is_nil(_m_init)
end

function test_doApplyAction()
    local from = map:getPlanetList(agent._n)[1]
    local to = map:getPlanetList(map:getNeutralUser().n)[1]
    local action = "s," .. from.n .. "," .. to.n .. ",100"
    state:_doApplyAction(action)
    assert.equals(0, from.ships)
    assert.equals(1, #map:getFleetList())
end

function test_generateSendAction()
    local expected = "s,4,7,75"
    local actual = state.generateSendAction({n = 4}, {n = 7}, 75)
    assert.equals(expected, actual)
end

function test_generateRedirectAction()
    local expected = "r,4,7"
    local actual = state.generateRedirectAction({n = 4}, {n = 7})
    assert.equals(expected, actual)
end

function test_generateNullMove()
    local expected = GalconState.NULL_MOVE
    local actual = state.generateNullMove()
    assert.equals(expected, actual)
end

require("mod_test_runner")
