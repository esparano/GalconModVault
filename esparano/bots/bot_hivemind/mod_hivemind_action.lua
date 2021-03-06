require("mod_hivemind_action")
require("mod_common_utils")

ACTION_TYPE_SEND = "s"
ACTION_TYPE_REDIRECT = "r"
ACTION_TYPE_PASS = "p"

function _m_init()
    local Action = {}
    
    function Action._new(initialPriority, mind, description, actionType, plans, sources, target, percent)
        local instance = {}
        for k, v in pairs(Action) do
            instance[k] = v
        end

        instance.initialPriority = initialPriority
        instance.mind = mind 
        instance.description = description
        instance.actionType = actionType
        instance.plans = plans
        instance.sources = sources
        instance.target = target
        instance.percent = percent
        instance.opinions = {}

        return instance
    end

    -- plan may be nil if there is no plan
    function Action.newSend(initialPriority, mind, description, plans, sources, target, percent)
        return Action._new(initialPriority, mind, description, ACTION_TYPE_SEND, plans, sources, target, percent)
    end

    function Action.newRedirect(initialPriority, mind, description, plans, sources, target)
        return Action._new(initialPriority, mind, description, ACTION_TYPE_REDIRECT, plans, sources, target)
    end

    function Action.newPass(initialPriority, mind, description)
        return Action._new(initialPriority, mind, description, ACTION_TYPE_PASS, {})
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
        local description
        if self:isSend() then 
            local sourceShips = common_utils.joinToString(common_utils.map(self.sources, function (f) return common_utils.round(f.ships) end), ",")
            description = "s [" .. sourceShips .. "] " .. self.percent .. "% -> " .. common_utils.toPrecision(self.target.ships, 1)
        elseif self:isRedirect() then 
            description = "r " .. common_utils.round(common_utils.sumList(common_utils.map(self.sources, function (f) return f.ships end)))
                .. "s -> " .. self.target.ships
        elseif self:isPass() then 
            description = "p"
        end
        description = description .. ", details: " .. self.description
        return self.mind.name 
            .. "(p0: " .. common_utils.toPrecision(self.initialPriority, 2) 
            .. ", p: " .. common_utils.toPrecision(self:getOverallPriority(), 2) 
            .. ") " 
            .. description
    end

    return Action
end
Action = _m_init()
_m_init = nil
