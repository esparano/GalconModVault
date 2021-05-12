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

    -- TODO: cross-front actions as well as to-enemy-center-of-mass actions.
    function FeedFrontMind:suggestActions(map, mapTunnels, mapFuture, botUser)
        local candidates = {}

        candidates = common_utils.combineLists(candidates, self:suggestSimpleFeedActions(map, mapTunnels, mapFuture, botUser))

        return candidates
    end

    function FeedFrontMind:gradeAction(map, mapTunnels, mapFuture, botUser, action)
       
    end

    function FeedFrontMind:suggestSimpleFeedActions(map, mapTunnels, mapFuture, botUser, action)
       return {}
    end

    return FeedFrontMind
end
FeedFrontMind = _m_init()
_m_init = nil
