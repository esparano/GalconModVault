require("mod_neural_net")

function _m_init()
    local TicTacToePlayer = {}

    local function getTTTNN()
        local neural_net = nn.new()
        local layer1Weights = {
            {0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01},
            {0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01},
            {0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01},
            {0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01},
            {0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01},
            {0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01},
            {0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01},
            {0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01},
            {0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01},
            {0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01}
        }
        neural_net:addLayer(layer1Weights, "relu", true)

        local layer2Weights = {
            {0.01},
            {0.01},
            {0.01},
            {0.01},
            {0.01},
            {0.01},
            {0.01},
            {0.01},
            {0.01},
            {0.01}
        }
        neural_net:addLayer(layer2Weights, "sigmoid", true)

        return neural_net
    end

    function TicTacToePlayer.new(marker)
        local instance = {}
        for k, v in pairs(TicTacToePlayer) do
            instance[k] = v
        end
        instance._marker = marker
        instance.network = getTTTNN()
        return instance
    end

    function TicTacToePlayer:getTerminalStateByPerformingSimulationFromState(state)
        return state
    end

    function TicTacToePlayer:getMarker()
        return self._marker
    end

    local function stateToNNInput(state, marker)
        local board = state:getBoard()
        local input = {}
        for i = 1, #board do
            for j = 1, #board[1] do
                local val = 0.5
                local m = board[i][j]
                if m == marker then
                    val = 1
                elseif m ~= "-" then
                    val = 0
                end
                input[#input + 1] = val
            end
        end
        return input
    end

    function TicTacToePlayer:getRewardFromTerminalState(state)
        if state:isDraw() then
            return 0.5
        elseif state:specificPlayerWon(self) then
            return 1
        elseif state:isTerminal() then
            return 0
        end
        local input = stateToNNInput(state, self:getMarker())
        return self.network:predict(input)[1]
    end

    return TicTacToePlayer
end
TicTacToePlayer = _m_init()
_m_init = nil
