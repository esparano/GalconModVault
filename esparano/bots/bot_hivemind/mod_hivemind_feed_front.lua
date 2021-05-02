require("mod_hivemind_action")
--[[
-suggests shuttling to nearest front planet
-grades moves based on whether headed from or away from front (handle penalty separately maybe?)
-prefer shuttling to front rather than sending from vulnerable planets usually?
]]
function _m_init()
    local FeedFrontMind = {}

    function FeedFrontMind.new()
        local instance = {}
        for k, v in pairs(FeedFrontMind) do
            instance[k] = v
        end

        instance.name = "FeedFront"

        return instance
    end

    function FeedFrontMind:suggestActions(map, mapTunnels, mapFuture, botUser)
        return {}
    end

    function FeedFrontMind:gradeAction(map, mapTunnels, mapFuture, botUser, action)
       
    end

    return FeedFrontMind
end
FeedFrontMind = _m_init()
_m_init = nil
