require("mod_common_utils")

function _m_init()
    local RandomKeyTweakMutation = {}

    function RandomKeyTweakMutation.new(tweakAmount, tweakFrequency)
        local instance = {}
        for k, v in pairs(RandomKeyTweakMutation) do
            instance[k] = v
        end

        instance.tweakAmount = tweakAmount or 0.1
        instance.tweakFrequency = tweakFrequency or 0.5

        return instance
    end

    -- 1 - tweakFrequency % of the time, changes a randomly chosen element of the array representation
    -- to a random value uniformly distributed in [0,1]
    -- tweakFrequency % of the time, tweaks a randomly chosen element of the array representation
    -- randomly from -tweakAmount to tweakAmount
    function RandomKeyTweakMutation:mutate(c)
        local mutatedRep = common_utils.copy(c.representation)

        local numitems = 0
        for k,v in pairs(mutatedRep) do
            numitems = numitems + 1
        end

        local randKeyIndex = math.random(1, numitems)

        local count = 0
        for k,v in pairs(mutatedRep) do
            count = count + 1
            if count == randKeyIndex then
                if math.random() < self.tweakFrequency then 
                    mutatedRep[k] = common_utils.clamp(mutatedRep[k] + (2 * math.random()  - 1) * self.tweakAmount)
                else 
                    mutatedRep[k] = math.random()
                end
                break
            end
        end

        return c.new(mutatedRep)
    end

    return RandomKeyTweakMutation
end
RandomKeyTweakMutation = _m_init()
_m_init = nil
