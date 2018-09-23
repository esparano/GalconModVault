-- TODO: documentation
function _assert_init()
local assert = {}

local function _equals_shallow(expected, actual, message, sign)
    if (expected ~= actual) == sign then
        local expected = tostring(expected)
        if not sign then expected = "not " .. expected end
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

local function _equals_boolean(b, cond, message)
    if type(cond) ~= "boolean" then
        print("assert: ERROR: condition was not boolean")
        return
    end
    assert.equals(b, cond, message)
end

-- TODO: assert.equals_epsilon
-- TODO: assert.equals_array/table/deep-equals

function assert.is_true(cond, message)
    _equals_boolean(true, cond, message)
end

function assert.is_false(cond, message)
    _equals_boolean(false, cond, message)
end

return assert
end; assert = _assert_init(); _assert_init = nil
