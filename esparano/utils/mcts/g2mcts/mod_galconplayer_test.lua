require("mod_assert")
require("mod_testmapgen")
require("mod_map_info")
require("mod_galconplayer")
require("mod_galconstate")

local agent
local enemyAgent
local state
function before_each()
    local map = Map.new(genMap())
    local users = map:getUserList(false)
    agent = GalconPlayer.new(users[1].n)
    enemyAgent = GalconPlayer.new(users[2].n)
    state = GalconState.new(map, agent, enemyAgent)
end

function test_available_functions()
    assert.not_nil(GalconPlayer)
    assert.not_nil(GalconPlayer.new)
    assert.not_nil(GalconPlayer.simulateUntilTerminal)
    assert.not_nil(GalconPlayer.getRewardFromState)
    assert.not_nil(GalconPlayer.getAvailableActions)
    local root = GalconPlayer.new(true)
    for k, v in pairs(root) do
        --print(k)
    end
end

function test_local_functions()
    assert.is_nil(new)
    assert.is_nil(_m_init)
end

function test_getAvailableActions()
    local actionSet = agent:getAvailableActions(state)
    for action in pairs(actionSet:getValues()) do
        --print(action)
    end
end

function test_getAvailableActions_memoization()
    local actionSet = agent:getAvailableActions(state)
    local actionSet2 = agent:getAvailableActions(state)
    assert.equals(actionSet, actionSet2)
end

function test_getRewardFromState()
    local eval = agent:getRewardFromState(state)
    assert.not_equals(0, eval)
    assert.not_equals(1, eval)
end

function test_getRewardFromState_memoization()
    local eval = agent:getRewardFromState(state)
    local eval2 = agent:getRewardFromState(state)
    assert.equals(eval, eval2)
    -- TODO: profile so this actually tests something
end

local function removeItemsForUser(map, userN)
    local toDelete = {}
    for n, item in pairs(map._items) do
        if not item.is_user and item.owner == userN then
            table.insert(toDelete, n)
        end
    end
    for _, n in ipairs(toDelete) do
        map._items[n] = nil
    end
    map:update(map._items)
end

function test_getRewardFromState_win()
    removeItemsForUser(state._map, enemyAgent._n)
    local eval = agent:getRewardFromState(state)
    assert.equals(1, eval)
end

function test_getRewardFromState_loss()
    removeItemsForUser(state._map, agent._n)
    local eval = agent:getRewardFromState(state)
    assert.equals(-1, eval)
end

require("mod_test_runner")
