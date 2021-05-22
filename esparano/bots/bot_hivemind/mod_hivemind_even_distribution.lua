require("mod_hivemind_action")
--[[
-does not suggest moves
-not sure what to do here. Balance fronts? Prefer supporting fronts that are behind or even take from fronts that are ahead?
]]
function _m_init()
    local EvenDistributionMind = {}

    function EvenDistributionMind.new(params)
        local instance = {}
        for k, v in pairs(EvenDistributionMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "EvenDistribution"

        return instance
    end

    function EvenDistributionMind:suggestActions(plans)
        return {}
    end

    function EvenDistributionMind:gradeAction(action, plans)
        
    end

    return EvenDistributionMind
end
EvenDistributionMind = _m_init()
_m_init = nil
