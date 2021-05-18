require("mod_hivemind_action")
--[[
only suggests moves when really behind.
]]
function _m_init()
    local SurrenderMind = {}

    function SurrenderMind.new()
        local instance = {}
        for k, v in pairs(SurrenderMind) do
            instance[k] = v
        end

        instance.name = "Surrender"

        return instance
    end

    function SurrenderMind:suggestActions(map, mapTunnels, mapFuture, botUser, plans)
        return {}
    end

    function SurrenderMind:gradeAction(map, mapTunnels, mapFuture, botUser, action, plans)

    end

    return SurrenderMind
end
SurrenderMind = _m_init()
_m_init = nil
