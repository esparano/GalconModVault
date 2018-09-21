require("mod_assert")
require("mod_tictactoeplayer")

function test_available_functions()
    assert.not_equals(nil, TicTacToePlayer)
    assert.not_equals(nil, TicTacToePlayer.new)
    assert.not_equals(nil, TicTacToePlayer.getTerminalStateByPerformingSimulationFromState)
    assert.not_equals(nil, TicTacToePlayer.getRewardFromTerminalState)
    assert.not_equals(nil, TicTacToePlayer.getMarker)
    local root = TicTacToePlayer.new(true)
    for k,v in pairs(root) do
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