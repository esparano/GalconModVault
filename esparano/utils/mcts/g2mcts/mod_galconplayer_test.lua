require("mod_assert")
require("mod_galconplayer")

function test_available_functions()
    assert.not_equals(nil, GalconPlayer)
    assert.not_equals(nil, GalconPlayer.new)
    assert.not_equals(nil, GalconPlayer.getTerminalStateByPerformingSimulationFromState)
    assert.not_equals(nil, GalconPlayer.getRewardFromTerminalState)
    assert.not_equals(nil, GalconPlayer.getMarker)
    local root = GalconPlayer.new(true)
    for k, v in pairs(root) do
        --print(k)
    end
end

function test_local_functions()
    assert.equals(nil, new)
    assert.equals(nil, _m_init)
    assert.equals(nil, pickFromAvailableActions)
end

function init()
end

function loop(t)
end

function event(e)
end

require("mod_test_runner")
