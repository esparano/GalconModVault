require("mod_assert")
require("mod_mcts")

function test_available_functions()
    assert.not_equals(nil, MctsTreeNode)
    assert.not_equals(nil, MctsTreeNode.new)
    local root = MctsTreeNode.new({}, function(c) return c end)
    for k,v in pairs(root) do
        --print(k)
    end
end

function test_local_functions()
    assert.equals(nil, new)
end

function test_imports_cleaned_up()
    --TODO: should we clean up imports?
    --assert.equals(nil, Set)
end

function init()
end

function loop(t)
end

function event(e)
end

require("mod_test_runner")