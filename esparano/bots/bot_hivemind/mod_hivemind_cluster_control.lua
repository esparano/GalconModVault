require("mod_hivemind_action")
--[[
-does not suggest moves
-add bonus to moves that puts ships near clusters (target + general direction?)
-construct map of nearby prod?
]]
function _m_init()
    local ClusterControlMind = {}

    function ClusterControlMind.new()
        local instance = {}
        for k, v in pairs(ClusterControlMind) do
            instance[k] = v
        end

        instance.name = "ClusterControl"

        return instance
    end

    function ClusterControlMind:suggestActions(map, mapTunnels, mapFuture, botUser)
        return {}
    end

    function ClusterControlMind:gradeAction(map, mapTunnels, mapFuture, botUser, action)
 
    end

    return ClusterControlMind
end
ClusterControlMind = _m_init()
_m_init = nil
