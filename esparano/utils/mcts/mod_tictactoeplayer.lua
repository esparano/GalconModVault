function _m_init()
    local TicTacToePlayer = {}

    function TicTacToePlayer.new(marker)
        local instance = {}
        for k, v in pairs(TicTacToePlayer) do
            instance[k] = v
        end
        instance._marker = marker
        return instance
    end

    -- TODO: test this
    local function pickFromAvailableActions(state)
        local availableActions = state:getAvailableActions()
        for action in pairs(availableActions:getValues()) do
            state:applyAction(action)
            local actionEndsGame = state:isTerminal()
            state:undoAction(action)
            if actionEndsGame then
                return action
            end
        end
        return availableActions:randomItem()
    end

    function TicTacToePlayer:getTerminalStateByPerformingSimulationFromState(state)
        while not state:isTerminal() do
            local action = pickFromAvailableActions(state)
            state:applyAction(action)
        end
        return state
    end

    function TicTacToePlayer:getMarker()
        return self._marker
    end

    function TicTacToePlayer:getRewardFromState(terminalState)
        if terminalState:specificPlayerWon(self) then
            return 1
        elseif terminalState:isDraw() then
            return 0.5
        end
        return 0
    end

    return TicTacToePlayer
end
TicTacToePlayer = _m_init()
_m_init = nil
