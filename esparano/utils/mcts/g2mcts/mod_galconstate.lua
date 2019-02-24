require("mod_map_sim")
require("mod_set")

function _m_init()
    local GalconState = {}

    local NULL_MOVE = -1
    local SEND = "s"
    local REDIRECT = "r"

    local function split(str, delim)
        local r = {}
        for k in (str .. delim):gmatch("([^" .. delim .. "]*)" .. delim) do
            r[#r + 1] = k
        end
        return r
    end

    local function doApplyAction(self, action)
        -- Do nothing when switching players to simulate simultaneous actions?
        -- TODO: send from planet, update planet shipcount
        if action == NULL_MOVE then
            return
        end
        local t = split(action, ",")
        local type = t[1]
        local from = self._map.items[t[2]]
        local to = self._map.items[t[3]]
        local perc = t[4]

        if type == GalconState.SEND then
            MapSim.send(self._map, from, to, perc)
        elseif type == GalconState.REDIRECT then
            MapSim.redirect(self._map, from, to)
        else
            error("UNRECOGNIZED ACTION TYPE")
        end
    end

    -- TODO: verify action is in possible actions, owned by player, enough ships, target exists.
    local function validateAction(self, action)
        assert.is_true(self:getAvailableActions():contains(action))
    end

    function GalconState:applyAction(action)
        validateAction(self, action)
        doApplyAction(self, action)
        -- TODO: don't simulate forward if owner is not the bot - simultaneous turns
        MapSim.simulateForward(self._map)
        self:_selectNextPlayer()
        return self
    end

    function GalconState:_selectNextPlayer()
        local tmp = self._currentAgent
        self._currentAgent = self._previousAgent
        self._previousAgent = tmp
    end

    function GalconState:getCurrentAgent()
        return self._currentAgent
    end

    function GalconState:getPreviousAgent()
        return self._previousAgent
    end

    function GalconState:getOppositeAgent(agent)
        if agent == self.currentAgent then
            return self.previousAgent
        else
            return currentAgent
        end
    end

    function GalconState:specificPlayerWon(agent)
        return self:specificPlayerLost(getOppositeAgent(agent))
    end

    function GalconState:specificPlayerLost(agent)
        return self._map:totalProd(agent._n) == 0 and self._map:totalShips(agent._n) == 0
    end

    function GalconState:isTerminal()
        return self:specificPlayerLost(self._currentAgent or self:specificPlayerLost(self._previousAgent))
    end

    function GalconState:skipCurrentAgent()
        -- Isn't this wrong? Shouldn't this switch agents?
        return self
    end

    -- TODO: this is wrong or extremely inefficient
    function GalconState:getNumAvailableActions()
        return self:getAvailableActions():size()
    end

    function GalconState.generateNullMove()
    end

    function GalconState.generateSendAction(from, to, perc)
        return SEND .. "," .. from.n .. "," .. to.n .. "," .. perc
    end

    function GalconState.generateRedirectAction(from, to)
        return REDIRECT .. "," .. from.n .. "," .. to.n
    end

    -- TODO: eventually replace this with NN and prior  probabilities
    function GalconState:getAvailableActions()
        return self._currentAgent:getAvailableActions(self._map)
    end

    function GalconState.new(map, currentAgent, previousAgent)
        local instance = {}
        for k, v in pairs(GalconState) do
            instance[k] = v
        end
        instance._map = map
        instance._currentAgent = currentAgent
        instance._previousAgent = previousAgent
        return instance
    end

    return GalconState
end
GalconState = _m_init()
_m_init = nil
