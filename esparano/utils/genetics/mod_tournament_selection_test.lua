require("mod_assert")
require("mod_tournament_selection")
require("mod_list_chromosome")
require("mod_elitist_population")

function before_each()
end

function test_available_functions()
    assert.not_nil(TournamentSelection)
    assert.not_nil(TournamentSelection.new)
    assert.not_nil(TournamentSelection.tournament)
    assert.not_nil(TournamentSelection.selectParents)
end

function test_local_functions()
    assert.is_nil(new)
    assert.is_nil(tournament)
    assert.is_nil(selectParents)
end

function test_tournament()
    local policy = TournamentSelection.new(2)

    local c1 = ListChromosome.new({})
    c1.fitness = 10
    local c2 = ListChromosome.new({})
    c2.fitness = 2
    local c3 = ListChromosome.new({})
    c3.fitness = 11

    local pop = ElitistPopulation.new(3)
    pop:addChromosome(c1)
    pop:addChromosome(c2)
    pop:addChromosome(c3)

    -- check c2 is never selected
    for i=1,10 do 
        local selected = policy:tournament(pop)
        assert.is_true(selected.fitness > c2.fitness)
    end

    local selected = policy:tournament(pop)
    selected.fitness = 1000

    -- In this case, I do want the returned chromosome to be the same reference
    assert.is_true(c1.fitness + c3.fitness > 1000)
end

function test_tournament_arity_equal_population_size()
    local policy = TournamentSelection.new(3)

    local c1 = ListChromosome.new({})
    c1.fitness = 10
    local c2 = ListChromosome.new({})
    c2.fitness = 2
    local c3 = ListChromosome.new({})
    c3.fitness = 11

    local pop = ElitistPopulation.new(3)
    pop:addChromosome(c1)
    pop:addChromosome(c2)
    pop:addChromosome(c3)

    -- check c3 is always selected
    for i=1,100 do 
        local selected = policy:tournament(pop)
        assert.equals(11, selected.fitness)
    end
end

require("mod_test_runner")
