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
    local matrix = {{1, 2, 3, 4}, {5, 6, 7, 8}}
    local expected = {30, 70}
    local actual = nn.multiplyByMatrix(input, matrix)
    for i=1,#input do
        assert.equals(expected[i], actual[i])
    end
end

function init()
end

function loop(t)
end

function event(e)
end

require("mod_test_runner")