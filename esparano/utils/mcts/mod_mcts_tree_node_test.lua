require("mod_assert")
require("mod_mcts_tree_node")
require("mod_staticstate")
require("mod_set")

local allPossibleActions
local availableactions
local rootNode
local state

local function deepCopy(o)
    if type(o) ~= "table" then
        return o
    end
    local r = {}
    for k, v in pairs(o) do
        r[k] = deepCopy(v)
    end
    return r
end

function before_each()
    allPossibleActions = Set.new({"0", "1", "2"})
    availableActions = Set.new({"0", "1"})
    state = StaticState.new(availableActions)
    rootNode = MctsTreeNode.new(state, deepCopy)
end

function test_available_functions()
    assert.not_nil(MctsTreeNode)
    assert.not_nil(MctsTreeNode.new)
    local root =
        MctsTreeNode.new(
        {},
        function(c)
            return c
        end
    )
    for k, v in pairs(root) do
        --print(k)
    end
end

function test_local_functions()
    assert.is_nil(new)
end

function test_imports_cleaned_up()
    -- TODO: Do this???
    --assert.is_nil(Set)
end

function test_has_child_nodes()
    local root =
        MctsTreeNode.new(
        {},
        function(c)
            return c
        end
    )
    assert.is_false(root:hasChildNodes())
    root:getChildNodes()[1] = {}
    assert.is_true(root:hasChildNodes())
end

function test_has_unvisited_child()
    local root =
        MctsTreeNode.new(
        {},
        function(c)
            return c
        end
    )
    assert.is_false(root:hasUnvisitedChild())
    root:getChildNodes()[1] = {
        isUnvisited = function()
            return false
        end
    }
    assert.is_false(root:hasUnvisitedChild())
    root:getChildNodes()[1] = {
        isUnvisited = function()
            return true
        end
    }
    assert.is_true(root:hasUnvisitedChild())
end

function test_getDeepStateClone()
    local clone = rootNode:getDeepStateClone()
    assert.not_equals(state, clone)
end

function test_getUntriedActions()
    local untried = rootNode:getUntriedActions()
    assert.equals(2, untried:size())
    assert.is_true(untried:contains("0"))
    assert.is_true(untried:contains("1"))

    rootNode:addNewChildFromAction("0")
    untried = rootNode:getUntriedActions()
    assert.equals(1, untried:size())
    assert.is_true(untried:contains("1"))

    rootNode:addNewChildFromAction("1")
    untried = rootNode:getUntriedActions()
    assert.equals(0, untried:size())
end

function test_addNewChildFromInvalidAction()
    print("assertion failure expected:")
    rootNode:addNewChildFromAction("87")
end

function test_addNewChildFromTriedAction()
    rootNode:addNewChildFromAction("1")
    print("assertion failure expected:")
    rootNode:addNewChildFromAction("1")
end

function test_isFullyExpanded()
    assert.is_false(rootNode:isFullyExpanded())
    rootNode:addNewChildFromAction("1")
    assert.is_false(rootNode:isFullyExpanded())
    rootNode:addNewChildFromAction("0")
    assert.is_true(rootNode:isFullyExpanded())
end

function init()
end

function loop(t)
end

function event(e)
end

require("mod_test_runner")
