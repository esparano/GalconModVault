require("mod_hivemind_action")
--[[
-send ships near enemy target and close by planets to enemy fleet.
-adds bonus to moves that help defend
-- if up prod + behidn ships and can defend attack ,maybe?
]]
function _m_init()
    local DefendMind = {}

    function DefendMind.new(params)
        local instance = {}
        for k, v in pairs(DefendMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "Defend"

        return instance
    end

    function DefendMind:suggestActions(plans)
        return {}
    end

    -- TODO: figure out how to deal with expansion logic while defending???
    function DefendMind:gradeAction(action, plans)

    end

    return DefendMind
end
DefendMind = _m_init()
_m_init = nil
