require("mod_common_utils")

function _m_init()
    local UniformCrossover = {}

    function UniformCrossover.new(crossoverRatio)
        local instance = {}
        for k, v in pairs(UniformCrossover) do
            instance[k] = v
        end
        
        assert.is_true(crossoverRatio >= 0 and crossoverRatio <= 1, "crossoverRatio " .. crossoverRatio .. " must be between 0 and 1")

        instance.crossoverRatio = crossoverRatio

        return instance
    end

    -- Assumes chromosomes are list chromosomes (will not operate on sub-tables)
    function UniformCrossover:crossover(p1, p2)
        local c1Rep, c2Rep = {}, {}

        for k in pairs(p1.representation) do
            if math.random() < self.crossoverRatio then 
                c1Rep[k] = p2.representation[k]
                c2Rep[k] = p1.representation[k]
            else
                c1Rep[k] = p1.representation[k]
                c2Rep[k] = p2.representation[k]
            end
        end

        return p1.new(c1Rep), p2.new(c2Rep)
    end

    return UniformCrossover
end
UniformCrossover = _m_init()
_m_init = nil
