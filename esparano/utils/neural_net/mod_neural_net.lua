require("mod_assert")

-- TODO: documentation
function _nn_init()
    local nn = {}

    function nn.new(weights, useBias)
        local instance = {}
        for k, v in pairs(nn) do
            instance[k] = v
        end
        instance.layers = {}
        return instance
    end

    function nn:addLayer(weights, activation, useBias)
        self.layers[#self.layers + 1] = {
            weights = weights,
            activation = activation,
            useBias = useBias
        }
    end

    function nn:predict(input)
        -- destructively modifies input - make a copy?...
        local v = input
        for _, layer in ipairs(self.layers) do
            local layerWeights = layer.weights
            if layer.useBias then
                v[#v + 1] = 1
            end
            v = nn.multiplyByMatrix(v, layerWeights)
            -- apply ReLU
            -- TODO: different activation functions
            if layer.activation == "relu" then
                for j = 1, #v do
                    if v[j] < 0 then
                        v[j] = 0
                    end
                end
            else
                error("activation function unrecognized or unsupported")
            end
        end
        return v
    end

    -- function that takes an N+1(bias) by M matrix of weights, applies weights to N length input vector,
    -- and produces an M length output vector
    function nn.multiplyByMatrix(input, weightMatrix)
        assert.equals(
            #input,
            #weightMatrix,
            "weight matrix does not match input dimensions. Note: Bias is the last column of weights if present"
        )
        local output = {}
        local outputLen = #(weightMatrix[1])
        for j = 1, outputLen do
            output[j] = 0
        end
        for n, nodeWeights in ipairs(weightMatrix) do
            for j = 1, #nodeWeights do
                output[j] = output[j] + input[n] * nodeWeights[j]
            end
        end
        return output
    end

    return nn
end
nn = _nn_init()
_nn_init = nil
