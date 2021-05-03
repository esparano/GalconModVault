require("mod_hivemind_action")
require("mod_common_utils")

function _m_init()
    local Action = {}

    local ACTION_TYPE_SEND = "s"
    local ACTION_TYPE_REDIRECT = "r"
    local ACTION_TYPE_PASS = "p"

    function Action._new(initialPriority, mind, description, actionType, sources, target, percent)
        local instance = {}
        for k, v in pairs(Action) do
            instance[k] = v
        end

        instance.initialPriority = initialPriority
        instance.mind = mind 
        instance.description = description
        instance.actionType = actionType
        instance.sources = sources
        instance.target = target
        instance.percent = percent
        instance.opinions = {}

        return instance
    end

    function Action.newSend(initialPriority, mind, description, sources, target, percent)
        return Action._new(initialPriority, mind, description, ACTION_TYPE_SEND, sources, target, percent)
    end

    function Action.newRedirect(initialPriority, mind, description, sources, target)
        return Action._new(initialPriority, mind, description, ACTION_TYPE_REDIRECT, sources, target)
    end

    function Action.newPass(initialPriority, mind, description)
        return Action._new(initialPriority, mind, description, ACTION_TYPE_PASS)
    end

    function Action:isSend()
        return self.actionType == ACTION_TYPE_SEND
    end

    function Action:isRedirect()
        return self.actionType == ACTION_TYPE_REDIRECT
    end

    function Action:isPass()
        return self.actionType == ACTION_TYPE_PASS
    end

    function Action:addOpinion(priorityAdjustment, mind, reason)
        table.insert(self.opinions, {
            adjustment = priorityAdjustment,
            mind = mind,
            reason = reason
        })
    end

    function Action:getOverallPriority()
        local adjustments = common_utils.map(self.opinions, function (o) return o.adjustment end)
        return self.initialPriority + common_utils.sumList(adjustments)
    end

    function Action:getSummary()
        return self.mind.name .. " suggests " .. self.actionType .. " with priority "
            .. common_utils.toPrecision(self.initialPriority, 2) .. " and final priority "
            .. common_utils.toPrecision(self:getOverallPriority(), 2)
    end

    return Action
end
Action = _m_init()
_m_init = nil