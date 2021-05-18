require("mod_hivemind_action")
--[[
-only at end of round, suggests expansion, lands fleets, and defends
-does not grade moves
]]
function _m_init()
    local TimerTrickMind = {}

    function TimerTrickMind.new()
        local instance = {}
        for k, v in pairs(TimerTrickMind) do
            instance[k] = v
        end

        instance.name = "TimerTrick"

        return instance
    end

    function TimerTrickMind:suggestActions(map, mapTunnels, mapFuture, botUser, plans)
        return {}
    end

    function TimerTrickMind:gradeAction(map, mapTunnels, mapFuture, botUser, action, plans)
    
    end

    return TimerTrickMind
end
TimerTrickMind = _m_init()
_m_init = nil
