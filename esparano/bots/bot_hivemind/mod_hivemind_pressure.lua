require("mod_hivemind_action")
--[[
Grades based on pressure enemy feels? how to quantify this? how many ships enemy has tied down? Idk.
]]
function _m_init()
    local PressureMind = {}

    function PressureMind.new(params)
        local instance = {}
        for k, v in pairs(PressureMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "Pressure"

        return instance
    end

    function PressureMind:suggestActions(plans)
        return {}
    end

    function PressureMind:gradeAction(action, plans)

    end

    return PressureMind
end
PressureMind = _m_init()
_m_init = nil
