require("mod_map_sim")
require("mod_set")
require("mod_assert")

function _m_init()
    local GalconState = {}

    local NEXT_STATE_ID = 0
    GalconState.NULL_MOVE = "n"
    GalconState.SEND = "s"
    GalconState.REDIRECT = "r"

    local function split(str, delim)
        local r = {}
        local result = string.gmatch(str .. delim, "([^" .. delim .. "]*)" .. delim)
        for k in result do
            r[#r + 1] = k
        end
        return r
    end

    function GalconState.parseMove(str, map)
        local t = split(str, ",")
        local move = {}
        move.actionType = t[1]
        move.from = map._items[tonumber(t[2])]
        move.to = map._items[tonumber(t[3])]
        move.perc = tonumber(t[4])
        return move
    end

    function GalconState:_doApplyAction(str)
        -- Do nothing when switching players to simulate simultaneous actions?
        -- TODO: send from planet, update planet shipcount
        if str == GalconState.NULL_MOVE then
            return
        end
        local move = GalconState.parseMove(str, self._map)
        if move.actionType == GalconState.SEND then
            MapSim.send(self._map, move.from, move.to, move.perc)
        elseif move.actionType == GalconState.REDIRECT then
            MapSim.redirect(self._map, move.from, move.to)
        else
            error("UNRECOGNIZED ACTION TYPE")
        end
    end

    -- TODO: verify action is in possible actions, owned by player, enough ships, target exists.
    local function validateAction(self, action)
        -- This is commented out because the state on which getAvailableActions() was called is not the same as this copy of that state.
        -- Thus calling getAvailableActions for this state may not return the same list.
        --assert.is_true(self:getAvailableActions():contains(action), "availableActions should contain action")
    end

    function GalconState:applyAction(action)
        validateAction(self, action)
        self:_doApplyAction(action)
        -- TODO: don't simulate forward if owner is not the bot - simultaneous turns
        -- TODO: go back to default timestep
        MapSim.simulate(self._map, 1)
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
        if agent == self._currentAgent then
            return self._previousAgent
        else
            return self._currentAgent
        end
    end

    function GalconState:specificPlayerWon(agent)
        return self:specificPlayerLost(self:getOppositeAgent(agent))
    end

    function GalconState:specificPlayerLost(agent)
        -- TODO: why doesn't equals 0 work?
        return self._map:totalProd(agent._n) < 0.1 and self._map:totalShips(agent._n) < 0.1
    end

    function GalconState:isTerminal()
        return self:specificPlayerLost(self._currentAgent) or self:specificPlayerLost(self._previousAgent)
    end

    function GalconState:skipCurrentAgent()
        error("skipCurrentAgent called")
        -- Isn't this wrong? Shouldn't this switch agents?
        return self
    end

    -- TODO: this is wrong or extremely inefficient
    function GalconState:getNumAvailableActions()
        return self:getAvailableActions():size()
    end

    function GalconState.generateNullMove()
        return GalconState.NULL_MOVE
    end

    function GalconState.generateSendAction(from, to, perc)
        return GalconState.SEND .. "," .. from.n .. "," .. to.n .. "," .. perc
    end

    function GalconState.generateRedirectAction(from, to)
        return GalconState.REDIRECT .. "," .. from.n .. "," .. to.n
    end

    -- TODO: eventually replace this with NN and prior probabilities
    function GalconState:getAvailableActions()
        return self._currentAgent:getAvailableActions(self)
    end

    function GalconState.new(map, currentAgent, previousAgent)
        local instance = {}
        for k, v in pairs(GalconState) do
            instance[k] = v
        end
        instance._map = map
        instance._currentAgent = currentAgent
        instance._previousAgent = previousAgent
        -- for debugging purposes
        instance._id = NEXT_STATE_ID
        NEXT_STATE_ID = NEXT_STATE_ID + 1
        return instance
    end

    return GalconState
end
GalconState = _m_init()
_m_init = nil
