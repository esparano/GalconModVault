function _run_tests()
    if before then
        before()
    end
    for f_name, f in pairs(_ENV) do
        if f_name:sub(1, 5) == "test_" then
            print("running test: " .. f_name)
            if before_each then
                before_each()
            end
            f()
            if after_each then
                after_each()
            end
        end
    end
    if after then
        after()
    end
end
_run_tests()
_run_tests = nil

function init()
end
function loop()
end
function event()
end
