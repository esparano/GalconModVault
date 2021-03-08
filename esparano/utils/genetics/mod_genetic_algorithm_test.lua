require("mod_assert")
require("mod_common_utils")
require("mod_genetic_algorithm")
require("mod_evaluation_policy")
require("mod_tournament_selection")
require("mod_uniform_crossover")
require("mod_random_key_tweak_mutation")
require("mod_elitist_population")
require("mod_list_chromosome")

local selectionPolicy = TournamentSelection.new(2)
local crossoverPolicy = UniformCrossover.new(0.6)
local mutationPolicy = RandomKeyTweakMutation.new()
function before_each()
end

function test_available_functions()
    assert.not_nil(GeneticAlgorithm)
    assert.not_nil(GeneticAlgorithm.new)
    assert.not_nil(GeneticAlgorithm.evolve)
    assert.not_nil(GeneticAlgorithm.nextGeneration)
end

function test_local_functions()
    assert.is_nil(new)
    assert.is_nil(evolve)
    assert.is_nil(nextGeneration)
end

function test_constructor_bad_params()
    local evaluationPolicy = EvaluationPolicy.new(function(dummy) end)

    GeneticAlgorithm.new(selectionPolicy, crossoverPolicy, -0.1, mutationPolicy, 0.5, evaluationPolicy)
    GeneticAlgorithm.new(selectionPolicy, crossoverPolicy, 1.1, mutationPolicy, 0.5, evaluationPolicy)
    GeneticAlgorithm.new(selectionPolicy, crossoverPolicy, 0.5, mutationPolicy, -0.1, evaluationPolicy)
    GeneticAlgorithm.new(selectionPolicy, crossoverPolicy, 0.5, mutationPolicy, 1.1, evaluationPolicy)
end

function test_nextGeneration()
    local evaluationPolicy = EvaluationPolicy.new(function(population) 
        for k,chromosome in pairs(population.chromosomes) do 
            chromosome.fitness = chromosome.fitness or math.random()
        end
    end)

    local geneticAlgorithm = GeneticAlgorithm.new(selectionPolicy, crossoverPolicy, 0.8, mutationPolicy, 0.01, evaluationPolicy)

    local p = ElitistPopulation.new(50)
    for i = 1,50 do 
        p:addChromosome(ListChromosome.new({someProperty = 0.1}))
    end
    evaluationPolicy:evaluateFitness(p)

    local newP = geneticAlgorithm:nextGeneration(p)

    assert.equals(p:getPopulationSize(), newP:getPopulationSize())
    assert.is_true(newP:isFull())
end

function test_evolve()
    local stoppingConditionFunc = function(population) 
        return population:getFittestChromosome().fitness > 0.99
    end
    local evaluationPolicy = EvaluationPolicy.new(function(population) 
        for k,c in ipairs(population.chromosomes) do 
            c.fitness = c.fitness or c.representation.someProperty
        end 
    end)

    local geneticAlgorithm = GeneticAlgorithm.new(selectionPolicy, crossoverPolicy, 0.8, mutationPolicy, 0.1, evaluationPolicy)

    local p = ElitistPopulation.new(50, 0.8)
    for i = 1,50 do 
        p:addChromosome(ListChromosome.new({someProperty = 0.1}))
    end

    local endingPopulation = geneticAlgorithm:evolve(p, stoppingConditionFunc)

    assert.equals(p:getPopulationSize(), endingPopulation:getPopulationSize())
    assert.is_true(endingPopulation:isFull())
    assert.is_true(endingPopulation:getFittestChromosome().fitness > 0.99)

    print("Took " .. geneticAlgorithm.generationsEvolved .. " generations to converge")
end

function test_evolve_square()
    local stoppingConditionFunc = function(population)
        return population:getFittestChromosome().fitness > 0.99
    end
    local evaluationPolicy = EvaluationPolicy.new(function(population)
        for k,c in ipairs(population.chromosomes) do
            c.fitness = c.fitness or c.representation.x * c.representation.y
        end
    end)

    local geneticAlgorithm = GeneticAlgorithm.new(selectionPolicy, crossoverPolicy, 0.8, mutationPolicy, 0.1, evaluationPolicy)

    local p = ElitistPopulation.new(50, 0.5)
    for i = 1,50 do 
        p:addChromosome(ListChromosome.new({x = 0, y = 0}))
    end

    local endingPopulation = geneticAlgorithm:evolve(p, stoppingConditionFunc)

    assert.equals(p:getPopulationSize(), endingPopulation:getPopulationSize())
    assert.is_true(endingPopulation:isFull())
    assert.is_true(endingPopulation:getFittestChromosome().fitness > 0.99)

    print("Took " .. geneticAlgorithm.generationsEvolved .. " generations to converge")
end

require("mod_test_runner")
