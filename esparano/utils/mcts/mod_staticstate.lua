function _m_init()
local StaticState = {}

function StaticState:isTerminal()
    return false
end

function StaticState:getCurrentAgent()
    return nil
end

function StaticState:getPreviousAgent()
    return nil
end

function StaticState:getNumAvailableActions()
    return self:getAvailableActions():size()
end
 
function StaticState:getAvailableActions()
    return self._availableActions
end

function StaticState:applyAction(action)
    return self
end

function StaticState:skipCurrentAgent() 
    return self
end

function StaticState.new(availableActions)
    local instance = {}
    for k, v in pairs(StaticState) do
        instance[k] = v
    end
    instance._availableActions = availableActions
	return instance
end

return StaticState
end; StaticState = _m_init(); _m_init = nil