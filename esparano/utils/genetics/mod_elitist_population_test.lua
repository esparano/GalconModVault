require("mod_assert")
require("mod_elitist_population")
require("mod_list_chromosome")

function before_each()
end

function test_available_functions()
    assert.not_nil(ElitistPopulation)
    assert.not_nil(ElitistPopulation.new)
    assert.not_nil(ElitistPopulation.getPopulationSize)
    assert.not_nil(ElitistPopulation.isFull)
    assert.not_nil(ElitistPopulation.hasBeenFullyEvaluated)
    assert.not_nil(ElitistPopulation.nextGeneration)
    assert.not_nil(ElitistPopulation.addChromosome)
    assert.not_nil(ElitistPopulation.getFittestChromosome)
end

function test_local_functions()
    assert.is_nil(new)
    assert.is_nil(getPopulationSize)
    assert.is_nil(isFull)
    assert.is_nil(hasBeenFullyEvaluated)
    assert.is_nil(nextGeneration)
    assert.is_nil(addChromosome)
    assert.is_nil(getFittestChromosome)
end

function test_constructor_bad_params()
    ElitistPopulation.new(0, 0)
    ElitistPopulation.new(1, -0.1)
    ElitistPopulation.new(1, 1.1)
end

function test_getPopulationSize()
    local p = ElitistPopulation.new(1)

    assert.equals(0, p:getPopulationSize())
    p:addChromosome(ListChromosome.new({}))
    assert.equals(1, p:getPopulationSize())
end

function test_isFull()
    local p = ElitistPopulation.new(3)
    assert.is_false(p:isFull())

    p:addChromosome(ListChromosome.new({}))
    assert.is_false(p:isFull())

    p:addChromosome(ListChromosome.new({}))
    assert.is_false(p:isFull())

    p:addChromosome(ListChromosome.new({}))
    assert.is_true(p:isFull())
end

function test_tooManyChromosomes()
    local p = ElitistPopulation.new(1)
    p:addChromosome(ListChromosome.new({}))
    p:addChromosome(ListChromosome.new({}))
end

function test_hasBeenFullyEvaluated()
    local p = ElitistPopulation.new(2)

    local c1 = ListChromosome.new({})
    c1.fitness = 1
    p:addChromosome(c1)
    assert.is_true(p:hasBeenFullyEvaluated())

    p:addChromosome(ListChromosome.new({}))
    assert.is_false(p:hasBeenFullyEvaluated())
end

function test_getFittestChromosome()
    local p = ElitistPopulation.new(4)

    local fittest = ListChromosome.new({}, 10)
    p:addChromosome(fittest)
    p:addChromosome(ListChromosome.new({}, 1))
    p:addChromosome(ListChromosome.new({}, 4))
    p:addChromosome(ListChromosome.new({}, 2))

    assert.equals(fittest, p:getFittestChromosome())
end

function test_getFittestChromosome_notFullyEvaluated()
    local p = ElitistPopulation.new(2)

    local fittest = ListChromosome.new({}, 10)
    p:addChromosome(fittest)
    assert.equals(fittest, p:getFittestChromosome())

    p:addChromosome(ListChromosome.new({}))
    assert.equals(fittest, p:getFittestChromosome())
end

function test_nextGeneration()
    local p = ElitistPopulation.new(4, 0.7)

    p:addChromosome(ListChromosome.new({}, 1))
    p:addChromosome(ListChromosome.new({}, -6))
    p:addChromosome(ListChromosome.new({}, 10))
    p:addChromosome(ListChromosome.new({}, 0))

    local p2 = p:nextGeneration()
    assert.equals(3, p2:getPopulationSize())
    assert.equals(10, p2.chromosomes[1].fitness)
    assert.equals(1, p2.chromosomes[2].fitness)
    assert.equals(0, p2.chromosomes[3].fitness)

    p2:addChromosome(ListChromosome.new({}, 100))

    local p3 = p2:nextGeneration()
    assert.equals(3, p3:getPopulationSize())
    assert.equals(100, p3.chromosomes[1].fitness)
    assert.equals(10, p3.chromosomes[2].fitness)
    assert.equals(1, p3.chromosomes[3].fitness)
end

require("mod_test_runner")
