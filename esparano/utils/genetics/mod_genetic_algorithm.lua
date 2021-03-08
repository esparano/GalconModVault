function _m_init()
    local GeneticAlgorithm = {}

    function GeneticAlgorithm.new(selectionPolicy, crossoverPolicy, crossoverRate, mutationPolicy, mutationRate, evaluationPolicy)
        local instance = {}
        for k, v in pairs(GeneticAlgorithm) do
            instance[k] = v
        end
        
        assert.is_true(crossoverRate >= 0 and crossoverRate <= 1, "crossoverRate " .. crossoverRate .. " must be between 0 and 1")
        assert.is_true(mutationRate >= 0 and mutationRate <= 1, "mutationRate " .. mutationRate .. " must be between 0 and 1")

        instance.selectionPolicy = selectionPolicy
        instance.crossoverPolicy = crossoverPolicy
        instance.crossoverRate = crossoverRate
        instance.mutationPolicy = mutationPolicy
        instance.mutationRate = mutationRate
        instance.evaluationPolicy = evaluationPolicy
        instance.generationsEvolved = 0

        return instance
    end

    function GeneticAlgorithm:evolve(initialPopulation, stoppingConditionFunc)
        local current = initialPopulation
        self.generationsEvolved = 0
        repeat
            self.evaluationPolicy:evaluateFitness(current)
            current = self:nextGeneration(current)
            
        until stoppingConditionFunc(current)
        self.evaluationPolicy:evaluateFitness(current)
        return current
    end

    -- NOTE: it is expected that the population has been evaluated so that chromosome's fitnesses are not nil before this is called.
    function GeneticAlgorithm:nextGeneration(currentPopulation)
        local nextGeneration = currentPopulation:nextGeneration()

        while not nextGeneration:isFull() do
            local parent1, parent2 = self.selectionPolicy:selectParents(currentPopulation)
            parent1 = parent1.new(common_utils.copy(parent1.representation))
            parent2 = parent2.new(common_utils.copy(parent2.representation))
            
            if math.random() < self.crossoverRate then 
                parent1, parent2 = self.crossoverPolicy:crossover(parent1, parent2)
            end

            if math.random() < self.mutationRate then 
                parent1 = self.mutationPolicy:mutate(parent1)
                parent2 = self.mutationPolicy:mutate(parent2)
            end

            nextGeneration:addChromosome(parent1)
            if not nextGeneration:isFull() then 
                nextGeneration:addChromosome(parent2)
            end
        end

        self.generationsEvolved = self.generationsEvolved + 1

        return nextGeneration
    end

    return GeneticAlgorithm
end
GeneticAlgorithm = _m_init()
_m_init = nil
