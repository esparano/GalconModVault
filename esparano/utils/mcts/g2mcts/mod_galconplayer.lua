require("mod_galconstate")
require("mod_eval")

function _m_init()
    local GalconPlayer = {}

    local MAX_ACTIONS_TO_GENERATE = 10

    function GalconPlayer.new(user)
        local instance = {}
        for k, v in pairs(GalconPlayer) do
            instance[k] = v
        end
        instance._user = user
        return instance
    end

    function GalconPlayer:getAvailableActions(state)
        local availableActions = Set.new()

        availableActions:add(GalconState.generateNullMove())
        for i = 2, MAX_ACTIONS_TO_GENERATE do
            local from_options = self._map:getPlanetList(self._currentAgent._n)
            local to_options = self._map:getPlanetList()
            local from = from_options[math.random(1, #from_options)]
            local target = to_options[math.random(1, #to_options)]

            -- Make sure planet doesn't send to itself
            while from == target do
                target = to_options[math.random(1, #to_options)]
            end

            -- s for send, r for redirect
            local action = GalconState.generateSendAction(from, to, 100)
            availableActions:add(action)
        end

        return availableActions
    end

    function GalconPlayer:getTerminalStateByPerformingSimulationFromState(state)
        -- simply return the state and use the predicted evaluation by the NN as the eval
        -- Or maybe land fleets, or sim forwards X seconds, then eval? who knows.
        return state
    end

    function GalconPlayer:getRewardFromState(state)
        if state:specificPlayerWon(self) then
            return 1
        elseif state:specificPlayerLost(self) then
            return 0
        end
        return eval_predict_with_map(state._map, self._user)
    end

    return GalconPlayer
end
GalconPlayer = _m_init()
_m_init = nil
