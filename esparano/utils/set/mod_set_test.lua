require("mod_assert")
require("mod_set")

function test_available_functions()
    for k, v in pairs(_ENV) do
        --print(k)
    end
    assert.not_nil(Set)
    assert.not_nil(Set.add)
    assert.not_nil(Set.addAll)
    assert.not_nil(Set.remove)
    assert.not_nil(Set.contains)
    assert.not_nil(Set.difference)
    assert.not_nil(Set.symmetricDifference)
    assert.not_nil(Set.contains)
end

function test_local_functions()
    assert.is_nil(add)
    assert.is_nil(addAll)
    assert.is_nil(remove)
    assert.is_nil(contains)
    assert.is_nil(difference)
    assert.is_nil(symmetricDifference)
    assert.is_nil(contains)
end

function test_constructor()
    local set = Set.new({4, 8, 6})
    set:add("asdf")
    assert.is_true(set:contains(4))
    assert.is_true(set:contains(6))
    assert.is_true(set:contains(8))
    assert.is_true(set:contains("asdf"))
    assert.is_false(set:contains(346))
end

function test_add_remove_and_contains()
    local set = Set.new()
    assert.equals(0, set:size())

    set:add("asdf")
    assert.equals(1, set:size())
    assert.is_true(set:contains("asdf"))
    assert.is_false(set:contains(346))

    set:remove("asdf")
    assert.equals(0, set:size())
    assert.is_false(set:contains("asdf"))
end

function test_add_remove_and_contains_table()
    local set = Set.new()
    local t = {value = 1}

    set:add(t)
    assert.equals(1, set:size())
    assert.is_true(set:contains(t))
    assert.is_false(set:contains({value = 1}))

    set:remove(t)
    assert.equals(0, set:size())
    assert.is_false(set:contains(t))
end

function test_difference()
    local set = Set.new()
    set:add(5)
    set:add(1)
    local set2 = Set.new()
    set2:add(1)
    local left_diff = set:difference(set2)
    local right_diff = set2:difference(set)

    assert.is_true(left_diff:contains(5))
    assert.is_false(left_diff:contains(1))

    assert.is_false(right_diff:contains(5))
    assert.is_false(right_diff:contains(1))
end

function test_difference_empty()
    local set = Set.new()
    set:add(5)
    set:add(1)
    local set2 = Set.new()
    local left_diff = set:difference(set2)
    local right_diff = set2:difference(set)

    assert.is_true(left_diff:contains(5))
    assert.is_true(left_diff:contains(1))

    assert.is_false(right_diff:contains(5))
    assert.is_false(right_diff:contains(1))
end

function test_symmetric_difference()
    local set = Set.new()
    set:add(5)
    set:add(1)
    local set2 = Set.new()
    set2:add(1)
    local left_diff = set:symmetricDifference(set2)
    local right_diff = set2:symmetricDifference(set)

    assert.equals(1, left_diff:size())
    assert.is_true(left_diff:contains(5))
    assert.is_false(left_diff:contains(1))

    assert.equals(1, right_diff:size())
    assert.is_true(right_diff:contains(5))
    assert.is_false(right_diff:contains(1))
end

function test_symmetric_difference_empty()
    local set = Set.new()
    set:add(5)
    set:add(1)
    local set2 = Set.new()
    local left_diff = set:symmetricDifference(set2)
    local right_diff = set2:symmetricDifference(set)

    assert.equals(2, left_diff:size())
    assert.is_true(left_diff:contains(5))
    assert.is_true(left_diff:contains(1))

    assert.equals(2, right_diff:size())
    assert.is_true(right_diff:contains(5))
    assert.is_true(right_diff:contains(1))
end

function test_union()
    local set = Set.new()
    set:add(5)
    set:add(1)
    local set2 = Set.new()
    set2:add(7)
    set2:add(5)
    local union = set:union(set2)

    assert.is_true(union:contains(5))
    assert.is_true(union:contains(1))
    assert.is_true(union:contains(7))
    assert.equals(3, union:size())

    local reverseUnion = set2:union(set)
    assert.is_true(reverseUnion:contains(5))
    assert.is_true(reverseUnion:contains(1))
    assert.is_true(reverseUnion:contains(7))
    assert.equals(3, reverseUnion:size())

    assert.equals(0, union:symmetricDifference(reverseUnion):size())
end

function test_union_empty()
    local set = Set.new()
    set:add(5)
    set:add(1)
    local set2 = Set.new()
    local union = set:union(set2)

    assert.is_true(union:contains(5))
    assert.is_true(union:contains(1))
    assert.equals(2, union:size())

    local reverseUnion = set2:union(set)
    assert.is_true(reverseUnion:contains(5))
    assert.is_true(reverseUnion:contains(1))
    assert.equals(2, reverseUnion:size())

    assert.equals(0, union:symmetricDifference(reverseUnion):size())
end

function test_random_item()
    local set = Set.new()
    assert.is_nil(set:randomItem())

    set:add(5)
    set:add(7)
    set:add(4)
    set:add(2)
    set:add("asdf")
    assert.equals(5, set:size())
    local iterations = 1000
    counts = {}
    for i = 1, iterations do
        local randomItem = set:randomItem()
        counts[randomItem] = counts[randomItem] or 0
        counts[randomItem] = counts[randomItem] + 1
    end
    local sum = 0
    for item, count in pairs(counts) do
        assert.is_true(count > 140)
        sum = sum + count
    end
    assert.equals(iterations, sum)
end

function test_random_item_empty()
    local set = Set.new()
    assert.is_nil(set:randomItem())
end

function init()
end

function loop(t)
end

function event(e)
end

require("mod_test_runner")
