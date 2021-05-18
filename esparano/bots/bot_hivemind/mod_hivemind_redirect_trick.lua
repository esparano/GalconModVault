require("mod_hivemind_action")
--[[
-strongly suggests redirecting away if planet will be captured by friendly fleet but then taken immediately by enemy (OR VULNERABLE TO ENEMY, don't use only target) ONLY IF planet is contested and cannot be easily taken back
-does not grade most moves, but may add bonus to moves supporting the neutral in question. Scales with neutral cost and prod?
]]
function _m_init()
    local RedirectTrickMind = {}

    function RedirectTrickMind.new()
        local instance = {}
        for k, v in pairs(RedirectTrickMind) do
            instance[k] = v
        end

        instance.name = "RedirectTrick"
        
        return instance
    end

    function RedirectTrickMind:suggestActions(plans)
        return {}
    end

    function RedirectTrickMind:gradeAction(action, plans)

    end

    return RedirectTrickMind
end
RedirectTrickMind = _m_init()
_m_init = nil
