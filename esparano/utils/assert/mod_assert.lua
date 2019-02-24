-- TODO: documentation
function _assert_init()
    local assert = {}

    local function _equals_shallow(expected, actual, message, sign)
        if (expected ~= actual) == sign then
            local expected = tostring(expected)
            if not sign then
                expected = "not " .. expected
            end
            local error_message = "assert: expected " .. expected .. " but was " .. tostring(actual)
            if message ~= nil then
                error_message = error_message .. ", message: " .. tostring(message)
            end
            print(error_message)
        end
    end

    function assert.equals(expected, actual, message)
        _equals_shallow(expected, actual, message, true)
    end

    function assert.not_equals(expected, actual, message)
        _equals_shallow(expected, actual, message, false)
    end

    local function checkType(obj, t, objName)
        if type(obj) ~= t then
            print("assert: ERROR: expected '" .. objName .. "' to be type " .. t)
            return false
        end
        return true
    end

    local function _equals_boolean(b, cond, message)
        if not checkType(cond, "boolean", "condition") then
            return
        end
        assert.equals(b, cond, message)
    end

    -- TODO: assert.equals_array/table/deep-equals
    function assert.equals_epsilon(expected, actual, epsilon, message)
        if
            not checkType(expected, "number", "expected") or not checkType(actual, "number", "actual") or
                not checkType(epsilon, "number", "epsilon")
         then
            return
        end
        assert.is_true(
            math.abs(expected - actual) <= epsilon,
            expected .. " was not within " .. epsilon .. " of " .. actual .. "; " .. (message ~= nil and message or "")
        )
    end

    function assert.is_true(cond, message)
        _equals_boolean(true, cond, message)
    end

    function assert.is_false(cond, message)
        _equals_boolean(false, cond, message)
    end

    function assert.is_nil(obj, message)
        assert.equals(nil, obj, message)
    end

    function assert.not_nil(obj, message)
        assert.not_equals(nil, obj, message)
    end

    return assert
end
assert = _assert_init()
_assert_init = nil
