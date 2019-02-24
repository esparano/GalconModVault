require("mod_assert")
require("mod_tictactoeplayer")

function test_available_functions()
    assert.not_nil(TicTacToePlayer)
    assert.not_nil(TicTacToePlayer.new)
    assert.not_nil(TicTacToePlayer.getTerminalStateByPerformingSimulationFromState)
    assert.not_nil(TicTacToePlayer.getRewardFromTerminalState)
    assert.not_nil(TicTacToePlayer.getMarker)
    local root = TicTacToePlayer.new(true)
    for k, v in pairs(root) do
        --print(k)
    end
end

function test_local_functions()
    assert.is_nil(new)
    assert.is_nil(_m_init)
    assert.is_nil(pickFromAvailableActions)
end

function init()
end

function loop(t)
end

function event(e)
end

require("mod_test_runner")
