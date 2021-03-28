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
end

function test_local_functions()
    assert.is_nil(add)
    assert.is_nil(addAll)
    assert.is_nil(remove)
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

function test_diff()
    local set = Set.new()
    set:add(5)
    set:add(1)
    local set2 = Set.new()
    set2:add(1)
    local left_diff = set:diff(set2)
    local right_diff = set2:diff(set)

    assert.is_true(left_diff:contains(5))
    assert.is_false(left_diff:contains(1))

    assert.is_false(right_diff:contains(5))
    assert.is_false(right_diff:contains(1))
end

function test_diff_empty()
    local set = Set.new()
    set:add(5)
    set:add(1)
    local set2 = Set.new()
    local left_diff = set:diff(set2)
    local right_diff = set2:diff(set)

    assert.is_true(left_diff:contains(5))
    assert.is_true(left_diff:contains(1))

    assert.is_false(right_diff:contains(5))
    assert.is_false(right_diff:contains(1))
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
