require("mod_assert")

-- TODO: documentation
function _nn_init()
    local nn = {}

    function nn.new(weights, useBias)
        local _o = {}
        for k, v in nn do
            _o[k] = v
        end
        _o.weights = weights
        _o.useBias = useBias
        return _o
    end

    function nn.compute(input)
        local v = input
        for i,layerWeights in ipairs(self.weights) do
            -- destructively modifies input - make a copy?...
            if self.useBias then v[#v] = 1 end
            v = nn.multiplyByMatrix(v, layerWeights)
            -- apply ReLU
            for j=1,#v do
                if v[j] < 0 then v[j] = 0 end
            end
        end
        return v
    end

    -- function that takes an N+1(bias) by M matrix of weights, applies weights to N length input vector,
    -- and produces an M length output vector
    function nn.multiplyByMatrix(input, weightMatrix)
        local output = {}
        for i,weights in ipairs(weightMatrix) do
            assert.equals(#weights, #input)
            local dotProduct = 0
            for j=1,#weights do
                dotProduct = dotProduct + input[j] * weights[j]
            end
            output[i] = dotProduct
        end
        return output
    end

    return nn
end
nn = _nn_init()
_nn_init = nil
