require("mod_hivemind_action")
--[[
-detect shitty rushes
-suppress expansion (careful not to suppress redirects etc?)
-land fleets if in enemy territory
-pull back fleets if on their way to enemy. Land at closest planet to center of mass?
]]
function _m_init()
    local DefendRushMind = {}

    function DefendRushMind.new(params)
        local instance = {}
        for k, v in pairs(DefendRushMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "DefendRush"

        return instance
    end

    function DefendRushMind:suggestActions(plans)
        return {}
    end

    function DefendRushMind:gradeAction(action, plans)
        
    end

    return DefendRushMind
end
DefendRushMind = _m_init()
_m_init = nil
