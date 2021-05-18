require("mod_hivemind_action")
--[[
-turns on when game is clearly over, attack nearest etc.? Does this need to exist?
ahead prod, ahead ships by significant amount, send amount of surplus to enemy? 
Is this the same or different from "Pressure" that only grades aggressive moves or suggests
surplus be amount for full on attack defense minus amount of ships owned?
]]
function _m_init()
    local CleanupMind = {}

    function CleanupMind.new()
        local instance = {}
        for k, v in pairs(CleanupMind) do
            instance[k] = v
        end

        instance.name = "Cleanup"

        return instance
    end

    function CleanupMind:suggestActions(map, mapTunnels, mapFuture, botUser, plans)
        return {}
    end

    function CleanupMind:gradeAction(map, mapTunnels, mapFuture, botUser, action, plans)

    end

    return CleanupMind
end
CleanupMind = _m_init()
_m_init = nil
