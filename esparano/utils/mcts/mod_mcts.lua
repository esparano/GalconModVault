require("mod_mcts_tree_node")

function _m_init()
    local Mcts = {}

    local NO_EXPLORATION = 0

    function Mcts.new(cloneFunc)
        local instance = {}
        for k, v in pairs(Mcts) do
            instance[k] = v
        end
        instance._cloneFunc = cloneFunc
        return instance
    end

    local function calculateUctValue(node, explorationParameter)
        -- TODO: this needs to take prior probabilities into account
        return node:getDomainTheoreticValue() +
            explorationParameter * (math.sqrt((2 * math.log(node:getParentsVisitCount())) / node:getVisitCount()))
    end

    local function getNodesBestChildConfidentlyWithExploration(node, explorationParameter)
        local childNodes = node:getChildNodes()
        local best, bestVal = childNodes[1], -math.huge
        for i, node in ipairs(childNodes) do
            local val = calculateUctValue(node, explorationParameter)
            if val > bestVal then
                best, bestVal = node, val
            end
        end
        return best
    end

    local function validateBestChildComputable(node)
        assert.is_true(node:hasChildNodes(), "ERROR: child nodes must not be empty")
        assert.is_true(node:isFullyExpanded(), "ERROR: node must be fully expanded")
        assert.is_false(node:hasUnvisitedChild(), "ERROR: child nodes must all be visited")
    end

    local function getBestChildForNode(node, explorationParameter)
        validateBestChildComputable(node)
        return getNodesBestChildConfidentlyWithExploration(node, explorationParameter)
    end

    local function getRandomUntriedActionForNode(node)
        local untriedActionSet = node:getUntriedActions()
        return untriedActionSet:randomItem()
    end

    local function expandWithAction(node)
        local randomUntriedAction = getRandomUntriedActionForNode(node)
        return node:addNewChildFromAction(randomUntriedAction)
    end

    local function expandWithoutAction(node)
        return node:addNewChildWithoutAction()
    end

    local function treePolicy(node, explorationParameter)
        while not node:isTerminal() do
            -- TODO: something is wrong with this
            if not node:statesCurrentAgentHasAvailableActions() then
                return expandWithoutAction(node)
            elseif not node:isFullyExpanded() then
                return expandWithAction(node)
            else
                node = getBestChildForNode(node, explorationParameter)
            end
        end
        return node
    end

    local function getTerminalStateFromDefaultPolicy(node, agentInvoking)
        -- Possibly unnecessary depending on the behavior of the simulation
        local nodesStateClone = node:getDeepStateClone()
        return agentInvoking:getTerminalStateByPerformingSimulationFromState(nodesStateClone)
    end

    local function backPropagate(node, state)
        while node do
            local parentsStatesCurrentAgent = node:getPreviousAgent()
            local reward = parentsStatesCurrentAgent:getRewardFromState(state)
            node:updateDomainTheoreticValue(reward)
            node = node:getParent()
        end
    end

    local function getNodesMostPromisingAction(node)
        validateBestChildComputable(node)
        local bestChildWithoutExploration = getNodesBestChildConfidentlyWithExploration(node, NO_EXPLORATION)
        return bestChildWithoutExploration:getPrevAction()
    end

    function Mcts:startUtcSearch(state, explorationParameter)
        self._explorationParameter = explorationParameter
        self._rootNode = MctsTreeNode.new(state, self._cloneFunc)
        self._state = state
    end

    function Mcts:nextIteration()
        local selectedChildNode = treePolicy(self._rootNode, self._explorationParameter)
        local terminalState = getTerminalStateFromDefaultPolicy(selectedChildNode, self._state:getCurrentAgent())
        backPropagate(selectedChildNode, terminalState)
    end

    -- TODO: allow picking move stochastically
    function Mcts:finish()
        return getNodesMostPromisingAction(self._rootNode)
    end

    return Mcts
end
Mcts = _m_init()
_m_init = nil
