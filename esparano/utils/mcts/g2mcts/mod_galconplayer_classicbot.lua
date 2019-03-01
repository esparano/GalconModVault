require("mod_eval")
require("mod_memoize")
require("mod_assert")

-- search list for the best match by greatest result
local function find(Q, f)
    local r, v
    for _, o in pairs(Q) do
        local _v = f(o)
        if _v and ((not r) or _v > v) then
            r, v = o, _v
        end
    end
    return r
end
-- return distance between planets
local function dist(a, b)
    return ((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2) ^ 0.5
end

function _m_init()
    local GalconPlayer = {}

    local MAX_ACTIONS_TO_GENERATE = 100

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

        availableActions:add(state.generateNullMove())

        -- find a source planet
        local from_options = state._map:getPlanetList(self._n)
        for i, from in ipairs(from_options) do
            if from.ships >= 15 then
                -- find a target planet
                local to_options = state._map:getPlanetList()
                local to =
                    find(
                    to_options,
                    function(o)
                        if o.n ~= from.n and o.owner ~= from.owner then
                            return o.production - o.ships - 0.2 * dist(from, o)
                        end
                    end
                )

                -- s for send, r for redirect
                local action = state.generateSendAction(from, to, 65)
                availableActions:add(action)
            end
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
