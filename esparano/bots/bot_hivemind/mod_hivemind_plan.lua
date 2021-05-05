require("mod_common_utils")

function _m_init()
    local Plan = {}
    
    function Plan.new(mindName, data)
        local instance = {}

        instance.mindName = mindName 
        instance.data = data
        instance.satisfied = false

        return instance
    end

    return Plan
end
Plan = _m_init()
_m_init = nil
