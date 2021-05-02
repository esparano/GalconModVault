require("mod_hivemind_action")
--[[
-detect enemy overexpansion
-suppress expansion unless it helps reach enemy and is very cheap.
-suppress defense
-suppress excessive floating
-add bonus for attacking head on and reinforcing
full on attack of enemy front planet works?
]]
function _m_init()
    local RushMind = {}

    function RushMind.new()
        local instance = {}
        for k, v in pairs(RushMind) do
            instance[k] = v
        end

        instance.name = "Rush"

        return instance
    end

    function RushMind:suggestActions(map, mapTunnels, mapFuture, botUser)
        return {}
    end

    function RushMind:gradeAction(map, mapTunnels, mapFuture, botUser, action)

    end

    return RushMind
end
RushMind = _m_init()
_m_init = nil
