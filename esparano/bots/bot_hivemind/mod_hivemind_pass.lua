require("mod_hivemind_action")

function _m_init()
    local PassMind = {}

    function PassMind.new(params)
        local instance = {}
        for k, v in pairs(PassMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "Pass"

        return instance
    end

    function PassMind:suggestActions(plans)
        return { Action.newPass(0, self, "pass") }
    end

    function PassMind:gradeAction(action, plans) 
    end

    return PassMind
end
PassMind = _m_init()
_m_init = nil
