require("mod_eval")
require("mod_memoize")
require("mod_assert")

function _m_init()
    local GalconPlayer = {}

    local MAX_ACTIONS_TO_GENERATE = 10

    local cachedFunctions = {
        "getAvailableActions"
    }

    function GalconPlayer.new(userN)
        local instance = {}
        for k, v in pairs(GalconPlayer) do
            instance[k] = v
        end

        -- set up memoization of key functions
        instance.caches = {}
        for _, funcName in pairs(cachedFunctions) do
            instance.caches[funcName] = {}
            instance[funcName] = memoize(instance[funcName], instance.caches[funcName])
        end

        instance._n = userN
        return instance
    end

    local function sanityChecks(self, state)
        assert.not_equals(self._n, state._map:getNeutralUser().n, "ERROR: GalconPlayer was created from Neutral user")
    end

    -- This is memoized, so state can't change in between
    -- calls to this and getRewardFromState
    function GalconPlayer:getAvailableActions(state)
        sanityChecks(self, state)
        local availableActions = Set.new()

        --availableActions:add(state.generateNullMove())
        for i = 1, MAX_ACTIONS_TO_GENERATE do
            local from_options = state._map:getPlanetList(self._n)
            local to_options = state._map:getPlanetList()
            local from = from_options[math.random(1, #from_options)]
            local to = to_options[math.random(1, #to_options)]

            -- Make sure planet doesn't send to itself
            while from == to do
                to = to_options[math.random(1, #to_options)]
            end

            -- s for send, r for redirect
            local action = state.generateSendAction(from, to, 100)
            availableActions:add(action)
        end

        return availableActions
    end

    function GalconPlayer:requiresDeepCopyToSimulate()
        return false
    end

    function GalconPlayer:simulateUntilTerminal(state)
        -- simply return the state and use the predicted evaluation by the NN as the eval
        -- Or maybe land fleets, or sim forwards X seconds, then eval? who knows.
        return state
    end

    function GalconPlayer:getRewardFromState(state)
        sanityChecks(self, state)
        if state:specificPlayerWon(self) then
            return 1
        elseif state:specificPlayerLost(self) then
            return -1
        end
        return eval_predict_with_map(state._map, state._map._items[self._n])
    end

    return GalconPlayer
end
GalconPlayer = _m_init()
_m_init = nil
