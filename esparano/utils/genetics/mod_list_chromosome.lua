require("mod_common_utils")

function _m_init()
    local ListChromosome = {}

    -- representation must be a 1-dimensional table (no nesting)
    -- in most cases, fitness should be nil at the start
    function ListChromosome.new(representation, fitness)
        local instance = {}
        for k, v in pairs(ListChromosome) do
            instance[k] = v
        end

        -- TODO: add to common utils for precision
        for k, v in pairs(representation) do
            representation[k] = common_utils.round(1000*v)/1000
        end
        instance.representation = representation
        instance.fitness = fitness

        return instance
    end

    -- TODO: don't compare chromosomes if representations are identical.

    return ListChromosome
end
ListChromosome = _m_init()
_m_init = nil
