require("mod_assert")
require("mod_neural_net")

function before_each()
end

function test_available_functions()
    assert.not_equals(nil, nn)
end

function test_local_functions()
end

function test_matrix_multiply()
    local input = {1, 2, 3, 4}
    local matrix = {{1, 5}, {2, 6}, {3, 7}, {4, 8}}
    local expected = {30, 70}
    local actual = nn.multiplyByMatrix(input, matrix)
    for i = 1, #input do
        assert.equals(expected[i], actual[i])
    end
end

function test_predict()
    local input = {1, 2, 3, 4}
    local weights = {
        {1, 5},
        {2, 6},
        {3, 7},
        {4, 8}
    }
    local expected = {30, 70}
    local net = nn.new()
    net:addLayer(weights, "relu", false)
    local actual = net:predict(input)
    for i = 1, #input do
        assert.equals(expected[i], actual[i])
    end
end

function test_predict_with_bias()
    local input = {1, 2, 3, 4}
    local weights = {
        {1, 5},
        {2, 6},
        {3, 7},
        {4, 8},
        {1.3, 1.4}
    }
    local expected = {31.3, 71.4}

    local net = nn.new()
    net:addLayer(weights, "relu", true)
    local actual = net:predict(input)
    for i = 1, #input do
        assert.equals(expected[i], actual[i])
    end
end

function test_predict_with_bias_real_relu()
    local input = {1, 2, 3, 4}
    local weights = {
        {-0.00507037, -0.04878497},
        {0.04400307, 0.01574006},
        {0.04959274, 0.04452698},
        {0.04298705, -0.04140915},
        {0.01, 0.01} -- bias
    }
    local expected = {0.41366219, 0}

    local net = nn.new()
    net:addLayer(weights, "relu", true)
    local actual = net:predict(input)
    for i = 1, #expected do
        assert.equals(round(expected[i], 7), round(actual[i], 7))
    end
end

function test_predict_with_bias_real_sigmoid()
    local input = {1, 2, 3, 4}
    local weights = {
        {-0.00507037, -0.04878497},
        {0.04400307, 0.01574006},
        {0.04959274, 0.04452698},
        {0.04298705, -0.04140915},
        {0.01, 0.01} -- bias
    }
    local expected = {0.60196567, 0.49016115}

    local net = nn.new()
    net:addLayer(weights, "sigmoid", true)
    local actual = net:predict(input)
    for i = 1, #expected do
        assert.equals(round(expected[i], 6), round(actual[i], 6))
    end
end

function test_predict_multiple_layers_and_bias()
    local input = {1, 2, 3, 4}
    local layer1Weights = {
        {1, 5},
        {2, 6},
        {3, 7},
        {4, 8}
    }
    local layer2Weights = {
        {3},
        {4},
        {0.123}
    }
    local expected = {370.123}
    local net = nn.new()
    net:addLayer(layer1Weights, "relu", false)
    net:addLayer(layer2Weights, "relu", true)
    local actual = net:predict(input)
    for i = 1, #input do
        assert.equals(expected[i], actual[i])
    end
end

function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

require("mod_test_runner")
