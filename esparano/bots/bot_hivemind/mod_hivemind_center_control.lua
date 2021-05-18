require("mod_hivemind_action")
--[[
-no suggestions
-grades moves based on how central ships are (center of mass of in-play planets?? Or center of mass tunnel distance?)
]]
function _m_init()
    local CenterControlMind = {}

    function CenterControlMind.new()
        local instance = {}
        for k, v in pairs(CenterControlMind) do
            instance[k] = v
        end

        instance.name = "CenterControl"

        return instance
    end

    function CenterControlMind:suggestActions(plans)
        return {}
    end

    function CenterControlMind:gradeAction(action, plans)

    end

    return CenterControlMind
end
CenterControlMind = _m_init()
_m_init = nil
