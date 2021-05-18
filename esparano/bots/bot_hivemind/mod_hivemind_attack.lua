require("mod_hivemind_action")
--[[
    Attack from front planets to enemy front planets, especially if they are weak or very close and can be overwhelmed
    Otherwise attack back planets?
]]
function _m_init()
    local AttackMind = {}

    function AttackMind.new()
        local instance = {}
        for k, v in pairs(AttackMind) do
            instance[k] = v
        end

        instance.name = "Attack"

        return instance
    end

    --[[
        #Num moves suggested as configurable per mind?? Max num?#  
    ]]
    function AttackMind:suggestActions(map, mapTunnels, mapFuture, botUser, plans)
        return {}
    end

    function AttackMind:gradeAction(map, mapTunnels, mapFuture, botUser, action, plans)
        -- action:addOpinion(0, self, "no opinion")
    end

    return AttackMind
end
AttackMind = _m_init()
_m_init = nil
