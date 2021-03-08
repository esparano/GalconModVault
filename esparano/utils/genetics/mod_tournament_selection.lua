require("mod_assert")
require("mod_common_utils")
require("mod_elitist_population")

function _m_init()
    local TournamentSelection = {}

    -- a good rule of thumb is that tournament size should be ~20% of population size
    function TournamentSelection.new(arity)
        local instance = {}
        for k, v in pairs(TournamentSelection) do
            instance[k] = v
        end
        
        assert.not_nil(arity, "arity cannot be nil")
        assert.is_true(arity > 0, "arity " .. arity .. " must be greater than 0")

        instance.arity = arity

        return instance
    end

    function TournamentSelection:selectParents(population)
        return self:tournament(population), self:tournament(population)
    end

    function TournamentSelection:tournament(population)
        local popSize = population:getPopulationSize()
        assert.is_true(popSize >= self.arity, "population size " .. popSize .. 
            " must be greater than arity " .. self.arity)

        local tournamentPopulation = ElitistPopulation.new(self.arity)
        -- add chromosomes to tournament population, without duplicates
        local chromosomeList = common_utils.shallow_copy(population.chromosomes)
        for i=1, self.arity do
            local randomChromosome = table.remove(chromosomeList, math.random(1, #chromosomeList))
            tournamentPopulation:addChromosome(randomChromosome)
        end

        return tournamentPopulation:getFittestChromosome()
    end

    return TournamentSelection
end
TournamentSelection = _m_init()
_m_init = nil
