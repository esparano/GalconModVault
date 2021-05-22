require("mod_hivemind_action")
--[[
-only at end of round, suggests expansion, lands fleets, and defends
-does not grade moves
]]
function _m_init()
    local TimerTrickMind = {}

    function TimerTrickMind.new(params)
        local instance = {}
        for k, v in pairs(TimerTrickMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "TimerTrick"

        return instance
    end

    function TimerTrickMind:suggestActions(plans)
        return {}
    end

    function TimerTrickMind:gradeAction(action, plans)
    
    end

    return TimerTrickMind
end
TimerTrickMind = _m_init()
_m_init = nil
