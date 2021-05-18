require("mod_hivemind_action")
--[[
-does not grade moves
-only suggests two move types:
-if planet being attacked is about to die AND IN ENEMY TERRITORY, 
send to another enemy planet that is preferably empty, 
or send to a somewhat far (enemy?) planet to start a FleeTrick. 
Also only activate if really about to be captured (DO consider target and make sure capture time is less than say .5 seconds).
Make sure planet about to be captured is not a mid planet etc.
]]
function _m_init()
    local FleeTrickMind = {}

    function FleeTrickMind.new()
        local instance = {}
        for k, v in pairs(FleeTrickMind) do
            instance[k] = v
        end

        instance.name = "FleeTrick"

        return instance
    end

    function FleeTrickMind:suggestActions(plans)
        return {}
    end

    function FleeTrickMind:gradeAction(action, plans)

    end

    return FleeTrickMind
end
FleeTrickMind = _m_init()
_m_init = nil
