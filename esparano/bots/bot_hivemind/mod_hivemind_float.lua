require("mod_hivemind_action")
--[[
-If no good planets to land on, redirects away from enemy center of ship mass
-if good planets to land on, land
-if any planet will not be captured by fleet, redirect away?
- no neutral available for expansion, neutral game??
]]
function _m_init()
    local FloatMind = {}

    function FloatMind.new(params)
        local instance = {}
        for k, v in pairs(FloatMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "Float"

        return instance
    end

    function FloatMind:suggestActions(plans)
        return {}
    end

    function FloatMind:gradeAction(action, plans)
        
    end

    return FloatMind
end
FloatMind = _m_init()
_m_init = nil
