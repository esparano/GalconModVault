require("mod_set")

function _m_init()
local MctsTreeNode = {}

local function new(parent, prevAction, state, cloneFunc)
    local instance = {}
    for k, v in pairs(MctsTreeNode) do
        instance[k] = v
    end
    instance._parent = parent
    instance._prevAction = prevAction
    instance._state = state
    instance._visitCount = 0
    instance._totalReward = 0
    instance._childNodes = {}
    instance._cloneFunc = cloneFunc
	return instance
end

function MctsTreeNode.new(state, cloneFunc)
    return new(nil, nil, state, cloneFunc)
end

function MctsTreeNode:getParent()
    return self._parent
end

function MctsTreeNode:getPrevAction()
    return self._prevAction
end

function MctsTreeNode:getVisitCount()
    return self._visitCount
end

function MctsTreeNode:getParentsVisitCount()
    return self._parent._visitCount
end

function MctsTreeNode:getChildNodes()
    return self._childNodes
end

function MctsTreeNode:hasChildNodes()
    return #self._childNodes > 0
end

function MctsTreeNode:isTerminal()
    return self._state:isTerminal()
end

function MctsTreeNode:getPreviousAgent()
    return self._state:getPreviousAgent()
end

function MctsTreeNode:statesCurrentAgentHasAvailableActions()
    return self._state:getNumAvailableActions() > 0
end

function MctsTreeNode:isFullyExpanded()
    return self._state:getNumAvailableActions() == #self._childNodes
end

function MctsTreeNode:isUnvisited()
    return self._visitCount == 0
end

function MctsTreeNode:hasUnvisitedChild()
    for _,child in ipairs(self._childNodes) do
        if child:isUnvisited() then
            return true
        end
    end
    return false
end

function MctsTreeNode:appendNewChildInstance(state, prevAction)
    local childNode = new(self, prevAction, state, self._cloneFunc)
    self._childNodes[#self._childNodes + 1] = childNode
    return childNode
end

function MctsTreeNode:addNewChildWithoutAction()
    local childState = self:getDeepStateClone()
    childState:skipCurrentAgent()
    return self:appendNewChildInstance(childState)
end

function MctsTreeNode:getNewStateFromAction(action)
    local stateClone = self:getDeepStateClone()
    stateClone:applyAction(action)
    return stateClone
end

function MctsTreeNode:addNewChildFromAction(action)
    assert.is_true(self:getUntriedActions():contains(action), "ERROR: Action was invalid or already tried")
    local childNodeState = self:getNewStateFromAction(action);
    return self:appendNewChildInstance(childNodeState, action);
end

function MctsTreeNode:getUntriedActions()
    local availableActions = self._state:getAvailableActions() -- set
    local triedActions = self:getTriedActionsForCurrentAgent()
    local untriedActions = availableActions:diff(triedActions)
    return untriedActions
end

function MctsTreeNode:getTriedActionsForCurrentAgent()
    local triedActions = Set.new()
    for _,child in ipairs(self._childNodes) do
        triedActions:add(child:getPrevAction())
    end
    return triedActions
end

-- TODO: this doesn't make any sense because clonefunc doesn't necessarily
-- return a deep clone
function MctsTreeNode:getDeepStateClone()
    return self._cloneFunc(self._state)
end

function MctsTreeNode:updateDomainTheoreticValue(rewardAdded)
    self._visitCount = self._visitCount + 1
    self._totalReward = self._totalReward + rewardAdded
end

function MctsTreeNode:getDomainTheoreticValue()
    return self._totalReward / self._visitCount
end

return MctsTreeNode
end MctsTreeNode = _m_init(); _m_init = nil
    