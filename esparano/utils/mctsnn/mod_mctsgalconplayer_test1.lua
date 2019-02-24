function _m_init()
    local Player = {}

    function Player.new()
        local instance = {}
        for k, v in pairs(Player) do
            instance[k] = v
        end
        return instance
    end

    -- Return an evaluation [-1,1] of the position and a list of moves with play probability estimates
    function Player:getValueAndPriorProbabilitiesForState(state)
        -- TODO:
        -- TODO: NN here. NNCache?
    end

    return Player
end
Player = _m_init()
_m_init = nil
