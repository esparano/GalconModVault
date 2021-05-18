require("mod_hivemind_action")
--[[
-detect good mid maps, predict enemy front planets and owned front planets and if the distance between any pair of fronts is very small, RUSH. Also
-suppress expansion unless it helps capture mid and is very cheap
-steal mid planets if enemy is far away and will gain more ships before enemy capture than enemy would have spent on the planet
]]
function _m_init()
    local MidRushMind = {}

    function MidRushMind.new()
        local instance = {}
        for k, v in pairs(MidRushMind) do
            instance[k] = v
        end

        instance.name = "MidRush"

        return instance
    end

    function MidRushMind:suggestActions(map, mapTunnels, mapFuture, botUser, plans)
        return {}
    end

    function MidRushMind:gradeAction(map, mapTunnels, mapFuture, botUser, action, plans)
        
    end

    return MidRushMind
end
MidRushMind = _m_init()
_m_init = nil
