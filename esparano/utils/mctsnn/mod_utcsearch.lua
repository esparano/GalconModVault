function _m_init()
    local Mcts = {}

    function Mcts.new()
        local instance = {}
        for k, v in pairs(Mcts) do
            instance[k] = v
        end
        return instance
    end

    function Mcts:nextIteration()
        -- TODO
    end

    function Mcts:selectMoveDeterministically()
        -- TODO
    end

    function Mcts:selectMoveStochastically()
        -- TODO
    end

    return Mcts
end
Mcts = _m_init()
_m_init = nil
