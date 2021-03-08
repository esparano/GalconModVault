function _m_init()
    local EvaluationPolicy = {}

    -- fitnessEvaluator must assign a fitness to all chromosomes in a population
    function EvaluationPolicy.new(fitnessEvaluator)
        local instance = {}
        for k, v in pairs(EvaluationPolicy) do
            instance[k] = v
        end

        instance.fitnessEvaluator = fitnessEvaluator

        return instance
    end
    
    function EvaluationPolicy:evaluateFitness(population)
        return self.fitnessEvaluator(population)
    end

    return EvaluationPolicy
end
EvaluationPolicy = _m_init()
_m_init = nil
