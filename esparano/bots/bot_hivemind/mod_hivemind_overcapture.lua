require("mod_hivemind_action")

function _m_init()
    local OvercaptureMind = {}

    function OvercaptureMind.new(params)
        local instance = {}
        for k, v in pairs(OvercaptureMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "Overcapture"

        return instance
    end

    -- does not suggest moves
    function OvercaptureMind:suggestActions(plans)
        return {}
    end

    --adds penalty to moves that will capture with too many ships?? Not sure. Is this necessary or does EvenDistributionMind take care of this?
    function OvercaptureMind:gradeAction(action, plans)
        
    end

    return OvercaptureMind
end
OvercaptureMind = _m_init()
_m_init = nil
