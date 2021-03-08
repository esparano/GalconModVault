require("mod_common_utils")

function _m_init()
    local RandomKeyMutation = {}

    function RandomKeyMutation.new()
        local instance = {}
        for k, v in pairs(RandomKeyMutation) do
            instance[k] = v
        end

        return instance
    end

    -- Changes a randomly chosen element of the array representation
    -- to a random value uniformly distributed in [0,1]
    function RandomKeyMutation:mutate(c)
        local mutatedRep = common_utils.copy(c.representation)

        local numitems = 0
        for k,v in pairs(mutatedRep) do
            numitems = numitems + 1
        end

        local randKeyIndex = math.random(1, numitems)

        local count = 0
        for k,v in pairs(mutatedRep) do
            count = count + 1
            if (count == randKeyIndex) then
                mutatedRep[k] = math.random()
                break
            end
        end

        return c.new(mutatedRep)
    end

    return RandomKeyMutation
end
RandomKeyMutation = _m_init()
_m_init = nil
