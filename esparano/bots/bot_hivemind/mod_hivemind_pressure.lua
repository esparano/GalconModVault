require("mod_hivemind_action")
--[[
Grades based on pressure enemy feels? how to quantify this? how many ships enemy has tied down? Idk.
]]
function _m_init()
    local PressureMind = {}

    function PressureMind.new()
        local instance = {}
        for k, v in pairs(PressureMind) do
            instance[k] = v
        end

        instance.name = "Pressure"

        return instance
    end

    function PressureMind:suggestActions(map, mapTunnels, mapFuture, botUser)
        return {}
    end

    function PressureMind:gradeAction(map, mapTunnels, mapFuture, botUser, action)

    end

    return PressureMind
end
PressureMind = _m_init()
_m_init = nil
