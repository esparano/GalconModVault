require("mod_hivemind_action")
--[[
-does not grade moves
-explosively attack nearest planets (clusters based?) full-on if swap detected
-the goal is attrition of enemy ships as well as capturing prod....
]]
function _m_init()
    local SwapMind = {}

    function SwapMind.new()
        local instance = {}
        for k, v in pairs(SwapMind) do
            instance[k] = v
        end

        instance.name = "Swap"

        return instance
    end

    function SwapMind:suggestActions(map, mapTunnels, mapFuture, botUser)
        return {}
    end

    function SwapMind:gradeAction(map, mapTunnels, mapFuture, botUser, action)

    end

    return SwapMind
end
SwapMind = _m_init()
_m_init = nil
