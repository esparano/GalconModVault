require("mod_assert")
require("mod_common_utils")
require("mod_uniform_crossover")
require("mod_list_chromosome")

function before_each()
end

function test_available_functions()
    assert.not_nil(UniformCrossover)
    assert.not_nil(UniformCrossover.new)
    assert.not_nil(UniformCrossover.crossover)
end

function test_local_functions()
    assert.is_nil(new)
    assert.is_nil(crossover)
end

function test_constructor_bad_params()
    UniformCrossover.new(-0.1)
    UniformCrossover.new(1.1)
end

function test_crossover()
    local policy = UniformCrossover.new(0.8)

    local p1 = ListChromosome.new({1, 1, 1, 1, 1, 1, 1, 1, 1, 1})
    local p2 = ListChromosome.new({0, 0, 0, 0, 0, 0, 0, 0, 0, 0})

    local c1, c2 = policy:crossover(p1, p2)

    local c1Sum = common_utils.sumList(c1.representation)
    local c2Sum = common_utils.sumList(c2.representation)

    assert.is_true(c1Sum < c2Sum)
    assert.equals(10, c1Sum + c2Sum)
end


require("mod_test_runner")
