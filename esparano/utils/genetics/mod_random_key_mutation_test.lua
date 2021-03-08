require("mod_assert")
require("mod_common_utils")
require("mod_random_key_mutation")
require("mod_list_chromosome")

function before_each()
end

function test_available_functions()
    assert.not_nil(RandomKeyMutation)
    assert.not_nil(RandomKeyMutation.new)
    assert.not_nil(RandomKeyMutation.mutate)
end

function test_local_functions()
    assert.is_nil(new)
    assert.is_nil(mutate)
end

function test_mutate()
    local policy = RandomKeyMutation.new()

    local p = ListChromosome.new({1, 1, 1, 1, 1, 1, 1, 1, 1, 1})

    local c = policy:mutate(p)

    local pSum = common_utils.sumList(p.representation)
    local cSum = common_utils.sumList(c.representation)

    assert.equals(10, pSum)
    assert.is_true(cSum < 10)
    assert.is_true(cSum >= 9)
end

function test_mutate_with_keys()
    local policy = RandomKeyMutation.new() 

    local p = ListChromosome.new({someKey=1, anotherKey=1})

    local c = policy:mutate(p)

    assert.equals(p.representation.someKey, p.representation.anotherKey)
    assert.not_equals(c.representation.someKey, c.representation.anotherKey)
end

require("mod_test_runner")
