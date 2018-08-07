require("mod_assert")

function test_available_functions()
    print(assert)
    print(assert.is_true)
    print(assert.is_false)
    print(assert.equals)
    print(assert.not_equals)
    for k,v in pairs(assert) do
        print(k)
    end
end

function test_local_functions()
    print(is_true)
    print(is_false)
    print(equals)
    print(not_equals)
end

function test_is_true()
    assert.is_true(true)
    assert.is_true(true, "some message")
end

function test_is_true_fail()
    assert.is_true(false)
end

function test_is_true_invalid()
    assert.is_true(0)
    assert.is_true(nil)
    assert.is_true(1)
    assert.is_true(4)
    assert.is_true(-1)
    assert.is_true("")
    assert.is_true("true")
end

function test_is_true_fail_with_message()
    assert.is_true(false, "some message")
    assert.is_true(false, "")
    assert.is_true(false, 5)
    assert.is_true(false, {})
end

function test_is_true_invalid_with_message()
    assert.is_true(7, "message not shown")
end

function test_equals()
    assert.equals(4, 4)
    assert.equals(4, 4, "message not seen")
end

function test_equals_fail()
    assert.equals(4, 7)
    assert.equals(4, 7, "some message")
    assert.equals({}, {})
end

function test_not_equals()
    assert.not_equals(4, 7)
    assert.not_equals(4, 7, "message not seen message")
    assert.not_equals({}, {})
end

function test_not_equals_fail()
    assert.not_equals(4, 4)
    assert.not_equals(4, 4, "some message")
end

function init()
end

function loop(t)
end

function event(e)
end

require("mod_test_runner")