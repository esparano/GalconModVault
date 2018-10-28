require("mod_assert")
require("mod_profiler")

function test_wraps_multiarg_function()
    local testModule = {}
    local actualX, actualY
    testModule.f = function(x, y) 
        actualX, actualY = x, y
        for i=1,(x+y) do
            local a = 1 + i
        end
    end

    local profiler = profiler.new()
    profiler:profile(testModule)

    local expectedX = 1235
    local expectedY = 1513135
    testModule.f(expectedX, expectedY)
    assert.equals(expectedX, actualX)
    assert.equals(expectedY, actualY)
end

function test_profiling_data() 
    local testModule = {}
    testModule.f = function() 
        for i=1,100000 do
            local a = 1 + i
        end
    end

    local profiler = profiler.new()
    profiler:profile(testModule)
    local data = profiler:getData()
    
    testModule.f()

    local elapsed = data[testModule].f.elapsed
    assert.equals(1, data[testModule].f.n)
    assert.not_equals(0, elapsed)
    
    testModule.f()
    
    assert.equals(2, data[testModule].f.n)
    assert.is_true(data[testModule].f.elapsed > elapsed)
end

require("mod_test_runner")
