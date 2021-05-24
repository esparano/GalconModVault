require("mod_common_utils")

function _m_init()
    local ElitistPopulation = {}

    function ElitistPopulation.new(populationLimit, elitismRate)
        elitismRate = elitismRate or 0.8

        local instance = {}
        for k, v in pairs(ElitistPopulation) do
            instance[k] = v
        end
        
        assert.is_true(populationLimit > 0 , "populationLimit " .. populationLimit .. " must be > 0")
        assert.is_true(elitismRate >= 0 and elitismRate <= 1, "elitismRate " .. elitismRate .. " must be between 0 and 1")

        instance.populationLimit = populationLimit
        instance.elitismRate = elitismRate
        instance.chromosomes = {}

        return instance
    end
    
    function ElitistPopulation:getPopulationSize()
        return #self.chromosomes
    end
    
    function ElitistPopulation:isFull()
        return #self.chromosomes >= self.populationLimit 
    end

    function ElitistPopulation:hasBeenFullyEvaluated()
        for _,c in pairs(self.chromosomes) do
            if c.fitness == nil then 
                return false
            end
        end
        return true
    end

    function ElitistPopulation:nextGeneration()
        local nextGeneration = ElitistPopulation.new(self.populationLimit, self.elitismRate)

        assert.is_true(self:hasBeenFullyEvaluated(), "Population contains chromosomes whose fitness was not yet evaluated.")

        table.sort(self.chromosomes,function(a,b) return a.fitness > b.fitness end)

        local boundIndex = common_utils.round(self.elitismRate * #self.chromosomes)

        for i = 1, boundIndex do
            nextGeneration:addChromosome(self.chromosomes[i])
        end

        return nextGeneration
    end

    function ElitistPopulation:addChromosome(chromosome)
        assert.is_false(self:isFull(), "Population is full. Cannot add chromosome.")
        table.insert(self.chromosomes, chromosome)
    end

    function ElitistPopulation:getFittestChromosome()
        return common_utils.find(self.chromosomes, function (o) 
            if o.fitness ~= nil then 
                return o.fitness 
            else 
                return -math.huge 
            end
        end
        )
    end

    return ElitistPopulation
end
ElitistPopulation = _m_init()
_m_init = nil
